import Foundation
import CoreLocation

// One-shot location + ZIP helpers used by onboarding (and later, the home
// pin in the Browse/Filter sheet). We don't keep the manager running — just
// request a single fix, deliver it, and let CLLocationManager idle out.

@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {
    enum LocationError: Error {
        case denied
        case unavailable
        case timeout
        case underlying(Error)
    }

    struct Fix {
        let coordinate: CLLocationCoordinate2D
        let zip: String?
        let neighborhood: String?
    }

    private let manager = CLLocationManager()
    private var pending: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Geocode a US ZIP code (or any postal address) to a coordinate.
    func geocode(zip: String) async throws -> CLLocationCoordinate2D {
        let trimmed = zip.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw LocationError.unavailable }
        let placemarks = try await CLGeocoder().geocodeAddressString(trimmed + ", USA")
        guard let coord = placemarks.first?.location?.coordinate else {
            throw LocationError.unavailable
        }
        return coord
    }

    /// Ask for permission, get a single fix, then reverse-geocode it into
    /// (zip, neighborhood) so the onboarding form can prefill its fields.
    func currentLocationFix() async throws -> Fix {
        let status = manager.authorizationStatus
        if status == .denied || status == .restricted {
            throw LocationError.denied
        }
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
            // Give the prompt a moment to resolve.
            try await Task.sleep(nanoseconds: 300_000_000)
        }

        let location: CLLocation = try await withCheckedThrowingContinuation { cont in
            self.pending = cont
            self.manager.requestLocation()
        }

        let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location)
        let pm = placemarks?.first
        return Fix(
            coordinate: location.coordinate,
            zip: pm?.postalCode,
            neighborhood: pm?.subLocality ?? pm?.locality
        )
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.pending?.resume(returning: loc)
            self.pending = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.pending?.resume(throwing: LocationError.underlying(error))
            self.pending = nil
        }
    }
}
