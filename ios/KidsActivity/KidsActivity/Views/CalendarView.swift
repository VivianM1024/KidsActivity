import SwiftUI

// V5 Calendar — month strip + day-grouped agenda of registered events.

struct CalendarView: View {
    @Environment(ActivityStore.self) private var store
    @State private var displayedMonth: Date = Date()
    @State private var showExport: Bool = false
    @State private var icsURL: URL?
    @State private var googleSafariURL: URL?
    @State private var lastBatch: [String] = []
    @State private var exportedCount: Int?
    @State private var exportError: String?
    @State private var resolveConflict: ActivityStore.Conflict?
    private let exporter = CalendarExportService()

    private var calendar: Calendar { Calendar(identifier: .iso8601) }
    private var todayStartOfDay: Date { calendar.startOfDay(for: Date()) }
    /// Calendar events fan out from `store.calendarEvents`; here we batch-
    /// fetch the matching Activity rows so each event row can render its
    /// title/venue without a per-row SQL hit.
    private var activitiesById: [String: Activity] {
        let ids = Array(Set(store.calendarEvents.map(\.activityId)))
        let rows = store.repository?.activities(ids: ids) ?? []
        return Dictionary(uniqueKeysWithValues: rows.map { ($0.activityId, $0) })
    }
    private var venuesBySlug: [String: Venue] { store.venueBySlug }
    private var kidsById: [UUID: Kid] {
        Dictionary(uniqueKeysWithValues: store.kids.map { ($0.id, $0) })
    }

    @State private var parentFilter: ParentFilter = .all

    enum ParentFilter: Hashable {
        case all, mine, theirs, both
    }

    private var allUpcomingEvents: [CalendarEvent] {
        store.calendarEvents
            .filter { $0.date >= todayStartOfDay }
            .sorted { $0.date < $1.date }
    }

    /// Events filtered by the parent-filter strip. When unlinked or no
    /// assignments exist, the strip isn't shown and this returns everything.
    private var upcomingEvents: [CalendarEvent] {
        guard store.hasAnyAssignment, store.linkedParent != nil else {
            return allUpcomingEvents
        }
        let me = store.selfParent.id
        let theirs = store.linkedParent?.partner.id
        return allUpcomingEvents.filter { e in
            let assignment = store.assignment(for: e.activityId, on: e.date)
            switch parentFilter {
            case .all: return true
            case .mine:
                guard let a = assignment else { return false }
                if case .solo(let pid) = a.kind, pid == me { return true }
                if case .split(let m) = a.kind, m[e.kidId] == me { return true }
                return false
            case .theirs:
                guard let a = assignment, let theirs else { return false }
                if case .solo(let pid) = a.kind, pid == theirs { return true }
                if case .split(let m) = a.kind, m[e.kidId] == theirs { return true }
                return false
            case .both:
                guard let a = assignment, case .both = a.kind else { return false }
                return true
            }
        }
    }

