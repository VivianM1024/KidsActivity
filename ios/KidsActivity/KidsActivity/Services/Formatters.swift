import Foundation

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

    static func scheduleSummary(_ s: Schedule) -> String {
        if let raw = s.rawScheduleText, !raw.isEmpty { return raw }
        if let start = s.startDate, let end = s.endDate {
            return dateRange.string(from: start, to: end) ?? dayOnly.string(from: start)
        }
        if let start = s.startDate { return dayOnly.string(from: start) }
        return "—"
    }

    static func weeklyTimes(_ times: [WeeklyTime]) -> String {
        guard !times.isEmpty else { return "" }
        return times.map { "\($0.dayOfWeek) \($0.start.prefix(5))–\($0.end.prefix(5))" }
                    .joined(separator: ", ")
    }
}
