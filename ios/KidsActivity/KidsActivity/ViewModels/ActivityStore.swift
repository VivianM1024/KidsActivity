import Foundation
import Observation
import CoreLocation
import OSLog

private let log = Logger(subsystem: "com.vivianm1024.KidsActivity", category: "store")

// Single source of truth — owns the loaded data, the active filters, the
// user's kids, saved/registered sets, and the calendar events derived from
// registered activities.

@Observable
@MainActor
final class ActivityStore {
    enum LoadState {
        case idle
        case loading
        case ready
        case error(String)
    }

    var state: LoadState = .idle
    var manifest: Manifest?
    var venues: [Venue] = []
    /// SQLite-backed query layer. Replaces the old in-memory `[Activity]`
    /// array — Browse, Saved, and Calendar lookups all flow through this.
    var repository: SQLiteActivityRepository?
    /// Total row count, populated on load. Drives "Chicagoland · X listings".
    var totalActivityCount: Int = 0
    /// Per-venue-type counts for FilterSheet's right-aligned tallies.
    var venueTypeCounts: [VenueType: Int] = [:]
    var filters: ActivityFilters = .default

    // Household / personalization. Empty by default — onboarding is what
    // populates these. Existing installs that already have data persisted
    // get auto-marked as onboarded in `loadPersistedState()`.
    var kids: [Kid] = []
    var selectedKidIds: Set<UUID> = []

    var savedActivityIds: Set<String> = []
    var registeredActivityIds: Set<String> = []
    var calendarEvents: [CalendarEvent] = []

    // Co-parent (opt-in). When `linkedParent` is nil we hide every co-parent
    // surface (filter bar, "+ Add Sam" row, parent chips). Once set, a parent
    // chip on Calendar appears only for events that have an explicit
    // assignment — unassigned events stay neutral.
    var linkedParent: LinkedParent? = nil
    var assignments: [Assignment] = []

    /// Append-only audit log of co-parent-relevant events. Surfaced in
    /// LinkedSettingsView's "Recent activity" card. Capped at the last 30
    /// entries so the snapshot stays small.
    var activityLog: [ActivityLogEntry] = []

    /// True when the most recent load served stale cached data (network
    /// fetch failed and the on-disk cache filled in). Drives the
    /// `CachedBanner` above the Browse list.
    var lastLoadFromCache: Bool = false
    var lastCacheDate: Date? = nil

    var sortMode: SortMode = .when
    var searchText: String = ""

    // Onboarding gate + the home address it captures.
    var hasCompletedOnboarding: Bool = false
    var homeZIP: String = ""
    var homeNeighborhood: String = ""
    var weeklyAvailability: Set<ActivityFilters.DayOfWeek> = []

    /// Logan Square, Chicago — the prototype's hardcoded fallback. Onboarding
    /// overwrites this with the user's geocoded ZIP or location fix.
    var homeCoordinate: CLLocationCoordinate2D = .init(latitude: 41.929, longitude: -87.706)

    private let loader = DataLoader()
    private let persistence = StorePersistence()

    var selectedKids: [Kid] { kids.filter { selectedKidIds.contains($0.id) } }
    var venueBySlug: [String: Venue] { Dictionary(uniqueKeysWithValues: venues.map { ($0.slug, $0) }) }

    /// Browse list — SQLite query that filters + sorts in one shot.
    /// Returns [] before the repository is loaded so the skeleton can show.
    var filteredActivities: [Activity] {
        guard let repository else { return [] }
        var f = filters
        f.homeCoordinate = homeCoordinate
        return repository.query(
            filters: f, kids: selectedKids, sort: sortMode,
            searchText: searchText, home: homeCoordinate
        )
    }

    var savedActivities: [Activity] {
        guard let repository else { return [] }
        return repository.activities(ids: Array(savedActivityIds))
            .sorted { lhs, rhs in
                let l = lhs.schedule.startDate ?? .distantFuture
                let r = rhs.schedule.startDate ?? .distantFuture
                return l < r
            }
    }

    /// Look up a single activity by id. Hot path for calendar / saved /
    /// registration flows that work in terms of stored activity_ids.
    func activity(forId id: String) -> Activity? {
        repository?.activity(id: id)
    }

    var consideringActivities: [Activity] {
        savedActivities.filter { !registeredActivityIds.contains($0.activityId) }
    }

