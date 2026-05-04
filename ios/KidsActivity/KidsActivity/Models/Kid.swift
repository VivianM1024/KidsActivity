import Foundation

struct Kid: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var ageMonths: Int
    var hue: Double  // OKLCH hue, 0–360

    var ageYears: Int { ageMonths / 12 }
    var initial: String { String(name.prefix(1)).uppercased() }

    static let sampleMaya = Kid(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        name: "Maya", ageMonths: 49, hue: 22)
    static let sampleLeo  = Kid(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        name: "Leo",  ageMonths: 86, hue: 250)
    static let sampleNora = Kid(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        name: "Nora", ageMonths: 28, hue: 320)

    static let samples: [Kid] = [.sampleMaya, .sampleLeo, .sampleNora]

    /// OKLCH hues we cycle through when auto-assigning a color to a new kid
    /// during onboarding. Order matches the README's category palette so the
    /// first three kids land on the same hues as the prototype's Maya/Leo/Nora.
    static let availableHues: [Double] = [22, 250, 320, 145, 200, 60, 290, 130]

    /// Pick the next unused hue from `availableHues`. Cycles if all are taken.
    static func nextHue(after existing: [Kid]) -> Double {
        let used = Set(existing.map(\.hue))
        return availableHues.first { !used.contains($0) } ?? availableHues[existing.count % availableHues.count]
    }
}

struct CalendarEvent: Identifiable, Codable, Hashable {
    let id: UUID
    let activityId: String
    let kidId: UUID
    let date: Date
    let durationMinutes: Int
    var note: String?

    init(id: UUID = UUID(), activityId: String, kidId: UUID, date: Date,
         durationMinutes: Int, note: String? = nil) {
        self.id = id
        self.activityId = activityId
        self.kidId = kidId
        self.date = date
        self.durationMinutes = durationMinutes
        self.note = note
    }
}

enum SortMode: String, Codable, CaseIterable, Hashable {
    case when, near, price

    var label: String {
        switch self {
        case .when:  return "When"
        case .near:  return "Near"
        case .price: return "Price"
        }
    }
}

enum ActivityCategory: String, CaseIterable, Codable, Hashable {
    case sports, arts, stem, events, storytime, music, outdoors

    var label: String {
        switch self {
        case .sports:    return "Sports"
        case .arts:      return "Arts"
        case .stem:      return "STEM"
        case .events:    return "Events"
        case .storytime: return "Storytime"
        case .music:     return "Music"
        case .outdoors:  return "Outdoors"
        }
    }

    var short: String {
        switch self {
        case .sports:    return "SPO"
        case .arts:      return "ART"
        case .stem:      return "STE"
        case .events:    return "EVT"
        case .storytime: return "STO"
        case .music:     return "MUS"
        case .outdoors:  return "OUT"
        }
    }

    /// OKLCH hue used for swatches, chips, dots.
    var hue: Double {
        switch self {
        case .sports:    return 22
        case .arts:      return 290
        case .stem:      return 200
        case .events:    return 145
        case .storytime: return 60
        case .music:     return 320
        case .outdoors:  return 130
        }
    }

    /// Best-effort classifier: backend `category` is often nil for ActiveNet
    /// scrapes, so fall back to keyword heuristics on the activity name.
    static func infer(from a: Activity) -> ActivityCategory {
        let raw = ((a.category ?? "") + " " + (a.rawCategory ?? "")).lowercased()
        let name = a.name.lowercased()

        func anyOf(_ haystacks: [String], _ needles: [String]) -> Bool {
            haystacks.contains { h in needles.contains { h.contains($0) } }
        }

        // Order matters: more-specific keywords (music, outdoors) win over the
        // older catch-all .arts / .events buckets.
        if anyOf([raw], ["music", "band", "choir", "orchestra"])           { return .music }
        if anyOf([raw], ["outdoor", "hike", "nature", "garden", "trail"])  { return .outdoors }
        if anyOf([raw], ["sport", "aquat", "swim", "camp"])                { return .sports }
        if anyOf([raw], ["story", "read"])                                 { return .storytime }
        if anyOf([raw], ["stem", "science", "tech", "robot", "engineer"])  { return .stem }
        if anyOf([raw], ["art", "paint", "draw", "dance", "theater", "theatre"]) { return .arts }
        if anyOf([raw], ["event", "festival", "family"])                   { return .events }

        if anyOf([name], ["music", "band", "choir", "orchestra", "guitar", "piano", "drum"]) { return .music }
        if anyOf([name], ["outdoor", "hike", "nature", "garden", "trail", "forest"])         { return .outdoors }
        if anyOf([name], ["soccer", "football", "ball", "hockey", "swim",
                          "tennis", "yoga", "fitness", "karate", "gym"]) { return .sports }
        if anyOf([name], ["lego", "robot", "code", "stem", "rocket", "science"]) { return .stem }
        if anyOf([name], ["story", "read", "book"])                              { return .storytime }
        if anyOf([name], ["art", "paint", "draw", "dance", "ballet",
                          "theater", "theatre"])                                  { return .arts }

        if let n = a.schedule.numSessions, n <= 1 { return .events }
        return .events
    }
}

enum ActivityKind: String, Codable, Hashable {
    case oneTime, series

    var badgeText: String {
        switch self {
        case .oneTime: return "ONE-TIME"
        case .series:  return "SERIES"
        }
    }
}

extension Activity {
    var inferredCategory: ActivityCategory { ActivityCategory.infer(from: self) }
    var kind: ActivityKind {
        if let n = schedule.numSessions, n > 1 { return .series }
        return .oneTime
    }

    /// Days of week as short strings ("Mon", "Tue", ...). Empty if unknown.
    var dayLetters: [String] { schedule.weeklyTimes.map(\.dayOfWeek) }

    /// Lowest displayable price ($N or "Free"); falls back to raw text.
    var lowestPrice: Double? {
        if let r = price.residentPrice { return r }
        if let n = price.nonResidentPrice { return n }
        return nil
    }
}
