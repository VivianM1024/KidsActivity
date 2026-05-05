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

