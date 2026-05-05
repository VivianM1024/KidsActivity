import Foundation
import CoreLocation
import SQLite3

// Data layer.
//
// On launch the app fetches `manifest.json`, `venues.json`, and
// `activities.db.gz` from GitHub Pages. The .db.gz is decompressed locally
// into the caches directory and opened via `SQLiteActivityRepository` —
// every subsequent Browse / Saved / Calendar lookup is a SQL query, so
// the full activity set never sits in memory.
//
// The whole data stack lives in this one file because the project's
// Xcode `.xcodeproj` is generated from `project.yml` via XcodeGen, and
// the contributor toolchain doesn't always have xcodegen on hand. Adding
// a new top-level Swift file therefore requires fiddling with the
// `.pbxproj`, which is fragile. Until the toolchain is sorted, all data-
// layer code is grouped here and the file is kept already-listed in the
// project.

// MARK: - Public types

enum DataLoaderError: Error {
    case schemaMismatch(found: Int, supported: Int)
    case decode(Error)
    case decompress(Error)
    case sqlite(Error)
    case network(Error)
    case missingCache
}

struct LoadedData {
    let manifest: Manifest
    let venues: [Venue]
    let repository: SQLiteActivityRepository
    /// True when network fetch failed and we returned the on-disk cache.
    let fromCache: Bool
    /// Modification time of the cache files when `fromCache == true`. nil
    /// otherwise — fresh fetches don't carry a "cached at" date.
    let cacheDate: Date?
}

// MARK: - DataLoader

final class DataLoader {
    static let baseURL: URL = {
        // Dev override: when running in the simulator on the author's
        // machine, prefer the local `docs/data/` so a `kidsactivity publish`
        // run is reflected immediately without pushing to GitHub Pages.
        // Falls through to production for everyone else.
        #if targetEnvironment(simulator)
        let local = URL(fileURLWithPath: "/Users/vivian/Projects/KidsActivity/docs/data/")
        if FileManager.default.fileExists(atPath: local.appendingPathComponent("activities.db.gz").path) {
            return local
        }
        #endif
        return URL(string: "https://vivianm1024.github.io/KidsActivity/data/")!
    }()