    var registeredActivities: [Activity] {
        savedActivities.filter { registeredActivityIds.contains($0.activityId) }
    }

    /// User-assigned kid for a saved activity — defaults to the youngest
    /// kid whose age fits the activity, falling back to the first selected kid.
    var savedKidByActivity: [String: UUID] = [:]

    func kid(for activityId: String) -> Kid? {
        if let id = savedKidByActivity[activityId] {
            return kids.first { $0.id == id }
        }
        // Fallback: pick first selected kid whose age fits the activity.
        guard let activity = activity(forId: activityId) else { return nil }
        return matchKids(for: activity).first ?? kids.first
    }

    /// Kids whose age falls within the activity's age range (±1 year window).
    /// The wider window matches the README's "±1y" match-dot spec: a 4-year-old
    /// will register a match for a "ages 3–5" class.
    func matchKids(for a: Activity) -> [Kid] {
        let lo = a.ageRange.minMonths.map { max(0, $0 - 12) } ?? 0
        let hi = a.ageRange.maxMonths.map { $0 + 12 } ?? 10_000
        return selectedKids.filter { $0.ageMonths >= lo && $0.ageMonths <= hi }
    }

    // MARK: - Load

    func load(forceRefresh: Bool = false) async {
        state = .loading
        let result = await loader.load(forceRefresh: forceRefresh)
        switch result {
        case .success(let data):
            self.manifest = data.manifest
            self.venues = data.venues
            self.repository = data.repository
            self.totalActivityCount = data.repository.totalCount()
            self.venueTypeCounts = data.repository.countsByVenueType()
            self.lastLoadFromCache = data.fromCache
            self.lastCacheDate = data.cacheDate
            self.state = .ready
            log.info("store.load ready: \(self.totalActivityCount) activities, fromCache=\(data.fromCache)")
        case .failure(let err):
            log.error("store.load failed: \(String(describing: err))")
            self.state = .error(describe(err))
        }
    }

    func refresh() async { await load(forceRefresh: true) }

    /// Restore kids, saved set, and registered set from disk. Call on app
    /// launch before the first render so the UI reflects last session.
    func loadPersistedState() {
        let snap = persistence.load()
        self.kids = snap.kids
        self.selectedKidIds = snap.selectedKidIds
        self.savedActivityIds = snap.savedActivityIds
        self.registeredActivityIds = snap.registeredActivityIds
        self.savedKidByActivity = snap.savedKidByActivity
        self.calendarEvents = snap.calendarEvents
        self.weeklyAvailability = snap.weeklyAvailability
        self.homeZIP = snap.homeZIP
        self.homeNeighborhood = snap.homeNeighborhood
        if let lat = snap.homeLat, let lon = snap.homeLon {
            self.homeCoordinate = .init(latitude: lat, longitude: lon)
        }
        self.linkedParent = snap.linkedParent
        self.assignments = snap.assignments
        self.activityLog = snap.activityLog
        // Pre-onboarding installs already had data — treat that as onboarded
        // so they don't see the flow on next launch.
        self.hasCompletedOnboarding = snap.hasCompletedOnboarding
            || !snap.kids.isEmpty
            || !snap.savedActivityIds.isEmpty
    }

    private func persist() {
        persistence.save(.init(
            kids: kids,
            selectedKidIds: selectedKidIds,
            savedActivityIds: savedActivityIds,
            registeredActivityIds: registeredActivityIds,
            savedKidByActivity: savedKidByActivity,
            calendarEvents: calendarEvents,
            hasCompletedOnboarding: hasCompletedOnboarding,
            homeZIP: homeZIP,
            homeNeighborhood: homeNeighborhood,
            homeLat: homeCoordinate.latitude,
            homeLon: homeCoordinate.longitude,
            weeklyAvailability: weeklyAvailability,
            linkedParent: linkedParent,
            assignments: assignments,
            activityLog: activityLog
        ))
    }

    // MARK: - Co-parent

    var hasAnyAssignment: Bool { !assignments.isEmpty }

    /// "You" identity. Built fresh each access since it doesn't carry state
    /// beyond the user's choice of name (and we just hardcode "You" today).
    var selfParent: Parent { .defaultYou }

