import Foundation
import CoreLocation
import MapKit

/// MapKit-backed travel-time lookup. Asynchronous, with a session-level
/// cache so repeated lookups (e.g. resolving the same pair of conflicting
/// venues) don't refire `MKDirections`. Used by the Calendar conflict
/// banner + ResolveConflictSheet.
@MainActor
final class TravelTimeService {
    static let shared = TravelTimeService()

    /// Cache key: rounded lat/lon to ~10m so jittery coordinates dedupe.
    private var cache: [String: Int] = [:]

    private func key(_ from: CLLocationCoordinate2D, _ to: CLLocationCoordinate2D) -> String {
        let f = String(format: "%.4f,%.4f", from.latitude, from.longitude)
        let t = String(format: "%.4f,%.4f", to.latitude, to.longitude)
        return "\(f)→\(t)"
    }

    /// Returns minutes (rounded) of expected driving time, or `nil` on failure.
    /// Apple's directions API can be flaky over flaky networks; treat `nil` as
    /// "we couldn't compute it" rather than "no travel needed".
    func driveMinutes(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) async -> Int? {
        let k = key(from, to)
        if let cached = cache[k] { return cached }

        let req = MKDirections.Request()
        req.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        req.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        req.transportType = .automobile

        do {
            let resp = try await MKDirections(request: req).calculate()
            guard let route = resp.routes.first else { return nil }
            let minutes = Int((route.expectedTravelTime / 60.0).rounded())
            cache[k] = minutes
            return minutes
        } catch {
            return nil
        }
    }
}