    private var parentFilterCounts: (all: Int, mine: Int, theirs: Int, both: Int) {
        var mine = 0, theirs = 0, both = 0
        let me = store.selfParent.id
        let pid = store.linkedParent?.partner.id
        for e in allUpcomingEvents {
            guard let a = store.assignment(for: e.activityId, on: e.date) else { continue }
            switch a.kind {
            case .both: both += 1
            case .solo(let p):
                if p == me { mine += 1 }
                else if p == pid { theirs += 1 }
            case .split(let m):
                if m[e.kidId] == me { mine += 1 }
                else if m[e.kidId] == pid { theirs += 1 }
            }
        }
        return (allUpcomingEvents.count, mine, theirs, both)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.warmCanvas.ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    titleBlock
                        .padding(.horizontal, 20)
                        .padding(.top, 8).padding(.bottom, 8)

                    if store.linkedParent != nil, store.hasAnyAssignment {
                        parentFilterBar
                            .padding(.horizontal, 16)
                            .padding(.top, 6).padding(.bottom, 6)
                    }

                    monthStrip
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    dayGroups
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    Color.clear.frame(height: 32)
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.warmCanvas, for: .navigationBar)
        .sheet(item: $icsURL) { url in
            ShareSheet(items: [url])
        }
        .sheet(item: $googleSafariURL) { url in
            SafariView(url: url).ignoresSafeArea()
        }
        .sheet(item: $resolveConflict) { c in
            ResolveConflictSheet(conflict: c)
        }
        .alert("Couldn't add events", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
        .overlay(alignment: .top) {
            if let count = exportedCount {
                exportToast(count: count)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: exportedCount)
    }

    private func exportToast(count: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.registeredGreen)
            Text("Added \(count) \(count == 1 ? "event" : "events") to Calendar")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.warmTextPrimary)
            Spacer(minLength: 0)
            Button("Undo") { undoLastBatch() }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.terracotta)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.warmCard)
                .shadow(color: Color(brown: 0.12), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(brown: 0.08), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Parent filter bar

    /// Shown only when a partner is linked AND at least one event has been
    /// assigned. Pill row of All / Mine / Theirs / Both with counts.
    /// Mirrors `v5-coparent.jsx::V5CalendarByParent` strip.
    private var parentFilterBar: some View {
        let counts = parentFilterCounts
        let partner = store.linkedParent?.partner ?? .defaultPartner
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                pfPill(.all, label: "All", count: counts.all, chip: nil)
                pfPill(.mine, label: "Mine", count: counts.mine,
                       chip: AnyView(ParentChip(kind: .solo(store.selfParent), size: 16)))
                pfPill(.theirs, label: "\(partner.name)'s", count: counts.theirs,
                       chip: AnyView(ParentChip(kind: .solo(partner), size: 16)))
                pfPill(.both, label: "Both", count: counts.both,
                       chip: AnyView(ParentChip(kind: .both, size: 16)))
            }
        }
    }

    private func pfPill(_ filter: ParentFilter, label: String, count: Int, chip: AnyView?) -> some View {
        let on = parentFilter == filter
        return Button {
            parentFilter = filter
        } label: {
            HStack(spacing: 6) {
                if let chip { chip }
                Text(label)
                    .font(.system(size: 12.5, weight: .semibold))
                Text("\(count)")
                    .font(.system(size: 10.5, weight: .bold).monospacedDigit())
                    .opacity(on ? 0.7 : 1)
                    .foregroundStyle(on ? Color.white.opacity(0.7) : .warmTextFaint)
            }
            .foregroundStyle(on ? Color.white : .warmTextPrimary)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(on ? Color.warmTextPrimary : Color.warmCard, in: Capsule())
            .overlay(Capsule().stroke(Color(brown: 0.08), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Title

    private var titleBlock: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(upcomingEvents.count) UPCOMING")
                    .font(.v5Eyebrow)
                    .tracking(0.5)
                    .foregroundStyle(Color.oklch(0.55, 0.05, 60))
                Text(Formatters.monthYear.string(from: displayedMonth))
                    .font(.v5Display)
                    .kerning(-0.6)
                    .foregroundStyle(.warmTextPrimary)
            }
            Spacer(minLength: 0)
            exportMenu
        }
    }

    private var exportMenu: some View {
        Menu {
            Button {
                exportICS()
            } label: { Label("Download .ics", systemImage: "arrow.down.doc") }
            Button {
                openInAppleCalendar()
            } label: { Label("Add to Apple Calendar", systemImage: "calendar") }
            Button {
                openInGoogleCalendar()
            } label: { Label("Add to Google Calendar", systemImage: "globe") }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 11, weight: .bold))
                Text("Export")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.terracotta)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.warmCard, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(brown: 0.08), lineWidth: 0.5)
            )
        }
        .disabled(upcomingEvents.isEmpty)
    }

    // MARK: - Month strip

    private var monthStrip: some View {
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let range = calendar.range(of: .day, in: .month, for: displayedMonth) ?? 1..<31
        let daysInMonth = range.count
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) // 1=Sunday

        // Build a set of "days that have at least one event" for quick lookup.
        let eventDayKeys: Set<String> = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return Set(upcomingEvents.map { f.string(from: $0.date) })
        }()
        let conflictKeys = store.conflictDayKeys

        return VStack(spacing: 6) {
            HStack(spacing: 2) {
                ForEach(["S","M","T","W","T","F","S"].indices, id: \.self) { i in
                    Text(["S","M","T","W","T","F","S"][i])
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.4)
                        .foregroundStyle(.warmTextFaint)
                        .frame(maxWidth: .infinity)
                }
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0..<(firstWeekday - 1), id: \.self) { _ in
                    Color.clear.frame(height: 36)
                }
                ForEach(1...daysInMonth, id: \.self) { day in
                    let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)!
                    let key = isoKey(date)
                    let isToday = calendar.isDate(date, inSameDayAs: Date())
                    let hasEvent = eventDayKeys.contains(key)
                    let isConflict = conflictKeys.contains(key)
                    monthCell(day: day, isToday: isToday, hasEvent: hasEvent, isConflict: isConflict)
                }
            }
        }
        .padding(12)
        .background(Color.warmCard, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(brown: 0.06), lineWidth: 0.5)
        )
        .shadow(color: Color(brown: 0.04), radius: 1, y: 1)
    }

    private func monthCell(day: Int, isToday: Bool, hasEvent: Bool, isConflict: Bool) -> some View {
        VStack(spacing: 1) {
            Text("\(day)")
                .font(.system(size: 12, weight: hasEvent || isToday ? .bold : .medium).monospacedDigit())
                .foregroundStyle(
                    isToday ? Color.white : (hasEvent ? .warmTextPrimary : .warmTextFaint)
                )
            Circle()
                .fill(
                    isToday ? Color.white
                    : isConflict ? Color.amberWarn
                    : hasEvent ? Color.registeredGreen
                    : .clear
                )
                .frame(width: 4, height: 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .background(
            isToday ? AnyShapeStyle(Color.terracotta)
            : isConflict ? AnyShapeStyle(Color.amberWarnSoft)
            : AnyShapeStyle(Color.clear),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isConflict && !isToday ? Color.amberWarn : Color.clear, lineWidth: 1.5)
        )
    }

    // MARK: - Day groups

    private var dayGroups: some View {
        Group {
            if upcomingEvents.isEmpty {
                emptyState
            } else {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(groupByDay(upcomingEvents), id: \.0) { (key, events) in
                        let conflicts = store.conflicts(on: events.first!.date)
                        DayBlock(date: events.first!.date, events: events,
                                 activitiesById: activitiesById,
                                 kidsById: kidsById,
                                 venuesBySlug: venuesBySlug,
                                 home: store.homeCoordinate,
                                 store: store,
                                 conflicts: conflicts,
                                 onResolveConflict: { c in resolveConflict = c })
                    }
                    Text("Tap “Export” to add to Apple or Google Calendar")
                        .font(.system(size: 11))
                        .foregroundStyle(.warmTextFaint)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                }
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            illustration: AnyView(EmptyIllCalendar()),
            eyebrow: "Nothing scheduled",
            title: "Your calendar is clear.",
            copy: "Once you confirm a saved activity, its sessions show up here — with reminders the day before."
        )
    }

    // MARK: - Helpers

    private func isoKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func groupByDay(_ events: [CalendarEvent]) -> [(String, [CalendarEvent])] {
        var buckets: [String: [CalendarEvent]] = [:]
        var order: [String] = []
        for e in events {
            let k = isoKey(e.date)
            if buckets[k] == nil { order.append(k); buckets[k] = [] }
            buckets[k]!.append(e)
        }
        return order.map { ($0, buckets[$0]!.sorted { $0.date < $1.date }) }
    }

    // MARK: - Export actions

    private func exportICS() {
        let url = ICSExporter.write(events: upcomingEvents, activitiesById: activitiesById)
        icsURL = url
    }

    private func openInAppleCalendar() {
        // Silent batch write to the user's default calendar via EventKit.
        // Toast appears on success with an Undo affordance for ~6 seconds.
        let batch = upcomingEvents
        let lookup = activitiesById
        Task {
            do {
                let ids = try await exporter.addEvents(batch, activitiesById: lookup)
                self.lastBatch = ids
                self.exportedCount = ids.count
                let pending = ids
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                if self.lastBatch == pending {
                    self.exportedCount = nil
                }
            } catch {
                self.exportError = (error as? LocalizedError)?.errorDescription
                    ?? error.localizedDescription
            }
        }
    }

    private func undoLastBatch() {
        let ids = lastBatch
        lastBatch = []
        exportedCount = nil
        Task {
            try? await exporter.removeEvents(identifiers: ids)
        }
    }

    private func openInGoogleCalendar() {
        // Open the first event in Google's web template inside an in-app
        // SFSafariViewController. Bulk import via .ics requires the desktop
        // UI, which is mentioned in the menu copy.
        guard let e = upcomingEvents.first,
              let a = activitiesById[e.activityId],
              let url = ICSExporter.googleTemplateURL(event: e, activity: a) else { return }
        googleSafariURL = url
    }
}