    /// Resolve assignment for an activity, optionally a specific session date.
    /// Session-specific overrides win; activity-level default is the fallback.
    func assignment(for activityId: String, on date: Date? = nil) -> Assignment? {
        if let date {
            let session = assignments.first { a in
                guard a.activityId == activityId, let s = a.sessionDate else { return false }
                return Calendar.current.isDate(s, inSameDayAs: date)
            }
            if let session { return session }
        }
        return assignments.first { $0.activityId == activityId && $0.sessionDate == nil }
    }

    func setAssignment(_ kind: AssignmentKind, for activityId: String, on date: Date? = nil) {
        let new = Assignment(activityId: activityId, sessionDate: date, kind: kind)
        // Replace any existing assignment for this (activity, sessionDate) tuple.
        assignments.removeAll { existing in
            existing.activityId == activityId &&
            (existing.sessionDate?.timeIntervalSince1970 == date?.timeIntervalSince1970)
        }
        assignments.append(new)
        if let activity = activity(forId: activityId) {
            appendLog(.assigned(activityName: activity.name, kind: kind.label))
        }
        persist()
    }

    func clearAssignment(for activityId: String, on date: Date? = nil) {
        assignments.removeAll { a in
            a.activityId == activityId &&
            (a.sessionDate?.timeIntervalSince1970 == date?.timeIntervalSince1970)
        }
        persist()
    }

    func linkPartner(_ partner: Parent, code: String) {
        linkedParent = LinkedParent(partner: partner, inviteCode: code, linkedAt: Date())
        appendLog(.linked(partnerName: partner.name, code: code))
        persist()
    }

    /// Unlinks the partner and clears every assignment — assignments
    /// reference the partner's UUID, so leaving them dangling would render
    /// nothing on screen.
    func unlinkPartner() {
        let name = linkedParent?.partner.name ?? "Partner"
        linkedParent = nil
        assignments.removeAll()
        appendLog(.unlinked(partnerName: name))
        persist()
    }

    private func appendLog(_ event: ActivityLogEntry.Event) {
        activityLog.append(ActivityLogEntry(at: Date(), event: event))
        if activityLog.count > 30 {
            activityLog.removeFirst(activityLog.count - 30)
        }
    }

    // MARK: - Conflicts

    /// A pair of overlapping events on the same day. Two events conflict
    /// when their time windows intersect. Conflicts are computed lazily —
    /// no persisted state.
    struct Conflict: Hashable, Identifiable {
        let id: String           // dayKey:eventA:eventB
        let dayKey: String       // "yyyy-MM-dd"
        let primary: CalendarEvent
        let secondary: CalendarEvent
        let overlapMinutes: Int
    }

    /// Returns conflicts whose events fall on `date` (start-of-day match).
    func conflicts(on date: Date) -> [Conflict] {
        let cal = Calendar(identifier: .iso8601)
        let dayKey = isoKey(cal.startOfDay(for: date))
        let dayEvents = calendarEvents.filter {
            isoKey(cal.startOfDay(for: $0.date)) == dayKey
        }
        return findConflicts(in: dayEvents, dayKey: dayKey)
    }

    /// Set of `yyyy-MM-dd` keys for every day that has at least one conflict
    /// among the upcoming events. Used by the Calendar month-strip ring.
    var conflictDayKeys: Set<String> {
        let cal = Calendar(identifier: .iso8601)
        let buckets = Dictionary(grouping: calendarEvents) {
            isoKey(cal.startOfDay(for: $0.date))
        }
        var out: Set<String> = []
        for (key, list) in buckets where !findConflicts(in: list, dayKey: key).isEmpty {
            out.insert(key)
        }
        return out
    }

    private func findConflicts(in events: [CalendarEvent], dayKey: String) -> [Conflict] {
        guard events.count >= 2 else { return [] }
        let sorted = events.sorted { $0.date < $1.date }
        var conflicts: [Conflict] = []
        for i in 0..<sorted.count {
            for j in (i+1)..<sorted.count {
                let a = sorted[i], b = sorted[j]
                let aEnd = a.date.addingTimeInterval(TimeInterval(a.durationMinutes * 60))
                let bEnd = b.date.addingTimeInterval(TimeInterval(b.durationMinutes * 60))
                if a.date < bEnd && b.date < aEnd {
                    let overlapStart = max(a.date, b.date)
                    let overlapEnd = min(aEnd, bEnd)
                    let mins = Int(overlapEnd.timeIntervalSince(overlapStart) / 60.0)
                    conflicts.append(Conflict(
                        id: "\(dayKey):\(a.id):\(b.id)",
                        dayKey: dayKey, primary: a, secondary: b,
                        overlapMinutes: max(1, mins)
                    ))
                }
            }
        }
        return conflicts
    }

