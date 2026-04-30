import Foundation

struct Manifest: Codable, Hashable {
    let schemaVersion: Int
    let lastUpdated: Date
    let venueCount: Int
    let activityCount: Int
    let venuesByType: [String: Int]
    let activitiesByType: [String: Int]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case lastUpdated = "last_updated"
        case venueCount = "venue_count"
        case activityCount = "activity_count"
        case venuesByType = "venues_by_type"
        case activitiesByType = "activities_by_type"
    }

    static let supportedSchemaVersion = 1
}
