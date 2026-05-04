import Foundation
import CoreLocation

struct ActivityFilters {
    var venueTypes: Set<VenueType> = Set(VenueType.allCases)
    var ageMinMonths: Int? = nil
    var ageMaxMonths: Int? = nil
    var startDate: Date? = nil
    var endDate: Date? = nil
    var keyword: String = ""
    var maxDistanceMiles: Double? = nil
    var homeCoordinate: CLLocationCoordinate2D? = nil

    // V5 additions
    var ageMode: AgeMode = .kids
    var registrationFilter: RegistrationFilter = .any
    var priceFilter: PriceFilter = .any
    var daysOfWeek: Set<DayOfWeek> = []
    var categories: Set<ActivityCategory> = []
    var kindFilter: KindFilter = .all

    enum AgeMode: String, Codable { case kids, manual }

    enum RegistrationFilter: String, Codable, CaseIterable, Hashable {
        case open, openingSoon, any
        var label: String {
            switch self {
            case .open:         return "Open now"
            case .openingSoon:  return "Opening soon"
            case .any:          return "Any"
            }
        }
    }

    enum PriceFilter: String, Codable, CaseIterable, Hashable {
        case any, free, under25, under75, under200
        var label: String {
            switch self {
            case .any:      return "Any"
            case .free:     return "Free"
            case .under25:  return "Under $25"
            case .under75:  return "Under $75"
            case .under200: return "Under $200"
            }
        }
        var cap: Double? {
            switch self {
            case .any: return nil
            case .free: return 0
            case .under25: return 25
            case .under75: return 75
            case .under200: return 200
            }
        }
    }

    enum KindFilter: String, Codable, CaseIterable, Hashable {
        case all, oneTime, series
        var label: String {
            switch self {
            case .all:     return "All"
            case .oneTime: return "One-time"
            case .series:  return "Series"
            }
        }
    }

    enum DayOfWeek: String, Codable, CaseIterable, Hashable {
        case mon, tue, wed, thu, fri, sat, sun

        var short: String {
            switch self {
            case .mon: return "Mon"
            case .tue: return "Tue"
            case .wed: return "Wed"
            case .thu: return "Thu"
            case .fri: return "Fri"
            case .sat: return "Sat"
            case .sun: return "Sun"
            }
        }

        var letter: String { String(short.prefix(1)) }
    }

    static let `default` = ActivityFilters()

    var activeCount: Int {
        var n = 0
        if venueTypes != Set(VenueType.allCases) { n += 1 }
        if ageMinMonths != nil || ageMaxMonths != nil { n += 1 }
        if startDate != nil || endDate != nil { n += 1 }
        if !keyword.isEmpty { n += 1 }
        if maxDistanceMiles != nil { n += 1 }
        if registrationFilter != .any { n += 1 }
        if priceFilter != .any { n += 1 }
        if !daysOfWeek.isEmpty { n += 1 }
        if !categories.isEmpty { n += 1 }
        if kindFilter != .all { n += 1 }
        return n
    }
}

enum FilterEngine {
    static func apply(
        activities: [Activity],
        venues: [Venue],
        filters: ActivityFilters,
        kids: [Kid] = [],
        today: Date = Date()
    ) -> [Activity] {
        let venueBySlug = Dictionary(uniqueKeysWithValues: venues.map { ($0.slug, $0) })
        let homeLocation = filters.homeCoordinate.map {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude)
        }

        // Resolve age window from selected kids when in `kids` mode.
        let ageWindow: (Int, Int)? = {
            switch filters.ageMode {
            case .manual:
                if filters.ageMinMonths == nil && filters.ageMaxMonths == nil { return nil }
                return (filters.ageMinMonths ?? 0, filters.ageMaxMonths ?? 10_000)
            case .kids:
                guard !kids.isEmpty else { return nil }
                let lo = kids.map { max(0, $0.ageMonths - 12) }.min() ?? 0
                let hi = kids.map { $0.ageMonths + 12 }.max() ?? 10_000
                return (lo, hi)
            }
        }()

        return activities.filter { a in
            if !filters.venueTypes.contains(a.venueType) { return false }

            if let (lo, hi) = ageWindow,
               !a.ageRange.overlaps(min: lo, max: hi) {
                return false
            }

            // Date range
            if let qStart = filters.startDate {
                let aEnd = a.schedule.endDate ?? a.schedule.startDate ?? Date.distantFuture
                if aEnd < qStart { return false }
            }
            if let qEnd = filters.endDate {
                let aStart = a.schedule.startDate ?? a.schedule.endDate ?? Date.distantPast
                if aStart > qEnd { return false }
            }

            // Keyword
            if !filters.keyword.isEmpty {
                let needle = filters.keyword.lowercased()
                let haystack = [a.name, a.category ?? "", a.rawCategory ?? "", a.description ?? "",
                                a.venueName, a.location]
                    .joined(separator: " ").lowercased()
                if !haystack.contains(needle) { return false }
            }

            // Distance
            if let limit = filters.maxDistanceMiles, let home = homeLocation,
               let venue = venueBySlug[a.venueSlug] {
                let venueLoc = CLLocation(latitude: venue.centerLat, longitude: venue.centerLon)
                let miles = home.distance(from: venueLoc) / 1609.344
                if miles > limit { return false }
            }

            // Registration
            switch filters.registrationFilter {
            case .open:
                if a.registration.isOpen != true { return false }
            case .openingSoon:
                guard let opens = a.registration.opensAt, opens >= today,
                      a.registration.isOpen != true else { return false }
            case .any: break
            }

            // Price
            if let cap = filters.priceFilter.cap {
                let p = a.lowestPrice ?? .infinity
                if cap == 0 {
                    if p != 0 { return false }
                } else if p > cap { return false }
            }

            // Days of week
            if !filters.daysOfWeek.isEmpty {
                let activityDays = Set(a.schedule.weeklyTimes.map { $0.dayOfWeek })
                let wanted = Set(filters.daysOfWeek.map(\.short))
                if activityDays.isDisjoint(with: wanted) { return false }
            }

            // Categories
            if !filters.categories.isEmpty {
                if !filters.categories.contains(a.inferredCategory) { return false }
            }

            // Kind
            switch filters.kindFilter {
            case .all: break
            case .oneTime: if a.kind != .oneTime { return false }
            case .series:  if a.kind != .series  { return false }
            }

            return true
        }
    }

    /// Sort activities for the Browse list.
    static func sort(
        _ activities: [Activity],
        by mode: SortMode,
        venues: [Venue] = [],
        home: CLLocationCoordinate2D? = nil
    ) -> [Activity] {
        switch mode {
        case .when:
            return activities.sorted { lhs, rhs in
                let l = lhs.schedule.startDate ?? .distantFuture
                let r = rhs.schedule.startDate ?? .distantFuture
                return l < r
            }
        case .price:
            return activities.sorted { lhs, rhs in
                let l = lhs.lowestPrice ?? .infinity
                let r = rhs.lowestPrice ?? .infinity
                return l < r
            }
        case .near:
            // TODO: real distance once user location lands.
            let bySlug = Dictionary(uniqueKeysWithValues: venues.map { ($0.slug, $0) })
            return activities.sorted { lhs, rhs in
                let l = Formatters.distanceMiles(home: home, venue: bySlug[lhs.venueSlug]) ?? .infinity
                let r = Formatters.distanceMiles(home: home, venue: bySlug[rhs.venueSlug]) ?? .infinity
                return l < r
            }
        }
    }
}