// MARK: - Day block + day event

struct DayBlock: View {
    let date: Date
    let events: [CalendarEvent]
    let activitiesById: [String: Activity]
    let kidsById: [UUID: Kid]
    let venuesBySlug: [String: Venue]
    let home: CLLocationCoordinate2D
    let store: ActivityStore
    let conflicts: [ActivityStore.Conflict]
    let onResolveConflict: (ActivityStore.Conflict) -> Void

    private var dayNumber: String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: date)
    }
    private var weekdayName: String { Formatters.weekdayLong.string(from: date) }
    private var monthDay: String    { Formatters.monthDay.string(from: date) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(dayNumber)
                    .font(.system(size: 22, weight: .bold).monospacedDigit())
                    .kerning(-0.4)
                    .foregroundStyle(.warmTextPrimary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(weekdayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.warmTextPrimary)
                    Text(monthDay)
                        .font(.system(size: 11))
                        .foregroundStyle(.warmTextFaint)
                }
                Rectangle().fill(Color(brown: 0.08)).frame(height: 1)

                if !conflicts.isEmpty {
                    Button { onResolveConflict(conflicts[0]) } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text("\(conflicts.count) conflict\(conflicts.count == 1 ? "" : "s")")
                                .font(.system(size: 10.5, weight: .bold))
                                .tracking(0.3)
                                .textCase(.uppercase)
                        }
                        .foregroundStyle(.amberWarnInk)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.amberWarnSoft, in: Capsule())
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("\(events.count) \(events.count == 1 ? "event" : "events")")
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundStyle(.warmTextFaint)
                }
            }

            VStack(spacing: 6) {
                ForEach(events, id: \.id) { e in
                    if let a = activitiesById[e.activityId] {
                        DayEventCard(
                            event: e, activity: a,
                            kid: kidsById[e.kidId],
                            venue: venuesBySlug[a.venueSlug],
                            home: home,
                            assignment: store.assignment(for: a.activityId, on: e.date),
                            partner: store.linkedParent?.partner,
                            self_: store.selfParent
                        )
                    }
                }
            }
        }
    }
}

