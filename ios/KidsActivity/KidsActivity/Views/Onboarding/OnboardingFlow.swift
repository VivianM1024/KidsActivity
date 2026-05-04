import SwiftUI
import CoreLocation

struct OnboardingFlow: View {
    @Environment(ActivityStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var step: Int = 0
    @State private var draftKids: [Kid] = [
        Kid(id: UUID(), name: "", ageMonths: 60, hue: Kid.availableHues[0])
    ]
    @State private var zip: String = ""
    @State private var neighborhood: String = ""
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var availability: Set<ActivityFilters.DayOfWeek> = []
    @State private var resolvingZIP: Bool = false

    private let location = LocationService()

    var body: some View {
        ZStack {
            Color.warmCanvas.ignoresSafeArea()

            VStack(spacing: 0) {
                topHeader
                    .padding(.top, 12)

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                footer
            }
        }
    }

    /// Back chevron (left), thin segmented progress bar (center),
    /// step counter (right) — matches `v5-onboarding.jsx::Header`.
    private var topHeader: some View {
        HStack(spacing: 12) {
            Group {
                if step > 0 {
                    Button { withAnimation { step -= 1 } } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.warmTextPrimary)
                            .frame(width: 32, height: 32)
                            .background(Color(brown: 0.05), in: Circle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(width: 32, height: 32)
                }
            }

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(i <= step ? Color.terracotta : Color(brown: 0.10))
                        .frame(height: 3)
                }
            }
            .animation(.easeInOut(duration: 0.24), value: step)

            Text("\(step + 1)/3")
                .font(.system(size: 11, weight: .bold).monospacedDigit())
                .tracking(0.4)
                .foregroundStyle(.warmTextFaint)
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:
            OnboardingKidsStep(kids: $draftKids)
        case 1:
            OnboardingLocationStep(zip: $zip, neighborhood: $neighborhood, coordinate: $coordinate)
        default:
            OnboardingAvailabilityStep(availability: $availability)
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.warmCanvas.opacity(0), Color.warmCanvas],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 24)

            Button(action: advance) {
                HStack(spacing: 8) {
                    if resolvingZIP {
                        ProgressView().tint(.white).scaleEffect(0.8)
                    }
                    Text(ctaLabel)
                        .font(.system(size: 15, weight: .bold))
                        .kerning(-0.1)
                    if step == 2, canAdvance, !resolvingZIP {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .foregroundStyle(canAdvance ? .white : .warmTextFaint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(canAdvance ? Color.terracotta : Color(brown: 0.12))
                )
                .shadow(color: Color.terracotta.opacity(canAdvance ? 0.25 : 0), radius: 12, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(!canAdvance || resolvingZIP)
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
            .background(Color.warmCanvas)
        }
    }

    /// CTA label adapts to step + state — matches `v5-onboarding.jsx`.
    private var ctaLabel: String {
        switch step {
        case 0:
            let n = draftKids.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }.count
            return n > 1 ? "Continue with \(n) kids" : "Continue"
        case 1:
            let hasLocation = !zip.trimmingCharacters(in: .whitespaces).isEmpty
                || !neighborhood.trimmingCharacters(in: .whitespaces).isEmpty
                || coordinate != nil
            return hasLocation ? "Continue" : "Skip for now"
        default:
            return "Find activities"
        }
    }

    private var canAdvance: Bool {
        switch step {
        case 0:
            return draftKids.allSatisfy { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
                && !draftKids.isEmpty
        case 1:
            return zip.count == 5 || coordinate != nil
        default:
            return true  // availability can be empty (= "any day")
        }
    }

    private func advance() {
        switch step {
        case 0:
            withAnimation { step = 1 }
        case 1:
            // If user typed a ZIP but didn't tap "Use my current location",
            // geocode it before advancing so we still capture a coordinate.
            if coordinate == nil, zip.count == 5 {
                resolvingZIP = true
                Task {
                    defer { resolvingZIP = false }
                    if let c = try? await location.geocode(zip: zip) {
                        coordinate = c
                    }
                    withAnimation { step = 2 }
                }
            } else {
                withAnimation { step = 2 }
            }
        default:
            finish()
        }
    }

    private func finish() {
        // Trim names so the kids list is presentable.
        let cleaned = draftKids.map { kid -> Kid in
            var copy = kid
            copy.name = kid.name.trimmingCharacters(in: .whitespaces)
            return copy
        }
        store.completeOnboarding(
            kids: cleaned,
            zip: zip,
            neighborhood: neighborhood.trimmingCharacters(in: .whitespaces),
            coordinate: coordinate,
            availability: availability
        )
        dismiss()
    }
}
