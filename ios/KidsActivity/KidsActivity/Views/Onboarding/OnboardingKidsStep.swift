import SwiftUI

struct OnboardingKidsStep: View {
    @Binding var kids: [Kid]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHero(
                eyebrow: "Welcome",
                title: "Who are we\nplanning for?",
                subtitle: "Add a name for each kid. You can fine-tune ages, distance, and the rest in Filters anytime."
            )

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach($kids) { $kid in
                        KidEditorRow(
                            kid: $kid,
                            canRemove: kids.count > 1,
                            onRemove: { remove(kid) }
                        )
                    }

                    Button(action: addKid) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text("Add another kid")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.terracotta)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.terracotta.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        )
                    }
                    .padding(.top, 4)

                    privacyCard
                        .padding(.top, 12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
    }

    private var privacyCard: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 13))
                .foregroundStyle(.warmTextSecondary)
                .padding(.top, 1)
            Text("Stays on this device. We don't make accounts or share names with venues.")
                .font(.system(size: 12))
                .foregroundStyle(.warmTextTertiary)
                .lineSpacing(1.5)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.oklch(0.97, 0.025, 60), in: RoundedRectangle(cornerRadius: 10))
    }

    private func addKid() {
        let hue = Kid.nextHue(after: kids)
        kids.append(Kid(id: UUID(), name: "", ageMonths: 60, hue: hue))
    }

    private func remove(_ kid: Kid) {
        kids.removeAll { $0.id == kid.id }
    }
}

private struct KidEditorRow: View {
    @Binding var kid: Kid
    var canRemove: Bool
    var onRemove: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            avatar

            VStack(alignment: .leading, spacing: 6) {
                TextField("Name", text: $kid.name)
                    .textInputAutocapitalization(.words)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.warmTextPrimary)

                AgeStepper(months: $kid.ageMonths)
            }

            if canRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.warmTextFaint)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .warmCard()
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(kid.avatarColor)
                .frame(width: 44, height: 44)
            Text(kid.initial.isEmpty ? "?" : kid.initial)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

private struct AgeStepper: View {
    @Binding var months: Int

    var body: some View {
        HStack(spacing: 10) {
            Button { months = max(0, months - 12) } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.warmTextMuted)
            }
            .buttonStyle(.plain)

            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.warmTextSecondary)
                .monospacedDigit()
                .frame(minWidth: 56, alignment: .center)

            Button { months = min(216, months + 12) } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.warmTextMuted)
            }
            .buttonStyle(.plain)
        }
    }

    private var label: String {
        let years = months / 12
        if years < 1 { return "< 1 yr" }
        return years == 1 ? "1 year old" : "\(years) yrs old"
    }
}

/// StepHero: terracotta eyebrow + 28pt display title (line breaks honored)
/// + warm tertiary subtitle. Matches `v5-onboarding.jsx::StepHero`.
@ViewBuilder
func stepHero(eyebrow: String, title: String, subtitle: String?) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(eyebrow.uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(0.6)
            .foregroundStyle(Color.oklch(0.45, 0.13, 22))
        Text(title)
            .font(.system(size: 28, weight: .bold))
            .kerning(-0.7)
            .foregroundStyle(.warmTextPrimary)
            .lineSpacing(-3)
            .fixedSize(horizontal: false, vertical: true)
        if let subtitle {
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(.warmTextTertiary)
                .lineSpacing(2)
                .frame(maxWidth: 320, alignment: .leading)
                .padding(.top, 2)
        }
    }
    .padding(.horizontal, 24)
    .padding(.top, 24)
    .padding(.bottom, 16)
    .frame(maxWidth: .infinity, alignment: .leading)
}