struct DayEventCard: View {
    let event: CalendarEvent
    let activity: Activity
    let kid: Kid?
    let venue: Venue?
    let home: CLLocationCoordinate2D
    let assignment: Assignment?
    let partner: Parent?
    let self_: Parent

    private var category: ActivityCategory { activity.inferredCategory }
    private var distance: Double? { Formatters.distanceMiles(home: home, venue: venue) }
    private var accentColor: Color { kid?.avatarColor3pxAccent ?? category.style.dot }

    /// ParentChip kind for this event — nil when unassigned (chip hidden).
    private var assignmentChipKind: ParentChip.Kind? {
        guard let assignment else { return nil }
        switch assignment.kind {
        case .both:
            return .both
        case .solo(let pid):
            if pid == self_.id { return .solo(self_) }
            if let p = partner, pid == p.id { return .solo(p) }
            return nil
        case .split(let m):
            // Show solo chip for the parent assigned to *this* kid.
            guard let kidId = kid?.id, let pid = m[kidId] else { return nil }
            if pid == self_.id { return .solo(self_) }
            if let p = partner, pid == p.id { return .solo(p) }
            return nil
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Time gutter
            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatters.timeOfDay.string(from: event.date))
                    .font(.system(size: 13, weight: .bold).monospacedDigit())
                    .foregroundStyle(.warmTextPrimary)
                Text("\(event.durationMinutes)m")
                    .font(.system(size: 10).monospacedDigit())
                    .foregroundStyle(.warmTextFaint)
            }
            .frame(width: 56, alignment: .trailing)
            .padding(.top, 10)

            // Card
            cardBody

