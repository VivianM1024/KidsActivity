import Foundation

/// A person taking responsibility for activities/sessions. "You" is the device
/// owner; "partner" is the linked co-parent established via a shared invite
/// code. Single-parent users have only `selfParent` and never see the partner
/// surfaces.
struct Parent: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var hue: Double  // OKLCH hue, 0–360
    var role: Role

    enum Role: String, Codable, Hashable {
        case you, partner
    }

    var initial: String { String(name.prefix(1)).uppercased() }
    /// Short tag for chips. "You" stays "You"; partner shows their first name.
    var short: String { role == .you ? "You" : name }

    /// Default "You" identity — terracotta hue 22, matches the brand accent.
    static let defaultYou = Parent(
        id: UUID(uuidString: "AA000000-0000-0000-0000-000000000001")!,
        name: "You", hue: 22, role: .you
    )
    /// Default partner — partner-blue hue 250 (kept distinct from terracotta).
    static let defaultPartner = Parent(
        id: UUID(uuidString: "AA000000-0000-0000-0000-000000000002")!,
        name: "Sam", hue: 250, role: .partner
    )
}

/// How a given activity (or single session) is split between parents.
enum AssignmentKind: Codable, Hashable {
    case both                                    // both parents going together
    case solo(parentId: UUID)                    // one parent takes all kids
    case split(byKid: [UUID: UUID])              // kidId → parentId per kid

    private enum CodingKeys: String, CodingKey { case type, parentId, byKid }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "both":
            self = .both
        case "solo":
            self = .solo(parentId: try c.decode(UUID.self, forKey: .parentId))
        case "split":
            self = .split(byKid: try c.decode([UUID: UUID].self, forKey: .byKid))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: c,
                debugDescription: "Unknown AssignmentKind \(type)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .both:
            try c.encode("both", forKey: .type)
        case .solo(let pid):
            try c.encode("solo", forKey: .type)
            try c.encode(pid, forKey: .parentId)
        case .split(let m):
            try c.encode("split", forKey: .type)
            try c.encode(m, forKey: .byKid)
        }
    }

    var label: String {
        switch self {
        case .both: return "Both"
        case .solo: return "Solo"
        case .split: return "Split"
        }
    }
}

/// Assignment of a parent (or split) to an activity. A nil `sessionDate`
/// means the assignment applies to every session of the activity; a non-nil
/// date is a session-specific override that supersedes the default.
struct Assignment: Codable, Hashable {
    var activityId: String
    var sessionDate: Date?
    var kind: AssignmentKind
}

/// The linked partner state. Exists once the user has either generated and
/// shared a code or accepted one. Local-only — no server until the user opts
/// in. The invite code is the only tangible artifact.
struct LinkedParent: Codable, Hashable {
    var partner: Parent
    var inviteCode: String     // e.g. "maple-otter-39"
    var linkedAt: Date
}

enum InviteCode {
    /// Word list intentionally short and kid-friendly so a code is easy to
    /// read aloud over the phone. Production would broaden this.
    private static let words: [String] = [
        "maple", "otter", "willow", "peach", "ridge", "comet", "harbor",
        "linden", "pine", "oak", "wren", "fox", "cardinal", "swallow",
        "robin", "amber", "river", "cedar", "juno", "moss"
    ]

    /// Generates a fresh code in the form `<word>-<word>-NN`.
    static func generate() -> String {
        let w1 = words.randomElement() ?? "maple"
        var w2 = words.randomElement() ?? "otter"
        if w2 == w1 { w2 = words.last ?? "moss" }
        let n = Int.random(in: 10...99)
        return "\(w1)-\(w2)-\(n)"
    }

    /// Validates the shape of a typed code: two words + a 2-digit suffix.
    static func isValid(_ code: String) -> Bool {
        let parts = code.lowercased().split(separator: "-")
        guard parts.count == 3 else { return false }
        let alphaOK = parts.prefix(2).allSatisfy { $0.allSatisfy(\.isLetter) }
        let suffixOK = parts.last.flatMap { Int($0) }.map { (10...99).contains($0) } ?? false
        return alphaOK && suffixOK
    }
}
