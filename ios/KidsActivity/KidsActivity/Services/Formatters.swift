import Foundation
import CoreLocation

enum Formatters {
    static let dayOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let dateRange: DateIntervalFormatter = {
        let f = DateIntervalFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let monthDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    static let weekdayLong: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()

    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    static let timeOfDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    static func scheduleSummary(_ s: Schedule) -> String {
        if let raw = s.rawScheduleText, !raw.isEmpty { return raw }
        if let start = s.startDate, let end = s.endDate {
            return dateRange.string(from: start, to: end)
        }
        if let start = s.startDate { return dayOnly.string(from: start) }
        return "—"
    }

    static func weeklyTimes(_ times: [WeeklyTime]) -> String {
        guard !times.isEmpty else { return "" }
        return times.map { "\($0.dayOfWeek) \($0.start.prefix(5))–\($0.end.prefix(5))" }
                    .joined(separator: ", ")
    }

    // MARK: - V5 row helpers

    /// Compact age window — "3y" or "3–6y" — matching `ageRangeLabel` in the
    /// prototype. Falls back to the raw scrape text when month bounds are nil.
    static func ageRange(_ a: AgeRange) -> String {
        if let lo = a.minMonths, let hi = a.maxMonths {
            let yLo = lo / 12, yHi = hi / 12
            return yLo == yHi ? "\(yLo)y" : "\(yLo)–\(yHi)y"
        }
        if let lo = a.minMonths { return "\(lo / 12)y+" }
        if let hi = a.maxMonths { return "≤\(hi / 12)y" }
        if let raw = a.rawAgeText, !raw.isEmpty { return raw }
        return "—"
    }

    /// "Mon", "Sat · Sun", "M–F", "—".
    static func days(_ days: [String]) -> String {
        guard !days.isEmpty else { return "—" }
        if days.count == 5 && days.first == "Mon" && days.last == "Fri" { return "M–F" }
        if days.count == 1 { return days[0] }
        return days.joined(separator: " · ")
    }

    /// First weekly time as "9:30 AM" — the prototype shows a single time per row.
    static func firstTime(_ times: [WeeklyTime]) -> String {
        guard let t = times.first else { return "" }
        // start is "HH:mm:ss" from backend.
        let hms = t.start
        let parts = hms.split(separator: ":")
        guard parts.count >= 2,
              let h = Int(parts[0]), let m = Int(parts[1]) else { return hms }
        let am = h < 12
        let displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        return String(format: "%d:%02d %@", displayH, m, am ? "AM" : "PM")
    }

    /// "Free", "$60", "$60 / $75" when resident/non-resident differ.
    static func price(_ p: Price) -> String {
        if let r = p.residentPrice {
            if r == 0 { return "Free" }
            if let n = p.nonResidentPrice, n != r { return "$\(Int(r)) / $\(Int(n))" }
            return "$\(Int(r))"
        }
        if let n = p.nonResidentPrice {
            if n == 0 { return "Free" }
            return "$\(Int(n))"
        }
        return p.rawPriceText ?? "—"
    }

    /// Formatted start date "May 9". Empty when unknown.
    static func startDate(_ d: Date?) -> String {
        guard let d else { return "" }
        return monthDay.string(from: d)
    }

    /// Distance in miles from `home` to a venue, or nil when home is unknown
    /// or the venue lacks coordinates.
    static func distanceMiles(home: CLLocationCoordinate2D?, venue: Venue?) -> Double? {
        guard let home, let venue else { return nil }
        let homeLoc = CLLocation(latitude: home.latitude, longitude: home.longitude)
        let venueLoc = CLLocation(latitude: venue.centerLat, longitude: venue.centerLon)
        return homeLoc.distance(from: venueLoc) / 1609.344
    }

    static func miles(_ m: Double?) -> String? {
        guard let m else { return nil }
        return String(format: "%.1f mi", m)
    }
}

/// Status pill text + color bucket. Mirrors the prototype's `statusLabel`
/// logic across `registration`, `opens_at`, and the activity's first session.
enum ActivityStatus: Hashable {
    case open           // registration open / drop-in
    case dropIn         // free + open + no scheduled session start
    case opensSoon(Date)
    case full
    case closed

    var label: String {
        switch self {
        case .open:          return "OPEN"
        case .dropIn:        return "DROP-IN"
        case .opensSoon(let d):
            return "OPENS \(Formatters.monthDay.string(from: d).uppercased())"
        case .full:          return "FULL"
        case .closed:        return "CLOSED"
        }
    }

    static func compute(for activity: Activity, today: Date = Date()) -> ActivityStatus {
        let r = activity.registration
        if r.isOpen == true {
            // Drop-in heuristic: free + single-session.
            let isFree = (activity.price.residentPrice ?? activity.price.nonResidentPrice) == 0
            if isFree && (activity.schedule.numSessions ?? 1) <= 1 {
                return .dropIn
            }
            return .open
        }
        if let opens = r.opensAt, opens >= today {
            return .opensSoon(opens)
        }
        if let raw = r.rawText?.lowercased(), raw.contains("full") || raw.contains("waitlist") {
            return .full
        }
        return .closed
    }
}
