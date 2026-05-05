import SwiftUI
import CoreLocation

/// Transparency popover for the Browse sort order. Reads real signals out
/// of the user's filters (kid match, distance limit, day-of-week, price
/// cap, registration state) and shows whether the top-ranked activity
/// satisfies each one. The score is a sum of weights for met rules — same
/// shape as `v5-transparency.jsx::V5WhyThis` but driven by `FilterEngine`'s
/// actual inputs.
struct WhyThisSheet: View {
    @Environment(ActivityStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var topActivity: Activity? { store.filteredActivities.first }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.warmCanvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    if topActivity != nil {
                        scoreCard
                        rulesList
                    } else {
                        emptyHint
                    }
                    privacyNote
                    Color.clear.frame(height: 100)
                }
            }
            .scrollIndicators(.hidden)

            stickyFooter
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.terracotta)
                Text(topActivity != nil ? "WHY THIS IS #1" : "WHY THIS ORDER")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(Color.oklch(0.45, 0.13, 22))
            }
            Text(topActivity?.name ?? "No activities matched")
                .font(.system(size: 24, weight: .bold))
                .kerning(-0.5)
                .foregroundStyle(.warmTextPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text("You set what matters in onboarding and the filter sheet. Here's how this activity scored against those rules.")
                .font(.system(size: 13))
                .foregroundStyle(.warmTextTertiary)
                .lineSpacing(2)
                .padding(.top, 4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 14)
    }

    // MARK: - Score

    private var scoreCard: some View {
        let evaluated = ruleSet
        let metWeight = evaluated.filter(\.met).reduce(0) { $0 + $1.weight }
        let metCount = evaluated.filter(\.met).count
        return HStack(spacing: 14) {
            scoreRing(score: metWeight)
            VStack(alignment: .leading, spacing: 2) {
                Text("MATCH SCORE")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(.warmTextFaint)
                Text("\(metCount) of \(evaluated.count) rules met")
                    .font(.system(size: 15, weight: .bold))
                    .kerning(-0.2)
                    .foregroundStyle(.warmTextPrimary)
                Text("Higher = more rules you set were satisfied.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.warmTextTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard(radius: 14)
        .padding(.horizontal, 16).padding(.bottom, 14)
    }

    private func scoreRing(score: Int) -> some View {
        let progress = Double(min(100, max(0, score))) / 100.0
        return ZStack {
            Circle()
                .stroke(Color(brown: 0.08), lineWidth: 5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.registeredGreen, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 16, weight: .bold).monospacedDigit())
                    .foregroundStyle(.warmTextPrimary)
                Text("/100")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.warmTextFaint)
            }
        }
        .frame(width: 56, height: 56)
    }

    // MARK: - Rules list

    private var rulesList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("THE RULES")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.warmTextFaint)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                let rules = ruleSet
                ForEach(Array(rules.enumerated()), id: \.offset) { idx, rule in
                    ruleRow(rule, showDivider: idx != rules.count - 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .warmCard()
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 14)
    }

    private func ruleRow(_ rule: Rule, showDivider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: rule.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(rule.met ? Color.oklch(0.40, 0.13, 145) : .warmTextFaint)
                    .frame(width: 30, height: 30)
                    .background(
                        rule.met ? AnyShapeStyle(Color.oklch(0.94, 0.05, 145))
                                 : AnyShapeStyle(Color(brown: 0.05)),
                        in: RoundedRectangle(cornerRadius: 9)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(rule.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.warmTextPrimary)
                        .strikethrough(!rule.met, color: .warmTextFaint)
                    Text(rule.detail)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.warmTextTertiary)
                        .lineSpacing(1.5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Text(rule.met ? "+\(rule.weight)" : "·0")
                    .font(.system(size: 10.5, weight: .bold).monospacedDigit())
                    .tracking(0.3)
                    .foregroundStyle(rule.met ? Color.oklch(0.40, 0.13, 145) : .warmTextFaint)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(
                        rule.met ? AnyShapeStyle(Color.oklch(0.94, 0.05, 145))
                                 : AnyShapeStyle(Color(brown: 0.04)),
                        in: RoundedRectangle(cornerRadius: 4)
                    )
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .opacity(rule.met ? 1 : 0.7)

            if showDivider {
                Rectangle().fill(Color(brown: 0.07)).frame(height: 0.5)
                    .padding(.leading, 14)
            }
        }
    }

    // MARK: - Privacy + footer

    private var privacyNote: some View {
        Text("**No black box.** We never reorder for sponsored placement, and we don't use what you've clicked on — only the filters and kids you set yourself.")
            .font(.system(size: 12.5))
            .foregroundStyle(.warmTextTertiary)
            .lineSpacing(2)
            .padding(.horizontal, 14).padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(brown: 0.03), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
    }

    private var emptyHint: some View {
        Text("Adjust filters to see how rules score the top match.")
            .font(.system(size: 13))
            .foregroundStyle(.warmTextTertiary)
            .padding(.horizontal, 24).padding(.vertical, 24)
    }

    private var stickyFooter: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.warmCanvas.opacity(0), Color.warmCanvas],
                startPoint: .top, endPoint: .bottom
            ).frame(height: 24).allowsHitTesting(false)

            HStack(spacing: 8) {
                Button { dismiss() } label: {
                    Text("Adjust filters")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.warmTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color(brown: 0.05), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button { dismiss() } label: {
                    Text("Got it")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.terracotta, in: RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.terracotta.opacity(0.22), radius: 8, y: 2)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20).padding(.bottom, 30)
            .background(Color.warmCanvas)
        }
    }

    // MARK: - Real signal evaluation

    /// A rule that was checked against the top-ranked activity.
    private struct Rule {
        let label: String
        let detail: String
        let weight: Int
        let met: Bool
        let icon: String
    }

    /// Builds the rule set out of `store.filters` + the top activity. Weights
    /// sum to 100 across the rules that were *applicable*; "didn't apply"
    /// rules show with 0 weight (struck through).
    private var ruleSet: [Rule] {
        guard let top = topActivity else { return [] }

        // Distance
        let distanceRule: Rule = {
            let limit = store.filters.maxDistanceMiles
            let venue = store.venueBySlug[top.venueSlug]
            let miles = Formatters.distanceMiles(home: store.homeCoordinate, venue: venue)
            if let limit, let miles {
                let met = miles <= limit
                let venueName = top.venueName
                return Rule(
                    label: "Within your radius",
                    detail: met
                        ? "\(venueName) is \(String(format: "%.1f", miles)) mi away (you set \(Int(limit)) mi)."
                        : "\(venueName) is \(String(format: "%.1f", miles)) mi — beyond your \(Int(limit)) mi limit.",
                    weight: 25, met: met, icon: "mappin.and.ellipse"
                )
            }
            return Rule(
                label: "Within your radius",
                detail: "No distance cap set — this rule didn't apply.",
                weight: 25, met: false, icon: "mappin.and.ellipse"
            )
        }()

        // Days of week
        let daysRule: Rule = {
            let days = store.filters.daysOfWeek
            if !days.isEmpty {
                let activityDays = Set(top.dayLetters)
                let wanted = Set(days.map(\.short))
                let met = !activityDays.isDisjoint(with: wanted)
                let dayList = days.sorted { $0.rawValue < $1.rawValue }.map(\.short).joined(separator: ", ")
                let firstTime = Formatters.firstTime(top.schedule.weeklyTimes)
                return Rule(
                    label: "Time fits your free days",
                    detail: met
                        ? "\(activityDays.first ?? "—") at \(firstTime) — you marked \(dayList)."
                        : "Runs on \(activityDays.joined(separator: ", ")), but you wanted \(dayList).",
                    weight: 20, met: met, icon: "calendar"
                )
            }
            return Rule(
                label: "Time fits your free days",
                detail: "No day filter set — this rule didn't apply.",
                weight: 20, met: false, icon: "calendar"
            )
        }()

        // Age (kids)
        let ageRule: Rule = {
            let matched = store.matchKids(for: top)
            if let firstKid = matched.first {
                return Rule(
                    label: "Age window matches \(firstKid.name)",
                    detail: "Activity ages \(Formatters.ageRange(top.ageRange)) · \(firstKid.name) is \(firstKid.ageYears).",
                    weight: 25, met: true, icon: "figure.child"
                )
            }
            if !store.selectedKids.isEmpty {
                let names = store.selectedKids.map(\.name).joined(separator: " + ")
                return Rule(
                    label: "Age window matches a kid",
                    detail: "Activity ages \(Formatters.ageRange(top.ageRange)) — outside the ±1y window for \(names).",
                    weight: 25, met: false, icon: "figure.child"
                )
            }
            return Rule(
                label: "Age window matches a kid",
                detail: "No kid selected — this rule didn't apply.",
                weight: 25, met: false, icon: "figure.child"
            )
        }()

        // Registration open
        let openRule: Rule = {
            switch store.filters.registrationFilter {
            case .open:
                let met = top.registration.isOpen == true
                return Rule(
                    label: "Registration still open",
                    detail: met
                        ? "Open now."
                        : "Closed or not yet open — wanted Open now.",
                    weight: 15, met: met, icon: "clock.fill"
                )
            case .openingSoon:
                let met = top.registration.opensAt != nil
                return Rule(
                    label: "Opens soon",
                    detail: met
                        ? "Opens \(Formatters.startDate(top.registration.opensAt))."
                        : "No upcoming open date.",
                    weight: 15, met: met, icon: "clock.fill"
                )
            case .any:
                return Rule(
                    label: "Registration still open",
                    detail: "No registration filter set — this rule didn't apply.",
                    weight: 15, met: false, icon: "clock.fill"
                )
            }
        }()

        // Price below cap
        let priceRule: Rule = {
            if let cap = store.filters.priceFilter.cap {
                let p = top.lowestPrice ?? .infinity
                let met = (cap == 0 ? p == 0 : p <= cap)
                let priceText = Formatters.price(top.price)
                return Rule(
                    label: "Price below your max",
                    detail: met
                        ? "\(priceText) — within your \(store.filters.priceFilter.label.lowercased()) limit."
                        : "\(priceText) — over your \(store.filters.priceFilter.label.lowercased()) limit.",
                    weight: 10, met: met, icon: "dollarsign.circle.fill"
                )
            }
            return Rule(
                label: "Price below your max",
                detail: "No max set — this rule didn't apply.",
                weight: 10, met: false, icon: "dollarsign.circle.fill"
            )
        }()

        // Saved-similarity heuristic — rough proxy: same category as one of
        // the user's saved activities. Carried at low weight so it doesn't
        // dominate.
        let similarRule: Rule = {
            let savedCategories = Set(store.savedActivities.map(\.inferredCategory))
            if savedCategories.isEmpty {
                return Rule(
                    label: "Similar to what you've saved",
                    detail: "Nothing saved yet — this rule didn't apply.",
                    weight: 5, met: false, icon: "heart.fill"
                )
            }
            let met = savedCategories.contains(top.inferredCategory)
            return Rule(
                label: "Similar to what you've saved",
                detail: met
                    ? "You saved other \(top.inferredCategory.label) activities."
                    : "Different category from your saves — boost from this rule didn't apply.",
                weight: 5, met: met, icon: "heart.fill"
            )
        }()

        return [distanceRule, daysRule, ageRule, openRule, priceRule, similarRule]
    }
}
