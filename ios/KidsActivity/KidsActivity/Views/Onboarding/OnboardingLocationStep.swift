import SwiftUI
import CoreLocation

struct OnboardingLocationStep: View {
    @Binding var zip: String
    @Binding var neighborhood: String
    @Binding var coordinate: CLLocationCoordinate2D?

    @State private var locating: Bool = false
    @State private var locationError: String?
    private let location = LocationService()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHero(
                eyebrow: "Step 2",
                title: "Where's home?",
                subtitle: "We'll sort activities by distance. Just a ZIP works — we don't need an exact address."
            )

            VStack(spacing: 14) {
                LabeledField(label: "ZIP CODE") {
                    TextField("60647", text: $zip)
                        .keyboardType(.numberPad)
                        .textContentType(.postalCode)
                        .onChange(of: zip) { _, new in
                            // Numeric only, max 5
                            let trimmed = String(new.filter(\.isNumber).prefix(5))
                            if trimmed != new { zip = trimmed }
                        }
                }

                LabeledField(label: "NEIGHBORHOOD (OPTIONAL)") {
                    TextField("Logan Square", text: $neighborhood)
                        .textInputAutocapitalization(.words)
                }

                Button(action: useCurrentLocation) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.oklch(0.94, 0.06, 22))
                                .frame(width: 32, height: 32)
                            if locating {
                                ProgressView().tint(.terracotta).scaleEffect(0.7)
                            } else {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.oklch(0.45, 0.13, 22))
                            }
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(locating ? "Locating…" : "Use my current location")
                                .font(.system(size: 13.5, weight: .semibold))
                                .foregroundStyle(.warmTextPrimary)
                            Text("Asks iOS for permission · doesn't leave the device")
                                .font(.system(size: 11.5))
                                .foregroundStyle(.warmTextTertiary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.warmTextFaint)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .warmCard()
                }
                .disabled(locating)
                .buttonStyle(.plain)

                if let coordinate {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.registeredGreen)
                        Text("Location pinned at \(format(coordinate))")
                            .font(.system(size: 12))
                            .foregroundStyle(.warmTextTertiary)
                    }
                }

                if let locationError {
                    Text(locationError)
                        .font(.system(size: 12))
                        .foregroundStyle(.terracotta)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Spacer(minLength: 0)
        }
    }

    private func format(_ c: CLLocationCoordinate2D) -> String {
        String(format: "%.3f, %.3f", c.latitude, c.longitude)
    }

    private func useCurrentLocation() {
        locationError = nil
        locating = true
        Task {
            defer { locating = false }
            do {
                let fix = try await location.currentLocationFix()
                self.coordinate = fix.coordinate
                if let z = fix.zip, !z.isEmpty { self.zip = String(z.prefix(5)) }
                if let n = fix.neighborhood, !n.isEmpty { self.neighborhood = n }
            } catch LocationService.LocationError.denied {
                locationError = "Location access is off. Add a ZIP manually, or enable it in Settings."
            } catch {
                locationError = "Couldn't get your location. Try entering a ZIP."
            }
        }
    }
}

private struct LabeledField<Field: View>: View {
    let label: String
    @ViewBuilder var field: Field

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.warmTextFaint)
            field
                .font(.system(size: 16))
                .foregroundStyle(.warmTextPrimary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .warmCard()
        }
    }
}
