import Foundation
import Observation

// Single source of truth — owns the loaded data and the active filters.
// Held as a @State on the App and injected via .environment(_:).

@Observable
@MainActor
final class ActivityStore {
    enum LoadState {
        case idle
        case loading
        case ready
        case error(String)
    }

    var state: LoadState = .idle
    var manifest: Manifest?
    var venues: [Venue] = []
    var activities: [Activity] = []
    var filters: ActivityFilters = .default

    private let loader = DataLoader()

    var filteredActivities: [Activity] {
        FilterEngine.apply(activities: activities, venues: venues, filters: filters)
    }

    func load(forceRefresh: Bool = false) async {
        state = .loading
        let result = await loader.load(forceRefresh: forceRefresh)
        switch result {
        case .success(let data):
            self.manifest = data.manifest
            self.venues = data.venues
            self.activities = data.activities
            self.state = .ready
        case .failure(let err):
            self.state = .error(describe(err))
        }
    }

    func refresh() async { await load(forceRefresh: true) }

    private func describe(_ err: DataLoaderError) -> String {
        switch err {
        case .schemaMismatch(let found, let supported):
            return "Data schema v\(found) is newer than this app (v\(supported)). Update the app."
        case .decode(let e): return "Couldn't read data: \(e.localizedDescription)"
        case .network(let e): return "Couldn't reach the server: \(e.localizedDescription)"
        case .missingCache: return "No cached data available."
        }
    }
}
