import SwiftUI

// V5 Saved — split saved items into "Considering" (not registered) and
// "Registered" (which spawn calendar events).

struct SavedView: View {
    @Environment(ActivityStore.self) private var store

    private var considering: [Activity] { store.consideringActivities }
    private var registered: [Activity]  { store.registeredActivities }

    var body: some View {
        ZStack(alignment: .top) {
            Color.warmCanvas.ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    titleBlock
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 6)

                    summaryStrip
                        .padding(.horizontal, 16)
                        .padding(.top, 12).padding(.bottom, 8)

                    if considering.isEmpty && registered.isEmpty {
                        emptyState
                    }

                    if !considering.isEmpty {
                        section(
                            title: "Considering",
                            subtitle: "Tap “I registered” once it’s confirmed on the host site",
                            accent: nil
                        ) {
                            ForEach(considering) { a in
                                NavigationLink(value: a) {
                                    SavedRow(activity: a, registered: false)
                                }.buttonStyle(.plain)
                            }
                        }
                    }

                    if !registered.isEmpty {
                        section(
                            title: "Registered",
                            subtitle: "On your calendar · reminders 1 day before",
                            accent: .registeredGreen
                        ) {
                            ForEach(registered) { a in
                                NavigationLink(value: a) {
                                    SavedRow(activity: a, registered: true)
                                }.buttonStyle(.plain)
                            }
                        }
                    }

                    Color.clear.frame(height: 32)
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.warmCanvas, for: .navigationBar)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(store.kids.count) KIDS · \(store.savedActivityIds.count) SAVED")
                .font(.v5Eyebrow)
                .tracking(0.5)
                .foregroundStyle(Color.oklch(0.55, 0.05, 60))
            Text("Saved")
                .font(.v5Display)
                .kerning(-0.6)
                .foregroundStyle(.warmTextPrimary)
            Text("Confirm the ones you actually registered for — they’ll show up on your Calendar.")
                .font(.system(size: 13))
                .foregroundStyle(.warmTextTertiary)
                .padding(.top, 4)
        }
    }

    private var summaryStrip: some View {
        HStack(spacing: 8) {
            summaryPill(count: considering.count, title: "Considering", subtitle: "still deciding", isReg: false)
            summaryPill(count: registered.count, title: "Registered", subtitle: "on calendar", isReg: true)
        }
    }

    private func summaryPill(count: Int, title: String, subtitle: String, isReg: Bool) -> some View {
        HStack(spacing: 10) {
            Text("\(count)")
                .font(.system(size: 13, weight: .bold).monospacedDigit())
                .foregroundStyle(isReg ? Color.white : .warmTextSecondary)
                .frame(width: 28, height: 28)
                .background(isReg ? AnyShapeStyle(Color.registeredGreen) : AnyShapeStyle(Color(brown: 0.08)),
                            in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.warmTextPrimary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.warmTextTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isReg ? AnyShapeStyle(Color.oklch(0.95, 0.07, 145)) : AnyShapeStyle(Color.warmCard),
                    in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isReg ? Color.clear : Color(brown: 0.06), lineWidth: 0.5)
        )
    }

    private func section<Content: View>(
        title: String, subtitle: String, accent: Color?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                if let accent {
                    Circle().fill(accent).frame(width: 8, height: 8)
                }
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(.warmTextFaint)
                    .textCase(.uppercase)
            }
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(.warmTextMuted)
                .padding(.top, 2)
            VStack(spacing: 6) {
                content()
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text("No saves yet.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.warmTextPrimary)
            Text("Tap the bookmark on any activity to start a list.")
                .font(.system(size: 12))
                .foregroundStyle(.warmTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Saved row

struct SavedRow: View {
    let activity: Activity
    let registered: Bool
    @Environment(ActivityStore.self) private var store

    private var category: ActivityCategory { activity.inferredCategory }
    private var kid: Kid? { store.kid(for: activity.activityId) }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            categorySwatch
            VStack(alignment: .leading, spacing: 3) {
                titleLine
                metaLine
            }
            Spacer(minLength: 0)
            registerToggle
        }
        .padding(10)
        .background(Color.warmCard, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(brown: 0.05), lineWidth: 0.5)
        )
        .overlay(alignment: .leading) {
            if let kid {
                Rectangle().fill(kid.avatarColor)
                    .frame(width: 3)
                    .clipShape(RoundedCorner(radius: 12, corners: [.topLeft, .bottomLeft]))
            }
        }
        .shadow(color: Color(brown: 0.03), radius: 1, y: 1)
    }

    private var categorySwatch: some View {
        let style = category.style
        return ZStack(alignment: .topTrailing) {
            Text(category.short)
                .font(.system(size: 14, weight: .bold))
                .tracking(0.4)
                .foregroundStyle(style.swatchFG)
                .frame(width: 40, height: 40)
                .background(style.swatchBG, in: RoundedRectangle(cornerRadius: 9))
            Text(activity.venueType.letter)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 14, height: 14)
                .background(Color.warmTextPrimary, in: Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                .offset(x: 2, y: -2)
        }
    }

    private var titleLine: some View {
        HStack(spacing: 6) {
            if let kid {
                Text(kid.initial)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 16, height: 16)
                    .background(kid.avatarColor, in: Circle())
            }
            Text(activity.name)
                .font(.v5Headline)
                .kerning(-0.2)
                .foregroundStyle(.warmTextPrimary)
                .lineLimit(1)
        }
    }

    private var metaLine: some View {
        HStack(spacing: 5) {
            Text("\(Formatters.days(activity.dayLetters)) \(Formatters.firstTime(activity.schedule.weeklyTimes))"
                .trimmingCharacters(in: .whitespaces))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.warmTextPrimary)
            sep
            Text(Formatters.startDate(activity.schedule.startDate).isEmpty
                 ? "—" : Formatters.startDate(activity.schedule.startDate))
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(.warmTextTertiary)
            sep
            Text(activity.venueName)
                .font(.v5Meta)
                .foregroundStyle(.warmTextTertiary)
                .lineLimit(1)
            sep
            Text(Formatters.price(activity.price))
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundStyle(.warmTextSecondary)
        }
    }

    private var sep: some View {
        Circle().fill(Color.warmDotSeparator).frame(width: 2, height: 2)
    }

    private var registerToggle: some View {
        Button {
            store.toggleRegistered(activity)
        } label: {
            HStack(spacing: 4) {
                if registered {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                }
                Text(registered ? "REGISTERED" : "I REGISTERED")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.3)
            }
            .foregroundStyle(registered ? Color.registeredText : .warmTextTertiary)
            .padding(.horizontal, 8).padding(.vertical, 6)
            .background(registered ? AnyShapeStyle(Color.oklch(0.95, 0.07, 145)) : AnyShapeStyle(Color(brown: 0.05)),
                        in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// Custom corner radius shape — used for the kid-color left bar.
struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect, byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