    private func isoKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f.string(from: date)
    }

    /// This week's events broken down by who's responsible. Used by the
    /// LinkedLoadView "load summary" card.
    func loadSummaryThisWeek() -> (you: Int, partner: Int, both: Int) {
        let cal = Calendar(identifier: .iso8601)
        let now = Date()
        guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: now) else {
            return (0, 0, 0)
        }
        var you = 0, partner = 0, both = 0
        for e in calendarEvents where weekInterval.contains(e.date) {
            guard let a = assignment(for: e.activityId, on: e.date) else { continue }
            switch a.kind {
            case .both: both += 1
            case .solo(let pid):
                if pid == selfParent.id { you += 1 }
                else { partner += 1 }
            case .split(let m):
                if m[e.kidId] == selfParent.id { you += 1 }
                else if m[e.kidId] != nil { partner += 1 }
            }
        }
        return (you, partner, both)
    }

    // MARK: - Onboarding

    func completeOnboarding(
        kids: [Kid],
        zip: String,
        neighborhood: String,
        coordinate: CLLocationCoordinate2D?,
        availability: Set<ActivityFilters.DayOfWeek>
    ) {
        self.kids = kids
        self.selectedKidIds = Set(kids.map(\.id))
        self.homeZIP = zip
        self.homeNeighborhood = neighborhood
        if let coordinate { self.homeCoordinate = coordinate }
        self.weeklyAvailability = availability
        // Seed the day-of-week filter with the user's stated availability so
        // Browse opens with relevant rows on day one.
        self.filters.daysOfWeek = availability
        self.hasCompletedOnboarding = true
        persist()
    }

    // MARK: - User actions

    func toggleSaved(_ a: Activity, forKid kid: Kid? = nil) {
        let id = a.activityId
        if savedActivityIds.contains(id) {
            savedActivityIds.remove(id)
            registeredActivityIds.remove(id)
            savedKidByActivity[id] = nil
            calendarEvents.removeAll { $0.activityId == id }
        } else {
            savedActivityIds.insert(id)
            if let kid {
                savedKidByActivity[id] = kid.id
            } else if let auto = matchKids(for: a).first ?? selectedKids.first {
                savedKidByActivity[id] = auto.id
            }
            appendLog(.saved(activityName: a.name))
        }
        persist()
    }

    func setKid(_ kid: Kid, forSaved activityId: String) {
        savedKidByActivity[activityId] = kid.id
        // Re-generate calendar events for this activity if registered.
        if registeredActivityIds.contains(activityId) {
            calendarEvents.removeAll { $0.activityId == activityId }
            if let activity = activity(forId: activityId) {
                calendarEvents.append(contentsOf: makeEvents(for: activity, kid: kid))
            }
        }
        persist()
    }

    func toggleRegistered(_ a: Activity) {
        let id = a.activityId
        if registeredActivityIds.contains(id) {
            registeredActivityIds.remove(id)
            calendarEvents.removeAll { $0.activityId == id }
        } else {
            registeredActivityIds.insert(id)
            // Make sure we keep it saved too.
            savedActivityIds.insert(id)
            if let kid = kid(for: id) {
                if savedKidByActivity[id] == nil { savedKidByActivity[id] = kid.id }
                calendarEvents.append(contentsOf: makeEvents(for: a, kid: kid))
            }
            appendLog(.registered(activityName: a.name))
        }
        persist()
    }

    func toggleSelectedKid(_ kid: Kid) {
        if selectedKidIds.contains(kid.id) {
            // Keep at least one selected so the empty state doesn't trip.
            if selectedKidIds.count > 1 { selectedKidIds.remove(kid.id) }
        } else {
            selectedKidIds.insert(kid.id)
        }
        persist()
    }

    func resetFilters() {
        filters = .default
    }

    // MARK: - Calendar event generation

    /// Expand the first ~8 weekly sessions of an activity into `CalendarEvent`s.
    /// Mirrors the prototype's "Session N of M" agenda.
    private func makeEvents(for a: Activity, kid: Kid) -> [CalendarEvent] {
        guard let start = a.schedule.startDate else { return [] }
        let totalSessions = a.schedule.numSessions ?? a.schedule.weeklyTimes.count
        let weekly = a.schedule.weeklyTimes
        guard totalSessions > 0, !weekly.isEmpty else {
            return [CalendarEvent(
                activityId: a.activityId, kidId: kid.id, date: start,
                durationMinutes: 60
            )]
        }

        let cap = min(totalSessions, 8)
        let cal = Calendar(identifier: .iso8601)

        // Map "Mon"/"Tue"/... to weekday integers (Sun=1 in Calendar).
        let dayMap: [String: Int] = [
            "Sun": 1, "Mon": 2, "Tue": 3, "Wed": 4, "Thu": 5, "Fri": 6, "Sat": 7
        ]

        var events: [CalendarEvent] = []
        var sessionIndex = 0
        var cursor = start
        let end = a.schedule.endDate ?? cal.date(byAdding: .month, value: 6, to: start) ?? start

        // Walk forward day by day, picking days that match the activity's
        // weekly times. Cheap and correct for the small N involved.
        while sessionIndex < cap, cursor <= end {
            let weekday = cal.component(.weekday, from: cursor)
            if let match = weekly.first(where: { dayMap[$0.dayOfWeek] == weekday }) {
                let parts = match.start.split(separator: ":")
                let hour = Int(parts.first ?? "0") ?? 0
                let minute = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
                if let dt = cal.date(bySettingHour: hour, minute: minute, second: 0, of: cursor) {
                    let duration = duration(start: match.start, end: match.end) ?? 60
                    let note = totalSessions > 1
                        ? "Session \(sessionIndex + 1) of \(totalSessions)"
                        : nil
                    events.append(CalendarEvent(
                        activityId: a.activityId, kidId: kid.id, date: dt,
                        durationMinutes: duration, note: note
                    ))
                    sessionIndex += 1
                }
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        return events
    }

    private func duration(start: String, end: String) -> Int? {
        func minutes(_ hms: String) -> Int? {
            let parts = hms.split(separator: ":")
            guard parts.count >= 2,
                  let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
            return h * 60 + m
        }
        guard let s = minutes(start), let e = minutes(end) else { return nil }
        let diff = e - s
        return diff > 0 ? diff : nil
    }

    // MARK: -

    private func describe(_ err: DataLoaderError) -> String {
        switch err {
        case .schemaMismatch(let found, let supported):
            return "Data schema v\(found) is newer than this app (v\(supported)). Update the app."
        case .decode(let e):     return "Couldn't read data: \(e.localizedDescription)"
        case .decompress(let e): return "Couldn't decompress data: \(e.localizedDescription)"
        case .sqlite(let e):     return "Couldn't open the local database: \(e.localizedDescription)"
        case .network(let e):    return "Couldn't reach the server: \(e.localizedDescription)"
        case .missingCache:      return "No cached data available."
        }
    }
}

// MARK: - Persistence (UserDefaults JSON snapshot)

private struct StoreSnapshot: Codable {
    var kids: [Kid] = []
    var selectedKidIds: Set<UUID> = []
    var savedActivityIds: Set<String> = []
    var registeredActivityIds: Set<String> = []
    var savedKidByActivity: [String: UUID] = [:]
    var calendarEvents: [CalendarEvent] = []
    var hasCompletedOnboarding: Bool = false
    var homeZIP: String = ""
    var homeNeighborhood: String = ""
    var homeLat: Double? = nil
    var homeLon: Double? = nil
    var weeklyAvailability: Set<ActivityFilters.DayOfWeek> = []
    var linkedParent: LinkedParent? = nil
    var assignments: [Assignment] = []
    var activityLog: [ActivityLogEntry] = []
}

private final class StorePersistence {
    private static let key = "kidsactivity.v5.store"
    private let defaults = UserDefaults.standard

    func load() -> StoreSnapshot {
        guard let data = defaults.data(forKey: Self.key) else {
            log.info("StorePersistence.load: no data")
            return StoreSnapshot()
        }
        do {
            return try JSONDecoder().decode(StoreSnapshot.self, from: data)
        } catch {
            log.error("StorePersistence.load decode failed: \(String(describing: error))")
            return StoreSnapshot()
        }
    }

    func save(_ snap: StoreSnapshot) {
        guard let data = try? JSONEncoder().encode(snap) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
