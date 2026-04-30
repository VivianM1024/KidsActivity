import Foundation

struct Venue: Identifiable, Codable, Hashable {
    var id: String { slug }

    let slug: String
    let name: String
    let venueType: VenueType
    let platform: String
    let baseUrl: URL
    let centerLat: Double
    let centerLon: Double
    let servedZipcodes: [String]

    enum CodingKeys: String, CodingKey {
        case slug
        case name
        case venueType = "venue_type"
        case platform
        case baseUrl = "base_url"
        case centerLat = "center_lat"
        case centerLon = "center_lon"
        case servedZipcodes = "served_zipcodes"
    }
}
