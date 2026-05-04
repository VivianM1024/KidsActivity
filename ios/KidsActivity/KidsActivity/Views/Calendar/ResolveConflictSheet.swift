import SwiftUI
import CoreLocation

/// Conflict resolution sheet. Shows a stacked timeline of the two events,
/// the actual MapKit ETA between their venues, and four resolution options
/// (skip one, move, split-with-partner, cancel one).
///
/// Mirrors `v5-conflicts.jsx::V5ConflictSheet`.
struct ResolveConflictSheet: View {
    let conflict: ActivityStore.Conflict
    @Environment(ActivityStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var travelMinutes: Int?
    @State private var travelLoading: Bool = true

    private var primaryActivity: Activity? {
        store.activities.first { $0.activityId == conflict.primary.activityId }
    }
    private var secondaryActivity: Activity? {
        store.activities.first { $0.activityId == conflict.secondary.activityId }
    }
    private var primaryKid: Kid? {
        store.kids.first { $0.id == conflict.primary.kidId }
    }
    private var secondaryKid: Kid? {
        store.kids.first { $0.id == conflict.secondary.kidId }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.warmCanvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    timelineCard
                    resolutionOptions
                    Color.clear.frame(height: 80)
                }
            }
            .scrollIndicators(.hidden)
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .task { await fetchTravel() }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.amberWarn)
                Text(headerEyebrow)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(.amberWarnInk)
            }
            Text("You can't make both\nwithout rushing.")
                .font(.system(size: 24, weight: .bold))
                .kerning(-0.5)
                .foregroundStyle(.warmTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(.warmTextTertiary)
                .lineSpacing(2)
                .padding(.top, 4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 12)
    }

    private var headerEyebrow: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: conflict.primary.date).uppercased()
    }

    private var subtitle: String {
        var parts: [String] = ["Two events overlap by \(conflict.overlapMinutes) minutes"]
        if let m = travelMinutes {
            parts.append("and the venues are \(m) min apart by car")
        }
        return parts.joined(separator: " — ") + ". Here's how parents usually handle this."
    }

    // MARK: - Timeline

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            timelineHeader
            track(event: conflict.primary, kid: primaryKid)
            overlapStripe
            track(event: conflict.secondary, kid: secondaryKid)
            travelRow
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard(radius: 14)
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    private var timelineHeader: some View {
        HStack {
            ForEach(timelineLabels, id: \.self) { label in
                Text(label)
                    .font(.system(size: 10, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.warmTextFaint)
                if label != timelineLabels.last { Spacer() }
            }
        }
    }

    /// 6 labels covering the window from earliest event start to latest event end.
    private var timelineLabels: [String] {
        let starts = [conflict.primary.date, conflict.secondary.date]
        let ends = [
            conflict.primary.date.addingTimeInterval(TimeInterval(conflict.primary.durationMinutes * 60)),
            conflict.secondary.date.addingTimeInterval(TimeInterval(conflict.secondary.durationMinutes * 60))
        ]
        guard let earliest = starts.min(), let latest = ends.max() else { return [] }
        let span = latest.timeIntervalSince(earliest)
        let count = 6
        let step = span / Double(count - 1)
        let f = DateFormatter(); f.dateFormat = "h:mm"
        return (0..<count).map { i in
            f.string(from: earliest.addingTimeInterval(step * Double(i)))
        }
    }

    private func track(event: CalendarEvent, kid: Kid?) -> some View {
        let earliest = min(conflict.primary.date, conflict.secondary.date)
        let latestEnd = max(
            conflict.primary.date.addingTimeInterval(TimeInterval(conflict.primary.durationMinutes * 60)),
            conflict.secondary.date.addingTimeInterval(TimeInterval(conflict.secondary.durationMinutes * 60))
        )
        let span = latestEnd.timeIntervalSince(earliest)
        let startOffset = event.date.timeIntervalSince(earliest)
        let widthFraction = Double(event.durationMinutes * 60) / max(1, span)
        let leftFraction = startOffset / max(1, span)

        return HStack(spacing: 8) {
            if let kid {
                Text(kid.initial)
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(kid.avatarColor, in: Circle())
            } else {
                Color.clear.frame(width: 22, height: 22)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(brown: 0.06))
                        .frame(height: 2)
                        .padding(.vertical, 13)

                    Capsule()
                        .fill(kid?.avatarColor ?? Color.warmTextSecondary)
                        .frame(width: max(8, geo.size.width * widthFraction), height: 18)
                        .offset(x: geo.size.width * leftFraction, y: 0)
                        .overlay(alignment: .leading) {
                            if let activityName = activityName(for: event) {
                                Text(activityName)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .padding(.leading, 8)
                                    .offset(x: geo.size.width * leftFraction)
                            }
                        }
                }
            }
            .frame(height: 28)

            Text(timeLabel(event))
                .font(.system(size: 10.5).monospacedDigit())
                .foregroundStyle(.warmTextTertiary)
        }
    }

    private func activityName(for event: CalendarEvent) -> String? {
        let a = event.activityId == conflict.primary.activityId
            ? primaryActivity : secondaryActivity
        return a?.name.split(separator: " ").prefix(2).joined(separator: " ")
    }

    private func timeLabel(_ event: CalendarEvent) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm"
        let start = f.string(from: event.date)
        let end = f.string(from: event.date.addingTimeInterval(TimeInterval(event.durationMinutes * 60)))
        return "\(start)–\(end)"
    }

    private var overlapStripe: some View {
        HStack {
            Spacer()
            Text("OVERLAP \(conflict.overlapMinutes)M")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.3)
                .foregroundStyle(.amberWarnInk)
                .padding(.horizontal, 10).padding(.vertical, 3)
                .background(Color.amberWarnSoft, in: RoundedRectangle(cornerRadius: 4))
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private var travelRow: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color(brown: 0.07)).frame(height: 0.5)
                .padding(.vertical, 8)
            HStack(spacing: 8) {
                Image(systemName: "car.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.warmTextTertiary)
                Text("\(primaryActivity?.venueName ?? "—") → \(secondaryActivity?.venueName ?? "—")")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.warmTextTertiary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if travelLoading {
                    ProgressView().scaleEffect(0.6).tint(.warmTextFaint)
                } else if let m = travelMinutes {
                    Text("~\(m) min drive")
                        .font(.system(size: 11.5, weight: .bold).monospacedDigit())
                        .foregroundStyle(.amberWarnInk)
                } else {
                    Text("—")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.warmTextFaint)
                }
            }
        }
    }

    // MARK: - Options

    private var resolutionOptions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PICK ONE")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.warmTextFaint)
                .padding(.horizontal, 20)

            VStack(spacing: 8) {
                option(letter: "A",
                       title: "Skip \(secondName) this week",
                       detail: "\(secondaryActivity?.venueName ?? "the venue") often runs this every week — \(secondaryKid?.name ?? "the kid") can do next session instead.",
                       tag: "Easiest", tagColor: .registeredText, recommended: true,
                       action: { skipSecondary() })

                if store.linkedParent != nil {
                    option(letter: "B",
                           title: "Keep both, split with \(store.linkedParent!.partner.name)",
                           detail: "\(store.linkedParent!.partner.name) takes one; you stay with the other.",
                           tag: "If linked", tagColor: .partnerBlueInk,
                           action: { assignSplit() })
                }

                option(letter: store.linkedParent != nil ? "C" : "B",
                       title: "Cancel one",
                       detail: "Frees up the time entirely — un-registers from the venue.",
                       tag: nil, tagColor: nil, danger: true,
                       action: { cancelSecondary() })
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 18)
    }

    private var secondName: String {
        secondaryActivity?.name.split(separator: " ").prefix(1).joined() ?? "the second"
    }

    @ViewBuilder
    private func option(
        letter: String, title: String, detail: String,
        tag: String?, tagColor: Color?,
        recommended: Bool = false, danger: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Text(letter)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(recommended ? .white : .warmTextPrimary)
                    .frame(width: 26, height: 26)
                    .background(
                        recommended ? AnyShapeStyle(Color.registeredGreen)
                                    : AnyShapeStyle(Color(brown: 0.05)),
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 13.5, weight: .bold))
                            .kerning(-0.2)
                            .foregroundStyle(danger ? .warmTextTertiary : .warmTextPrimary)
                        if let tag, let tagColor {
                            Text(tag.uppercased())
                                .font(.system(size: 9.5, weight: .bold))
                                .tracking(0.3)
                                .foregroundStyle(tagColor)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(tagColor, lineWidth: 1)
                                )
                        }
                    }
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundStyle(.warmTextTertiary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.warmTextFaint)
                    .padding(.top, 6)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                danger ? AnyShapeStyle(Color.clear) : AnyShapeStyle(Color.warmCard),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        recommended ? Color.registeredGreen : Color(brown: 0.08),
                        lineWidth: recommended ? 1.5 : 0.5
                    )
            )
            .shadow(
                color: recommended ? Color.registeredGreen.opacity(0.12) : .clear,
                radius: 8, y: 2
            )
            .opacity(danger ? 0.85 : 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func skipSecondary() {
        // Skip the second event for this date only — remove it from
        // calendarEvents but keep the underlying registration.
        store.calendarEvents.removeAll { $0.id == conflict.secondary.id }
        dismiss()
    }

    private func assignSplit() {
        guard let partner = store.linkedParent?.partner else { return }
        // Split: kid A → you, kid B → partner. Both events stay, but
        // each one's parent chip clarifies who's taking which kid.
        if let kidA = primaryKid, let kidB = secondaryKid {
            // Per-session assignment for the date of each conflicting event.
            store.setAssignment(.solo(parentId: store.selfParent.id),
                                for: conflict.primary.activityId, on: conflict.primary.date)
            store.setAssignment(.solo(parentId: partner.id),
                                for: conflict.secondary.activityId, on: conflict.secondary.date)
            _ = (kidA, kidB)  // referenced for clarity above
        }
        dismiss()
    }

    private func cancelSecondary() {
        // Cancel = un-register. Removes from registered set + drops the
        // generated calendar events for that activity. The activity stays
        // in Saved as "considering".
        if let a = secondaryActivity {
            store.toggleRegistered(a)
        }
        dismiss()
    }

    private func fetchTravel() async {
        defer { travelLoading = false }
        guard let primary = primaryActivity, let secondary = secondaryActivity,
              let v1 = store.venueBySlug[primary.venueSlug],
              let v2 = store.venueBySlug[secondary.venueSlug] else { return }
        let from = CLLocationCoordinate2D(latitude: v1.centerLat, longitude: v1.centerLon)
        let to = CLLocationCoordinate2D(latitude: v2.centerLat, longitude: v2.centerLon)
        travelMinutes = await TravelTimeService.shared.driveMinutes(from: from, to: to)
    }
}
