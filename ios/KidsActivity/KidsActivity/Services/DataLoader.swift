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

@MainActor
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
                let activities = try decoder.decode([Activity].self, from: a)
                writeCache(manifest: m, venues: v, activities: a)
                return .success(LoadedData(manifest: manifest, venues: venues, activities: activities))
            } catch {
                return .failure(.decode(error))
            }
        } catch {
            return .failure(.network(error))
        }
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
    static var kidsActivity: JSONDecoder {
        let d = JSONDecoder()
        // Pydantic emits ISO-8601 for datetimes ("2026-04-30T09:00:00+00:00")
        // and bare YYYY-MM-DD for dates. Custom decoder handles both shapes.
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let dt = isoFormatter.date(from: raw) ?? isoFractional.date(from: raw) {
                return dt
            }
            if let day = ymdFormatter.date(from: raw) {
                return day
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unrecognized date: \(raw)"
            )
        }
        return d
    }
}

private let isoFormatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f
}()

private let isoFractional: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
}()

private let ymdFormatter: DateFormatter = {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .iso8601)
    f.timeZone = TimeZone(secondsFromGMT: 0)
    f.dateFormat = "yyyy-MM-dd"
    return f
}()
