import Foundation
import CoreLocation

struct ActivityFilters: Equatable {
    var venueTypes: Set<VenueType> = Set(VenueType.allCases)
    var ageMinMonths: Int? = nil
    var ageMaxMonths: Int? = nil
    var startDate: Date? = nil
    var endDate: Date? = nil
    var registrationOpenOnly: Bool = false
    var keyword: String = ""
    var maxDistanceMiles: Double? = nil
    var homeCoordinate: CLLocationCoordinate2D? = nil

    static let `default` = ActivityFilters()
}

enum FilterEngine {
    static func apply(
        activities: [Activity],
        venues: [Venue],
        filters: ActivityFilters
    ) -> [Activity] {
        let venueBySlug = Dictionary(uniqueKeysWithValues: venues.map { ($0.slug, $0) })
        let homeLocation = filters.homeCoordinate.map {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude)
        }

        return activities.filter { a in
            if !filters.venueTypes.contains(a.venueType) { return false }
            if !a.ageRange.overlaps(min: filters.ageMinMonths, max: filters.ageMaxMonths) {
                return false
            }
            if filters.registrationOpenOnly, a.registration.isOpen != true { return false }

            // Date range overlap with the activity's [start, end] window.
            if let qStart = filters.startDate {
                let aEnd = a.schedule.endDate ?? a.schedule.startDate ?? Date.distantFuture
                if aEnd < qStart { return false }
            }
            if let qEnd = filters.endDate {
                let aStart = a.schedule.startDate ?? a.schedule.endDate ?? Date.distantPast
                if aStart > qEnd { return false }
            }

            // Keyword: case-insensitive contains in name/category/description.
            if !filters.keyword.isEmpty {
                let needle = filters.keyword.lowercased()
                let haystack = [a.name, a.category ?? "", a.rawCategory ?? "", a.description ?? ""]
                    .joined(separator: " ").lowercased()
                if !haystack.contains(needle) { return false }
            }

            // Distance from home.
            if let limit = filters.maxDistanceMiles, let home = homeLocation,
               let venue = venueBySlug[a.venueSlug] {
                let venueLoc = CLLocation(latitude: venue.centerLat, longitude: venue.centerLon)
                let miles = home.distance(from: venueLoc) / 1609.344
                if miles > limit { return false }
            }

            return true
        }
    }
}
