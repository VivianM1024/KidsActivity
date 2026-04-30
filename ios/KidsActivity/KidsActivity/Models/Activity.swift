import Foundation

// Mirrors backend/kidsactivity/models.py::Activity. When the schema bumps
// (Manifest.schema_version), update both sides in lockstep.

struct Activity: Identifiable, Codable, Hashable {
    var id: String { activityId }

    let name: String
    let venueName: String
    let venueSlug: String
    let venueType: VenueType
    let schedule: Schedule
    let price: Price
    let ageRange: AgeRange
    let location: String
    let registration: Registration
    let sourceUrl: URL
    let activityId: String
    let category: String?
    let rawCategory: String?
    let description: String?
    let scrapedAt: Date

    enum CodingKeys: String, CodingKey {
        case name
        case venueName = "venue_name"
        case venueSlug = "venue_slug"
        case venueType = "venue_type"
        case schedule
        case price
        case ageRange = "age_range"
        case location
        case registration
        case sourceUrl = "source_url"
        case activityId = "activity_id"
        case category
        case rawCategory = "raw_category"
        case description
        case scrapedAt = "scraped_at"
    }
}

enum VenueType: String, Codable, CaseIterable, Hashable {
    case parkDistrict = "park_district"
    case library = "library"
    case communityCenter = "community_center"
    case museum = "museum"

    var label: String {
        switch self {
        case .parkDistrict: return "Park District"
        case .library: return "Library"
        case .communityCenter: return "Community Center"
        case .museum: return "Museum"
        }
    }

    var symbol: String {
        switch self {
        case .parkDistrict: return "tree.fill"
        case .library: return "books.vertical.fill"
        case .communityCenter: return "person.3.fill"
        case .museum: return "building.columns.fill"
        }
    }
}

struct Schedule: Codable, Hashable {
    let startDate: Date?
    let endDate: Date?
    let weeklyTimes: [WeeklyTime]
    let rawScheduleText: String?
    let numSessions: Int?

    enum CodingKeys: String, CodingKey {
        case startDate = "start_date"
        case endDate = "end_date"
        case weeklyTimes = "weekly_times"
        case rawScheduleText = "raw_schedule_text"
        case numSessions = "num_sessions"
    }
}

struct WeeklyTime: Codable, Hashable {
    let dayOfWeek: String  // "Mon" / "Tue" / ...
    let start: String      // "HH:MM:SS"
    let end: String

    enum CodingKeys: String, CodingKey {
        case dayOfWeek = "day_of_week"
        case start
        case end
    }
}

struct Price: Codable, Hashable {
    let residentPrice: Double?
    let nonResidentPrice: Double?
    let currency: String
    let rawPriceText: String?

    enum CodingKeys: String, CodingKey {
        case residentPrice = "resident_price"
        case nonResidentPrice = "non_resident_price"
        case currency
        case rawPriceText = "raw_price_text"
    }

    var displayPrice: String {
        if let r = residentPrice, let n = nonResidentPrice, r != n {
            return "$\(Int(r)) / $\(Int(n))"
        }
        if let r = residentPrice { return "$\(Int(r))" }
        if let n = nonResidentPrice { return "$\(Int(n))" }
        return rawPriceText ?? "—"
    }
}

struct AgeRange: Codable, Hashable {
    let minMonths: Int?
    let maxMonths: Int?
    let rawAgeText: String?

    enum CodingKeys: String, CodingKey {
        case minMonths = "min_months"
        case maxMonths = "max_months"
        case rawAgeText = "raw_age_text"
    }

    func overlaps(min queryMin: Int?, max queryMax: Int?) -> Bool {
        if minMonths == nil && maxMonths == nil { return true }
        let lo = minMonths ?? 0
        let hi = maxMonths ?? 10_000
        let qlo = queryMin ?? 0
        let qhi = queryMax ?? 10_000
        return lo <= qhi && hi >= qlo
    }

    var displayAge: String {
        if let raw = rawAgeText, !raw.isEmpty { return raw }
        if let lo = minMonths, let hi = maxMonths { return formatRange(lo, hi) }
        if let lo = minMonths { return "\(formatMonths(lo))+" }
        if let hi = maxMonths { return "up to \(formatMonths(hi))" }
        return "—"
    }

    private func formatRange(_ lo: Int, _ hi: Int) -> String {
        "\(formatMonths(lo))–\(formatMonths(hi))"
    }

    private func formatMonths(_ m: Int) -> String {
        if m < 24 { return "\(m)mo" }
        let yrs = Double(m) / 12.0
        return yrs.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(yrs))yr"
            : String(format: "%.1fyr", yrs)
    }
}

struct Registration: Codable, Hashable {
    let isOpen: Bool?
    let opensAt: Date?
    let closesAt: Date?
    let residentOpensAt: Date?
    let nonResidentOpensAt: Date?
    let rawText: String?

    enum CodingKeys: String, CodingKey {
        case isOpen = "is_open"
        case opensAt = "opens_at"
        case closesAt = "closes_at"
        case residentOpensAt = "resident_opens_at"
        case nonResidentOpensAt = "non_resident_opens_at"
        case rawText = "raw_text"
    }
}
