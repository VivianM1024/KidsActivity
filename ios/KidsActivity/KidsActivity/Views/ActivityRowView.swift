import SwiftUI

// V5 row: 40pt category swatch w/ venue-letter corner mark, dense meta line,
// per-kid match dots, kind + status badges, start-date trailing.

struct ActivityRow: View {
    let activity: Activity
    @Environment(ActivityStore.self) private var store

    private var category: ActivityCategory { activity.inferredCategory }
    private var matchedKids: [Kid] { store.matchKids(for: activity) }
    private var distance: Double? {
        Formatters.distanceMiles(home: store.homeCoordinate,
                                 venue: store.venueBySlug[activity.venueSlug])
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            categorySwatch
            VStack(alignment: .leading, spacing: 2) {
                titleLine
                metaLine
                badgeLine
            }
        }
        .padding(10)
        .warmCard(radius: 12)
    }

    // MARK: - Pieces

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
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(activity.name)
                .font(.v5Headline)
                .kerning(-0.2)
                .foregroundStyle(.warmTextPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(Formatters.price(activity.price))
                .font(.system(size: 13, weight: .bold).monospacedDigit())
                .foregroundStyle(.warmTextPrimary)
        }
    }

    private var metaLine: some View {
        let dayTime = "\(Formatters.days(activity.dayLetters)) \(Formatters.firstTime(activity.schedule.weeklyTimes))"
            .trimmingCharacters(in: .whitespaces)
        return HStack(spacing: 5) {
            Text(dayTime.isEmpty ? "—" : dayTime)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.warmTextPrimary)
                .lineLimit(1)
            sep
            Text(Formatters.ageRange(activity.ageRange))
                .font(.v5Meta)
                .foregroundStyle(.warmTextTertiary)
            sep
            Text(activity.venueName)
                .font(.v5Meta)
                .foregroundStyle(.warmTextTertiary)
                .lineLimit(1)
            if let m = Formatters.miles(distance) {
                sep
                Text(m)
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(.warmTextTertiary)
            }
        }
        .padding(.top, 2)
    }

    private var badgeLine: some View {
        HStack(spacing: 4) {
            // Per-kid match dots
            if !matchedKids.isEmpty {
                HStack(spacing: 2) {
                    ForEach(matchedKids) { kid in
                        kidDot(kid: kid)
                    }
                }
                .padding(.trailing, 2)
            }

            // Kind badge
            kindBadge

            // Status badge
            statusBadge

            Spacer(minLength: 0)

            if let date = activity.schedule.startDate {
                Text(Formatters.monthDay.string(from: date))
                    .font(.system(size: 10).monospacedDigit())
                    .foregroundStyle(.warmTextFaint)
            }
        }
        .padding(.top, 5)
    }

    private var sep: some View {
        Circle()
            .fill(Color.warmDotSeparator)
            .frame(width: 2, height: 2)
    }

    private func kidDot(kid: Kid) -> some View {
        Text(kid.initial)
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 14, height: 14)
            .background(kid.avatarColor, in: Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
    }

    private var kindBadge: some View {
        let series = activity.kind == .series
        let label: String = {
            if series, let n = activity.schedule.numSessions { return "SERIES · \(n)×" }
            return series ? "SERIES" : "ONE-TIME"
        }()
        return Text(label)
            .font(.system(size: 10, weight: .bold))
            .tracking(0.3)
            .padding(.horizontal, 6).padding(.vertical, 1)
            .foregroundStyle(series ? Color.seriesText : .oneTimeText)
            .background(series ? Color.seriesBg : .oneTimeBg, in: RoundedRectangle(cornerRadius: 4))
    }

    private var statusBadge: some View {
        let status = ActivityStatus.compute(for: activity)
        return Text(status.label)
            .font(.system(size: 10, weight: .bold))
            .tracking(0.3)
            .padding(.horizontal, 6).padding(.vertical, 1)
            .foregroundStyle(statusFg(status))
            .background(statusBg(status), in: RoundedRectangle(cornerRadius: 4))
    }

    private func statusFg(_ s: ActivityStatus) -> Color {
        switch s {
        case .open, .dropIn: return .registeredText
        case .opensSoon:     return .opensSoonText
        case .full, .closed: return .warmTextTertiary
        }
    }

    private func statusBg(_ s: ActivityStatus) -> Color {
        switch s {
        case .open, .dropIn: return .registeredBg
        case .opensSoon:     return .opensSoonBg
        case .full, .closed: return Color(brown: 0.08)
        }
    }
}

// Backwards-compat wrapper so the old ActivityRowView call sites compile.
struct ActivityRowView: View {
    let activity: Activity
    var body: some View { ActivityRow(activity: activity) }
}
