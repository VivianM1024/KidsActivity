import Foundation
import Observation
import CoreLocation

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
    var activities: [Activity] = []
    var filters: ActivityFilters = .default

    // Household / personalization
    var kids: [Kid] = Kid.samples
    var selectedKidIds: Set<UUID> = [Kid.sampleMaya.id]

    var savedActivityIds: Set<String> = []
    var registeredActivityIds: Set<String> = []
    var calendarEvents: [CalendarEvent] = []

    var sortMode: SortMode = .when
    var searchText: String = ""

    /// Logan Square, Chicago — the prototype's hardcoded "home" location.
    /// Once a real location service lands, replace this with the user's pin.
    var homeCoordinate: CLLocationCoordinate2D = .init(latitude: 41.929, longitude: -87.706)

    private let loader = DataLoader()
    private let persistence = StorePersistence()

    var selectedKids: [Kid] { kids.filter { selectedKidIds.contains($0.id) } }
    var venueBySlug: [String: Venue] { Dictionary(uniqueKeysWithValues: venues.map { ($0.slug, $0) }) }

    /// `filters.keyword` is set from `searchText`; we surface them as one
    /// filter pipeline so debouncing in the UI is the only knob to tune.
    var filteredActivities: [Activity] {
        var f = filters
        f.keyword = searchText
        f.homeCoordinate = homeCoordinate
        let result = FilterEngine.apply(
            activities: activities, venues: venues, filters: f, kids: selectedKids
        )
        return FilterEngine.sort(result, by: sortMode, venues: venues, home: homeCoordinate)
    }

    var savedActivities: [Activity] {
        let bySaved = Dictionary(uniqueKeysWithValues: activities.map { ($0.activityId, $0) })
        return savedActivityIds.compactMap { bySaved[$0] }
            .sorted { lhs, rhs in
                let l = lhs.schedule.startDate ?? .distantFuture
                let r = rhs.schedule.startDate ?? .distantFuture
                return l < r
            }
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
        guard let activity = activities.first(where: { $0.activityId == activityId }) else { return nil }
        return matchKids(for: activity).first ?? kids.first
    }

    /// Kids whose age falls within the activity's age range (±3 months window).
    func matchKids(for a: Activity) -> [Kid] {
        let lo = a.ageRange.minMonths.map { max(0, $0 - 3) } ?? 0
        let hi = a.ageRange.maxMonths.map { $0 + 3 } ?? 10_000
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
            self.activities = data.activities
            self.state = .ready
        case .failure(let err):
            self.state = .error(describe(err))
        }
    }

    func refresh() async { await load(forceRefresh: true) }

    /// Restore kids, saved set, and registered set from disk. Call on app
    /// launch before the first render so the UI reflects last session.
    func loadPersistedState() {
        let snap = persistence.load()
        if !snap.kids.isEmpty { self.kids = snap.kids }
        if !snap.selectedKidIds.isEmpty { self.selectedKidIds = snap.selectedKidIds }
        self.savedActivityIds = snap.savedActivityIds
        self.registeredActivityIds = snap.registeredActivityIds
        self.savedKidByActivity = snap.savedKidByActivity
        self.calendarEvents = snap.calendarEvents
    }

    private func persist() {
        persistence.save(.init(
            kids: kids,
            selectedKidIds: selectedKidIds,
            savedActivityIds: savedActivityIds,
            registeredActivityIds: registeredActivityIds,
            savedKidByActivity: savedKidByActivity,
            calendarEvents: calendarEvents
        ))
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
        }
        persist()
    }

    func setKid(_ kid: Kid, forSaved activityId: String) {
        savedKidByActivity[activityId] = kid.id
        // Re-generate calendar events for this activity if registered.
        if registeredActivityIds.contains(activityId) {
            calendarEvents.removeAll { $0.activityId == activityId }
            if let activity = activities.first(where: { $0.activityId == activityId }) {
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
        case .decode(let e): return "Couldn't read data: \(e.localizedDescription)"
        case .network(let e): return "Couldn't reach the server: \(e.localizedDescription)"
        case .missingCache: return "No cached data available."
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
}

private final class StorePersistence {
    private static let key = "kidsactivity.v5.store"
    private let defaults = UserDefaults.standard

    func load() -> StoreSnapshot {
        guard let data = defaults.data(forKey: Self.key),
              let snap = try? JSONDecoder().decode(StoreSnapshot.self, from: data) else {
            return StoreSnapshot()
        }
        return snap
    }

    func save(_ snap: StoreSnapshot) {
        guard let data = try? JSONEncoder().encode(snap) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
