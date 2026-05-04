import SwiftUI

// V5 Registration handoff bridge sheet.
//
// Shown when the user taps "Register" on Detail. The bridge tells them what's
// about to happen (we open the venue's site in Safari), gives them the info
// they'll need to type, and provides a single "I registered" link to confirm
// on return — which marks the activity registered and dismisses the sheet.
//
// Mirrors `design_handoff_v5_hybrid/design/v5-handoff.jsx` row-for-row.

struct RegistrationHandoffSheet: View {
    let activity: Activity
    @Environment(ActivityStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showSafari = false

    private var category: ActivityCategory { activity.inferredCategory }
    private var primaryKid: Kid? {
        store.kid(for: activity.activityId)
            ?? store.matchKids(for: activity).first
            ?? store.selectedKids.first
            ?? store.kids.first
    }
    private var host: String { activity.sourceUrl.host ?? "host site" }
    private var price: String { Formatters.price(activity.price) }
    private var dayTime: String {
        "\(Formatters.days(activity.dayLetters)) \(Formatters.firstTime(activity.schedule.weeklyTimes))"
            .trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.warmCanvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    summaryCard
                    youllNeedSection
                    whatHappensSection
                    Color.clear.frame(height: 140)
                }
            }
            .scrollIndicators(.hidden)

            stickyFooter
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .sheet(isPresented: $showSafari) {
            SafariView(url: activity.sourceUrl).ignoresSafeArea()
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(Color.terracotta).frame(width: 6, height: 6)
                Text("HEADS UP")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(Color.oklch(0.45, 0.13, 22))
            }
            Text("We can't register you directly—here's how it works.")
                .font(.system(size: 24, weight: .bold))
                .kerning(-0.5)
                .foregroundStyle(.warmTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("The venue uses their own system. We'll open it in Safari so you can finish there, then come back to add it to your calendar.")
                .font(.system(size: 13))
                .foregroundStyle(.warmTextTertiary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Summary

    private var summaryCard: some View {
        let style = category.style
        return HStack(alignment: .center, spacing: 10) {
            Text(category.short)
                .font(.system(size: 13, weight: .bold))
                .tracking(0.3)
                .foregroundStyle(style.swatchFG)
                .frame(width: 40, height: 40)
                .background(style.swatchBG, in: RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.name)
                    .font(.v5Headline)
                    .foregroundStyle(.warmTextPrimary)
                    .lineLimit(1)
                HStack(spacing: 5) {
                    Text(dayTime.isEmpty ? "—" : dayTime)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(.warmTextTertiary)
                    Circle().fill(Color.warmDotSeparator).frame(width: 2, height: 2)
                    Text(price)
                        .font(.system(size: 11.5, weight: .semibold).monospacedDigit())
                        .foregroundStyle(.warmTextPrimary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard()
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    // MARK: - You'll need

    private var youllNeedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionEyebrow("You'll need")
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                if let kid = primaryKid {
                    needRow(
                        icon: AnyView(kidIcon(kid: kid)),
                        label: "\(kid.name)'s info",
                        value: "Name, age (\(kid.ageYears)yr), maybe school",
                        copy: kid.name,
                        showDivider: true
                    )
                }
                needRow(
                    icon: AnyView(dotBubble(letter: "$", hue: category.hue)),
                    label: "Payment",
                    value: "\(price) resident · credit card or saved on file",
                    copy: nil,
                    showDivider: true
                )
                needRow(
                    icon: AnyView(dotBubble(letter: "✓", hue: 145)),
                    label: "\(host) account",
                    value: "If you don't have one, sign-up takes ~2 min",
                    copy: nil,
                    showDivider: false
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .warmCard()
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 18)
    }

    private func needRow(
        icon: AnyView, label: String, value: String,
        copy: String?, showDivider: Bool
    ) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                icon
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(.warmTextPrimary)
                    Text(value)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.warmTextTertiary)
                }
                Spacer(minLength: 0)
                if let copy {
                    Button {
                        UIPasteboard.general.string = copy
                    } label: {
                        Text("COPY")
                            .font(.system(size: 10.5, weight: .bold))
                            .tracking(0.4)
                            .foregroundStyle(.warmTextSecondary)
                            .padding(.horizontal, 7).padding(.vertical, 4)
                            .background(Color(brown: 0.05), in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)

            if showDivider {
                Rectangle().fill(Color(brown: 0.07))
                    .frame(height: 0.5)
                    .padding(.leading, 14)
            }
        }
    }

    private func kidIcon(kid: Kid) -> some View {
        Text(kid.initial)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(kid.avatarColor, in: Circle())
    }

    private func dotBubble(letter: String, hue: Double) -> some View {
        Text(letter)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.oklch(0.32, 0.13, hue))
            .frame(width: 28, height: 28)
            .background(Color.oklch(0.92, 0.07, hue), in: Circle())
    }

    // MARK: - What happens

    private var whatHappensSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionEyebrow("What happens")
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 0) {
                stepRow(n: 1, title: "We open Safari",
                        sub: "Goes to \(host) with this activity pre-selected.",
                        active: true, last: false)
                stepRow(n: 2, title: "You finish on their site",
                        sub: "Account, payment, waivers — the usual stuff.",
                        active: false, last: false)
                stepRow(n: 3, title: "Come back here",
                        sub: "Tap \"I registered\" — we'll add the dates to your Calendar tab.",
                        active: false, last: true)
            }
            .padding(.horizontal, 20)
        }
    }

    private func stepRow(n: Int, title: String, sub: String, active: Bool, last: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Text("\(n)")
                    .font(.system(size: 12, weight: .bold).monospacedDigit())
                    .foregroundStyle(active ? .white : .warmTextSecondary)
                    .frame(width: 26, height: 26)
                    .background(active ? Color.terracotta : Color.warmCard, in: Circle())
                    .overlay(
                        Circle().stroke(
                            active ? Color.clear : Color(brown: 0.15),
                            lineWidth: 1.5
                        )
                    )
                if !last {
                    Rectangle().fill(Color(brown: 0.10))
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.warmTextPrimary)
                Text(sub)
                    .font(.system(size: 12))
                    .foregroundStyle(.warmTextTertiary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, last ? 0 : 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionEyebrow(_ label: String) -> some View {
        Text(label.uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(0.5)
            .foregroundStyle(.warmTextFaint)
    }

    // MARK: - Sticky footer

    private var stickyFooter: some View {
        VStack(spacing: 8) {
            LinearGradient(
                colors: [Color.warmCanvas.opacity(0), Color.warmCanvas],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 24)
            .allowsHitTesting(false)

            VStack(spacing: 8) {
                Button { showSafari = true } label: {
                    HStack(spacing: 8) {
                        Text("Open \(host)")
                            .font(.system(size: 15, weight: .bold))
                            .kerning(-0.1)
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 12, weight: .bold))
                            .opacity(0.85)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.terracotta, in: RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.terracotta.opacity(0.25), radius: 12, y: 4)
                }
                .buttonStyle(.plain)

                Button {
                    store.toggleRegistered(activity)
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Text("Already done?")
                            .foregroundStyle(.warmTextTertiary)
                        Text("I registered")
                            .foregroundStyle(.terracotta)
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.terracotta)
                    }
                    .font(.system(size: 12))
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            .background(Color.warmCanvas)
        }
    }
}