    private let cacheDir: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("kidsactivity", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private var dbPath: URL { cacheDir.appendingPathComponent("activities.db") }
    private var dbGzPath: URL { cacheDir.appendingPathComponent("activities.db.gz") }

    func load(forceRefresh: Bool = false) async -> Result<LoadedData, DataLoaderError> {
        if forceRefresh {
            return await fetchFresh()
        }
        switch await fetchFresh() {
        case .success(let data):
            return .success(data)
        case .failure(let netErr):
            // Fall back to cached copy when offline. The returned value
            // carries `fromCache: true` so Browse can show the cached banner.
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
            async let dbGzData: Data = fetch("activities.db.gz")

            let (m, v, gz) = try await (manifestData, venuesData, dbGzData)
            let decoder = JSONDecoder.kidsActivity

            let manifest: Manifest
            let venues: [Venue]
            do {
                manifest = try decoder.decode(Manifest.self, from: m)
                guard manifest.schemaVersion == Manifest.supportedSchemaVersion else {
                    return .failure(.schemaMismatch(
                        found: manifest.schemaVersion,
                        supported: Manifest.supportedSchemaVersion
                    ))
                }
                venues = try decoder.decode([Venue].self, from: v)
            } catch {
                return .failure(.decode(error))
            }

            // Decompress + persist the .db, then open it.
            let dbData: Data
            do {
                dbData = try gz.gunzipped()
            } catch {
                return .failure(.decompress(error))
            }
            do {
                try dbData.write(to: dbPath, options: .atomic)
                try gz.write(to: dbGzPath, options: .atomic)
                try m.write(to: cacheDir.appendingPathComponent("manifest.json"), options: .atomic)
                try v.write(to: cacheDir.appendingPathComponent("venues.json"), options: .atomic)
            } catch {
                // Cache write failure is non-fatal — proceed with in-memory data.
                print("Cache write failed:", error)
            }

            let repository: SQLiteActivityRepository
            do {
                repository = try SQLiteActivityRepository(databasePath: dbPath)
            } catch {
                return .failure(.sqlite(error))
            }
            return .success(LoadedData(
                manifest: manifest, venues: venues, repository: repository,
                fromCache: false, cacheDate: nil
            ))
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

    private func loadCached() -> LoadedData? {
        let m = cacheDir.appendingPathComponent("manifest.json")
        let v = cacheDir.appendingPathComponent("venues.json")
        guard
            let mData = try? Data(contentsOf: m),
            let vData = try? Data(contentsOf: v),
            FileManager.default.fileExists(atPath: dbPath.path)
        else { return nil }
        let decoder = JSONDecoder.kidsActivity
        guard
            let manifest = try? decoder.decode(Manifest.self, from: mData),
            let venues = try? decoder.decode([Venue].self, from: vData),
            let repository = try? SQLiteActivityRepository(databasePath: dbPath)
        else { return nil }
        let cacheDate = [m, v, dbPath]
            .compactMap { (try? FileManager.default.attributesOfItem(atPath: $0.path))?[.modificationDate] as? Date }
            .max()
        return LoadedData(
            manifest: manifest, venues: venues, repository: repository,
            fromCache: true, cacheDate: cacheDate
        )
    }
}

extension JSONDecoder {
    /// Shared decoder. ISO 8601 dates so the publisher and decoder stay in sync.
    static let kidsActivity: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

// MARK: - Gunzip

enum GunzipError: Error {
    case tooSmall
    case notGzip
    case truncatedHeader
    case decompressFailed
}

extension Data {
    /// Decompress a single-member gzip stream. Skips the RFC-1952 header
    /// then hands the raw DEFLATE body to NSData's `.zlib` decompressor.
    /// Carries its own header parser instead of using `Compression`'s
    /// streaming API because the .db.gz produced by the Python pipeline
    /// is always a single member with default flags — no need for full
    /// zlib state-machine handling.
    func gunzipped() throws -> Data {
        guard count >= 18 else { throw GunzipError.tooSmall }
        guard self[0] == 0x1f, self[1] == 0x8b else { throw GunzipError.notGzip }
        let flags = self[3]
        var p = 10
        if flags & 0x04 != 0 {  // FEXTRA
            guard p + 2 <= count else { throw GunzipError.truncatedHeader }
            let xlen = Int(self[p]) | (Int(self[p + 1]) << 8)
            p += 2 + xlen
        }
        if flags & 0x08 != 0 {  // FNAME, null-terminated
            while p < count, self[p] != 0 { p += 1 }
            p += 1
        }
        if flags & 0x10 != 0 {  // FCOMMENT, null-terminated
            while p < count, self[p] != 0 { p += 1 }
            p += 1
        }
        if flags & 0x02 != 0 {  // FHCRC
            p += 2
        }
        guard p < count - 8 else { throw GunzipError.truncatedHeader }
        let body = subdata(in: p ..< count - 8)
        do {
            return try (body as NSData).decompressed(using: .zlib) as Data
        } catch {
            throw GunzipError.decompressFailed
        }
    }
}

// MARK: - SQLiteActivityRepository

/// Query-on-demand backend for the iOS app. Every BrowseView refresh runs
/// `query(filters:kids:sort:home:)` against `activities.db`, decodes only
/// the matching payload JSONs into Activity structs, and hands them back.
final class SQLiteActivityRepository {
    private var db: OpaquePointer?

    enum RepositoryError: Error {
        case openFailed(String)
        case prepareFailed(String)
    }

    init(databasePath: URL) throws {
        var db: OpaquePointer?
        // FULLMUTEX so the handle can be opened on the loader's background
        // task and then used from the @MainActor store. Serialized mode adds
        // a tiny lock per call but the queries are all sub-ms anyway.
        let rc = sqlite3_open_v2(
            databasePath.path,
            &db,
            SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX,
            nil
        )
        guard rc == SQLITE_OK, let opened = db else {
            let msg = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "rc=\(rc)"
            sqlite3_close(db)
            throw RepositoryError.openFailed(msg)
        }
        self.db = opened
        sqlite3_exec(opened, "PRAGMA query_only=1; PRAGMA temp_store=MEMORY;", nil, nil, nil)
    }

    deinit { sqlite3_close(db) }

    // MARK: Public surface

    func totalCount() -> Int {
        scalarInt("SELECT COUNT(*) FROM activities") ?? 0
    }

    /// Per-venue-type tallies, used by the FilterSheet venue list.
    func countsByVenueType() -> [VenueType: Int] {
        var out: [VenueType: Int] = [:]
        run(sql: "SELECT venue_type, COUNT(*) FROM activities GROUP BY venue_type",
            bind: { _ in }) { stmt in
            guard let cstr = sqlite3_column_text(stmt, 0) else { return }
            let raw = String(cString: cstr)
            if let type = VenueType(rawValue: raw) {
                out[type] = Int(sqlite3_column_int64(stmt, 1))
            }
        }
        return out
    }

    /// Look up a single activity by id. Used by calendar / saved / registration
    /// flows that work in terms of stored activity_ids.
    func activity(id: String) -> Activity? {
        activities(ids: [id]).first
    }

    /// Bulk lookup. SQLite parameter cap is ~999 so we chunk.
    func activities(ids: [String]) -> [Activity] {
        guard !ids.isEmpty else { return [] }
        var out: [Activity] = []
        out.reserveCapacity(ids.count)
        for chunk in ids.chunked(into: 500) {
            let placeholders = Array(repeating: "?", count: chunk.count).joined(separator: ",")
            let sql = "SELECT payload FROM activities WHERE activity_id IN (\(placeholders))"
            run(sql: sql, bind: { stmt in
                for (i, id) in chunk.enumerated() {
                    bindString(stmt, index: Int32(i + 1), value: id)
                }
            }) { stmt in
                if let a = decodePayload(stmt: stmt, column: 0) { out.append(a) }
            }
        }
        return out
    }

    /// Main filtered + sorted query for BrowseView. Replaces the old
    /// in-memory `FilterEngine.apply()` + `FilterEngine.sort()` pipeline.
    func query(
        filters: ActivityFilters,
        kids: [Kid],
        sort: SortMode,
        searchText: String,
        home: CLLocationCoordinate2D?
    ) -> [Activity] {
        var clauses: [String] = []
        var binds: [(OpaquePointer?) -> Void] = []
        var idx: Int32 = 0
        func nextIdx() -> Int32 { idx += 1; return idx }

        if filters.venueTypes != Set(VenueType.allCases) {
            let placeholders = Array(repeating: "?", count: filters.venueTypes.count).joined(separator: ",")
            clauses.append("venue_type IN (\(placeholders))")
            for vt in filters.venueTypes {
                let i = nextIdx()
                binds.append { stmt in bindString(stmt, index: i, value: vt.rawValue) }
            }
        }

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
        if let (lo, hi) = ageWindow {
            // Activity overlaps [lo, hi] iff age_min <= hi AND age_max >= lo.
            // NULL columns are treated as wide-open on that side.
            clauses.append("(age_min_months IS NULL OR age_min_months <= ?)")
            let i1 = nextIdx()
            binds.append { stmt in bindInt(stmt, index: i1, value: hi) }
            clauses.append("(age_max_months IS NULL OR age_max_months >= ?)")
            let i2 = nextIdx()
            binds.append { stmt in bindInt(stmt, index: i2, value: lo) }
        }

        if let qStart = filters.startDate {
            clauses.append("(end_date IS NULL OR end_date >= ?)")
            let i = nextIdx()
            binds.append { stmt in bindString(stmt, index: i, value: isoDate(qStart)) }
        }
        if let qEnd = filters.endDate {
            clauses.append("(start_date IS NULL OR start_date <= ?)")
            let i = nextIdx()
            binds.append { stmt in bindString(stmt, index: i, value: isoDate(qEnd)) }
        }

        if !searchText.isEmpty {
            // FTS5 with prefix tokens — split on whitespace.
            let tokens = searchText
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .map { "\($0)*" }
            if !tokens.isEmpty {
                let match = tokens.joined(separator: " ")
                clauses.append("activity_id IN (SELECT activity_id FROM activities_fts WHERE activities_fts MATCH ?)")
                let i = nextIdx()
                binds.append { stmt in bindString(stmt, index: i, value: match) }
            }
        }

        // Distance — bounding box prefilter, exact-miles check happens in
        // Swift. 1 latitude degree ≈ 69 miles; longitude tightens at higher
        // latitudes so we use cos(lat).
        var exactDistanceCheck: ((CLLocationCoordinate2D) -> Double?)? = nil
        if let maxMi = filters.maxDistanceMiles, let h = home {
            let dLat = maxMi / 69.0
            let dLon = maxMi / (69.0 * max(0.1, cos(h.latitude * .pi / 180)))
            clauses.append("venue_lat BETWEEN ? AND ?")
            let i1 = nextIdx(), i2 = nextIdx()
            binds.append { stmt in bindDouble(stmt, index: i1, value: h.latitude - dLat) }
            binds.append { stmt in bindDouble(stmt, index: i2, value: h.latitude + dLat) }
            clauses.append("venue_lon BETWEEN ? AND ?")
            let i3 = nextIdx(), i4 = nextIdx()
            binds.append { stmt in bindDouble(stmt, index: i3, value: h.longitude - dLon) }
            binds.append { stmt in bindDouble(stmt, index: i4, value: h.longitude + dLon) }
            let homeLoc = CLLocation(latitude: h.latitude, longitude: h.longitude)
            exactDistanceCheck = { coord in
                let venueLoc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                return homeLoc.distance(from: venueLoc) / 1609.344
            }
        }

        switch filters.registrationFilter {
        case .open:
            clauses.append("reg_is_open = 1")
        case .openingSoon:
            clauses.append("(reg_is_open IS NULL OR reg_is_open = 0)")
            clauses.append("reg_opens_at IS NOT NULL AND reg_opens_at >= ?")
            let i = nextIdx()
            binds.append { stmt in
                let now = ISO8601DateFormatter().string(from: Date())
                bindString(stmt, index: i, value: now)
            }
        case .any: break
        }

        if let cap = filters.priceFilter.cap {
            if cap == 0 {
                clauses.append("(lowest_price = 0 OR lowest_price IS NULL)")
            } else {
                clauses.append("(lowest_price IS NULL OR lowest_price <= ?)")
                let i = nextIdx()
                binds.append { stmt in bindDouble(stmt, index: i, value: cap) }
            }
        }

        if !filters.daysOfWeek.isEmpty {
            let placeholders = Array(repeating: "?", count: filters.daysOfWeek.count).joined(separator: ",")
            clauses.append("activity_id IN (SELECT activity_id FROM activity_days WHERE day_of_week IN (\(placeholders)))")
            for d in filters.daysOfWeek {
                let i = nextIdx()
                binds.append { stmt in bindString(stmt, index: i, value: d.short) }
            }
        }

        if !filters.categories.isEmpty {
            let placeholders = Array(repeating: "?", count: filters.categories.count).joined(separator: ",")
            clauses.append("inferred_category IN (\(placeholders))")
            for c in filters.categories {
                let i = nextIdx()
                binds.append { stmt in bindString(stmt, index: i, value: c.rawValue) }
            }
        }

        switch filters.kindFilter {
        case .all: break
        case .oneTime: clauses.append("kind = 'oneTime'")
        case .series:  clauses.append("kind = 'series'")
        }

        let orderBy: String = {
            switch sort {
            case .when:  return "ORDER BY start_date IS NULL, start_date ASC"
            case .price: return "ORDER BY lowest_price IS NULL, lowest_price ASC"
            case .near:
                guard let h = home else { return "ORDER BY start_date ASC" }
                // Approximate squared-euclidean — fine for sort, exact miles
                // only matter for the maxDistance cutoff above.
                return """
                ORDER BY
                  (venue_lat - \(h.latitude)) * (venue_lat - \(h.latitude)) +
                  (venue_lon - \(h.longitude)) * (venue_lon - \(h.longitude))
                ASC
                """
            }
        }()

        let where_ = clauses.isEmpty ? "" : "WHERE " + clauses.joined(separator: " AND ")
        let sql = "SELECT payload, venue_lat, venue_lon FROM activities \(where_) \(orderBy)"

        var out: [Activity] = []
        run(sql: sql, bind: { stmt in
            for binder in binds { binder(stmt) }
        }) { stmt in
            if let exactCheck = exactDistanceCheck,
               let maxMi = filters.maxDistanceMiles {
                let lat = sqlite3_column_double(stmt, 1)
                let lon = sqlite3_column_double(stmt, 2)
                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                if let mi = exactCheck(coord), mi > maxMi { return }
            }
            if let a = decodePayload(stmt: stmt, column: 0) { out.append(a) }
        }
        return out
    }

    // MARK: Statement helpers

    private func scalarInt(_ sql: String) -> Int? {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        return Int(sqlite3_column_int64(stmt, 0))
    }

    private func run(
        sql: String,
        bind: (OpaquePointer?) -> Void,
        onRow: (OpaquePointer?) -> Void
    ) {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            if let db { print("SQL prepare failed:", String(cString: sqlite3_errmsg(db)), "sql=\n\(sql)") }
            return
        }
        bind(stmt)
        while sqlite3_step(stmt) == SQLITE_ROW {
            onRow(stmt)
        }
    }

    private func decodePayload(stmt: OpaquePointer?, column: Int32) -> Activity? {
        guard let cstr = sqlite3_column_text(stmt, column) else { return nil }
        let bytes = sqlite3_column_bytes(stmt, column)
        let data = Data(bytes: cstr, count: Int(bytes))
        do {
            return try JSONDecoder.kidsActivity.decode(Activity.self, from: data)
        } catch {
            print("Activity decode failed:", error)
            return nil
        }
    }
}

// MARK: - Bind helpers

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

private func bindString(_ stmt: OpaquePointer?, index: Int32, value: String) {
    sqlite3_bind_text(stmt, index, value, -1, SQLITE_TRANSIENT)
}

private func bindInt(_ stmt: OpaquePointer?, index: Int32, value: Int) {
    sqlite3_bind_int64(stmt, index, Int64(value))
}

private func bindDouble(_ stmt: OpaquePointer?, index: Int32, value: Double) {
    sqlite3_bind_double(stmt, index, value)
}

private func isoDate(_ date: Date) -> String {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .iso8601)
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone(identifier: "America/Chicago")
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: date)
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
