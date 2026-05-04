import SwiftUI

/// Mini parent avatar shared by Detail "Who's going", Calendar parent chips,
/// the Resolve sheet, and the Linked Settings hero. Mirrors
/// `v5-coparent.jsx::ParentChip`.
///
/// - `kind: .both`   → two stacked avatars (you + partner overlap by 35%)
/// - `kind: .solo`   → one colored avatar
/// - `kind: .split`  → two avatars with a faint `/` between
/// - `kind: .unassigned` → dashed-circle "?"
struct ParentChip: View {
    enum Kind: Hashable {
        case both
        case solo(Parent)
        case split(you: Parent, partner: Parent)
        case unassigned
    }

    var kind: Kind
    var size: CGFloat = 22
    var withLabel: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            visual
            if withLabel {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.warmTextTertiary)
            }
        }
    }

    @ViewBuilder
    private var visual: some View {
        switch kind {
        case .both:
            HStack(spacing: -size * 0.35) {
                avatar(parent: Parent.defaultYou)
                avatar(parent: Parent.defaultPartner)
            }
        case .solo(let parent):
            avatar(parent: parent)
        case .split(let you, let partner):
            HStack(spacing: 2) {
                avatar(parent: you)
                Text("/")
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(.warmTextFaint)
                avatar(parent: partner)
            }
        case .unassigned:
            Circle()
                .strokeBorder(Color.warmTextFaint, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                .frame(width: size, height: size)
                .overlay(
                    Text("?")
                        .font(.system(size: size * 0.55, weight: .semibold))
                        .foregroundStyle(.warmTextFaint)
                )
        }
    }

    private func avatar(parent: Parent) -> some View {
        Text(parent.initial)
            .font(.system(size: size * 0.46, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color.oklch(0.60, 0.14, parent.hue), in: Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
    }

    private var label: String {
        switch kind {
        case .both: return "Both"
        case .solo(let p): return p.short
        case .split: return "Split"
        case .unassigned: return "Claim"
        }
    }
}

extension Parent {
    /// 60/14/h avatar fill — used in chip and elsewhere where a parent's
    /// solid color is needed.
    var color: Color { Color.oklch(0.60, 0.14, hue) }
    var softBG: Color { Color.oklch(0.94, 0.05, hue) }
    var softInk: Color { Color.oklch(0.32, 0.13, hue) }
}
