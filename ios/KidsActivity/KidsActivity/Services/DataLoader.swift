import Foundation

// Fetches manifest.json + venues.json + activities.json from the GitHub
// Pages URL, with on-disk caching as offline fallback.

enum DataLoaderError: Error {
    case schemaMismatch(found: Int, supported: Int)
    case decode(Error)
    case network(Error)
    case missingCache
}

struct LoadedData {
    let manifest: Manifest
    let venues: [Venue]
    let activities: [Activity]
}

final class DataLoader {
    static let baseURL = URL(string: "https://vivianm1024.github.io/KidsActivity/data/")!

    private let cacheDir: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("kidsactivity", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    func load(forceRefresh: Bool = false) async -> Result<LoadedData, DataLoaderError> {
        if forceRefresh {
            return await fetchFresh()
        }
        switch await fetchFresh() {
        case .success(let data):
            return .success(data)
        case .failure(let netErr):
            // Fall back to cached copy when offline.
            if let cached = loadCached() {
                return .success(cached)
            }
            return .failure(netErr)
        }
    }

    private func fetchFresh() async -> Result<LoadedData, DataLoaderError> {
        do {
            async let manifestData: Data = fetch("manifest.json")
            async let venuesData: Data = fetch("venues.json")
            async let activitiesData: Data = fetch("activities.json")

            let (m, v, a) = try await (manifestData, venuesData, activitiesData)
            let decoder = JSONDecoder.kidsActivity

            do {
                let manifest = try decoder.decode(Manifest.self, from: m)
                guard manifest.schemaVersion == Manifest.supportedSchemaVersion else {
                    return .failure(.schemaMismatch(
                        found: manifest.schemaVersion,
                        supported: Manifest.supportedSchemaVersion
                    ))
                }
                let venues = try decoder.decode([Venue].self, from: v)
                // TEMP: slice to first 500 records BEFORE decode while we
                // figure out why the full 12k set leaks memory in the iOS
                // Simulator (Mac-native decode of the same data: 0.36s, 200MB).
                let aLimited = sliceJSONArray(a, prefix: 500) ?? a
                let activities = try decoder.decode([Activity].self, from: aLimited)
                writeCache(manifest: m, venues: v, activities: a)
                return .success(LoadedData(manifest: manifest, venues: venues, activities: activities))
            } catch {
                return .failure(.decode(error))
            }
        } catch {
            return .failure(.network(error))
        }
    }

    /// Use JSONSerialization to take the first `prefix` entries of a JSON
    /// array Data and re-serialize, so we can decode a smaller slice without
    /// pulling the whole thing through Codable.
    private func sliceJSONArray(_ data: Data, prefix: Int) -> Data? {
        guard let arr = try? JSONSerialization.jsonObject(with: data) as? [Any] else { return nil }
        let slice = Array(arr.prefix(prefix))
        return try? JSONSerialization.data(withJSONObject: slice)
    }

    private func fetch(_ filename: String) async throws -> Data {
        let url = Self.baseURL.appendingPathComponent(filename)
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }

    // MARK: - On-disk cache

    private func writeCache(manifest: Data, venues: Data, activities: Data) {
        try? manifest.write(to: cacheDir.appendingPathComponent("manifest.json"))
        try? venues.write(to: cacheDir.appendingPathComponent("venues.json"))
        try? activities.write(to: cacheDir.appendingPathComponent("activities.json"))
    }

    private func loadCached() -> LoadedData? {
        let m = cacheDir.appendingPathComponent("manifest.json")
        let v = cacheDir.appendingPathComponent("venues.json")
        let a = cacheDir.appendingPathComponent("activities.json")
        guard
            let mData = try? Data(contentsOf: m),
            let vData = try? Data(contentsOf: v),
            let aData = try? Data(contentsOf: a)
        else { return nil }
        let decoder = JSONDecoder.kidsActivity
        guard
            let manifest = try? decoder.decode(Manifest.self, from: mData),
            let venues = try? decoder.decode([Venue].self, from: vData),
            let activities = try? decoder.decode([Activity].self, from: aData)
        else { return nil }
        return LoadedData(manifest: manifest, venues: venues, activities: activities)
    }
}

extension JSONDecoder {
    // Date fields are kept as raw strings on the model and parsed lazily in
    // computed properties — letting JSONDecoder skip the per-date Decoder
    // construction that .custom triggers (a known perf cliff at 10k+ items).
    static var kidsActivity: JSONDecoder { JSONDecoder() }
}