            // Parent chip — only when this event has an explicit assignment.
            // Unassigned events look like normal calendar rows, so chips don't
            // visually clutter single-parent users.
            if let kind = assignmentChipKind {
                ParentChip(kind: kind, size: 22)
                    .padding(.top, 12)
                    .padding(.trailing, 4)
            }
        }
    }

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if let kid {
                        Text(kid.initial)
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(kid.avatarColor, in: Circle())
                    }
                    Text(category.label.uppercased())
                        .font(.system(size: 9.5, weight: .bold))
                        .tracking(0.4)
                        .foregroundStyle(category.style.chipFG)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(category.style.chipBG, in: RoundedRectangle(cornerRadius: 4))
                    Text(activity.name)
                        .font(.system(size: 13.5, weight: .semibold))
                        .kerning(-0.2)
                        .foregroundStyle(.warmTextPrimary)
                        .lineLimit(1)
                }
                HStack(spacing: 5) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 10))
                        .foregroundStyle(.warmTextTertiary)
                    Text(activity.venueName + (activity.location.isEmpty ? "" : " · \(activity.location)"))
                        .font(.system(size: 11.5))
                        .foregroundStyle(.warmTextTertiary)
                        .lineLimit(1)
                    if let m = Formatters.miles(distance) {
                        Circle().fill(Color.warmDotSeparator).frame(width: 2, height: 2)
                        Text(m)
                            .font(.system(size: 11.5).monospacedDigit())
                            .foregroundStyle(.warmTextTertiary)
                    }
                }
                if let note = event.note {
                    HStack(spacing: 4) {
                        Image(systemName: "pin.fill").font(.system(size: 9))
                        Text(note)
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.warmTextSecondary)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(Color.oklch(0.96, 0.04, 60), in: RoundedRectangle(cornerRadius: 6))
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.warmCard, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(brown: 0.05), lineWidth: 0.5)
            )
            .overlay(alignment: .leading) {
                Rectangle().fill(accentColor)
                    .frame(width: 3)
                    .clipShape(RoundedCorner(radius: 12, corners: [.topLeft, .bottomLeft]))
            }
            .shadow(color: Color(brown: 0.03), radius: 1, y: 1)
    }
}

// MARK: - URL Identifiable wrapper for sheet

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - Share sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

// MARK: - ICS Exporter

import CoreLocation

enum ICSExporter {
    /// Build a .ics string for the given events and write it to a temporary
    /// file, returning its URL. Caller is responsible for sharing/opening it.
    static func write(events: [CalendarEvent], activitiesById: [String: Activity]) -> URL? {
        let ics = build(events: events, activitiesById: activitiesById)
        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent("kidsactivity.ics")
        do {
            try ics.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    static func build(events: [CalendarEvent], activitiesById: [String: Activity]) -> String {
        var lines: [String] = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//KidsActivity//EN",
            "CALSCALE:GREGORIAN",
        ]
        let dtFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyyMMdd'T'HHmmss"
            f.timeZone = .current
            return f
        }()

        for e in events {
            guard let a = activitiesById[e.activityId] else { continue }
            let start = dtFormatter.string(from: e.date)
            let endDate = e.date.addingTimeInterval(TimeInterval(e.durationMinutes * 60))
            let end = dtFormatter.string(from: endDate)
            let uid = "\(a.activityId)-\(start)@kidsactivity"

            var description = a.description ?? ""
            if let note = e.note {
                description += description.isEmpty ? "Note: \(note)" : "\n\nNote: \(note)"
            }
            description += "\n\nRegistration: \(a.sourceUrl.absoluteString)"

            lines.append(contentsOf: [
                "BEGIN:VEVENT",
                "UID:\(uid)",
                "DTSTAMP:\(start)",
                "DTSTART:\(start)",
                "DTEND:\(end)",
                "SUMMARY:\(escape(a.name))",
                "LOCATION:\(escape(a.venueName + (a.location.isEmpty ? "" : " — \(a.location)")))",
                "DESCRIPTION:\(escape(description))",
                "URL:\(a.sourceUrl.absoluteString)",
                "END:VEVENT",
            ])
        }
        lines.append("END:VCALENDAR")
        return lines.joined(separator: "\r\n")
    }

    static func googleTemplateURL(event: CalendarEvent, activity: Activity) -> URL? {
        let utc: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            f.timeZone = TimeZone(secondsFromGMT: 0)
            return f
        }()
        let startUTC = utc.string(from: event.date)
        let endUTC = utc.string(from: event.date.addingTimeInterval(TimeInterval(event.durationMinutes * 60)))
        var components = URLComponents(string: "https://calendar.google.com/calendar/render")!
        components.queryItems = [
            URLQueryItem(name: "action", value: "TEMPLATE"),
            URLQueryItem(name: "text", value: activity.name),
            URLQueryItem(name: "dates", value: "\(startUTC)/\(endUTC)"),
            URLQueryItem(name: "details", value: [
                activity.description ?? "",
                event.note.map { "Note: \($0)" } ?? "",
                "Registration: \(activity.sourceUrl.absoluteString)"
            ].filter { !$0.isEmpty }.joined(separator: "\n\n")),
            URLQueryItem(name: "location", value: activity.venueName + (activity.location.isEmpty ? "" : " — \(activity.location)"))
        ]
        return components.url
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "\n", with: "\\n")
         .replacingOccurrences(of: ",", with: "\\,")
         .replacingOccurrences(of: ";", with: "\\;")
    }
}
