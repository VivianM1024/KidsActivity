import SwiftUI

/// "Who's going?" section embedded in `ActivityDetailView`. Renders ONLY
/// when the user has linked a co-parent (`store.linkedParent != nil`).
///
/// Collapsed (default): a single ghost row with "+ Add {partner} to this
/// activity" — co-parent is opt-in per activity.
///
/// Expanded: segmented control (Both / Solo / Split) + a body per mode.
/// Saving writes an `Assignment` keyed by `activityId` (no per-session date),
/// applying as the activity-level default.
///
/// Mirrors `v5-coparent.jsx::V5DetailWhosGoing`.
struct WhosGoingSection: View {
    let activity: Activity
    @Environment(ActivityStore.self) private var store

    @State private var expanded: Bool = false
    @State private var draftMode: Mode = .both
    @State private var draftSoloPartnerId: UUID?
    @State private var draftSplit: [UUID: UUID] = [:]   // kidId → parentId

    enum Mode: Hashable { case both, solo, split }

    private var partner: Parent? { store.linkedParent?.partner }
    private var existingAssignment: Assignment? {
        store.assignment(for: activity.activityId)
    }
    private var matchingKids: [Kid] {
        // Use the kids that match this activity, falling back to all kids
        // if none match (still want a meaningful split picker).
        let matched = store.matchKids(for: activity)
        return matched.isEmpty ? store.kids : matched
    }

    var body: some View {
        guard store.linkedParent != nil, let partner else {
            return AnyView(EmptyView())
        }
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                if !expanded { collapsedRow(partner: partner) } else { expandedBody(partner: partner) }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
            .onAppear { primeDraftFromExisting(partner: partner) }
        )
    }

    private func primeDraftFromExisting(partner: Parent) {
        guard let existing = existingAssignment else { return }
        expanded = true
        switch existing.kind {
        case .both:
            draftMode = .both
        case .solo(let pid):
            draftMode = .solo
            draftSoloPartnerId = pid
        case .split(let m):
            draftMode = .split
            draftSplit = m
        }
    }

    // MARK: - Collapsed

    private func collapsedRow(partner: Parent) -> some View {
        Button { withAnimation { expanded = true } } label: {
            HStack(spacing: 12) {
                ParentChip(kind: .unassigned, size: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add \(partner.name) to this activity")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(.warmTextPrimary)
                    Text("Optional. Only shows on \(partner.name)'s calendar if you assign them.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.warmTextTertiary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(.warmTextFaint)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.warmCard, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.warmTextFaint.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded

    @ViewBuilder
    private func expandedBody(partner: Parent) -> some View {
        modeSegments(partner: partner)
        modeCard(partner: partner)
        actionRow(partner: partner)
    }

    private func modeSegments(partner: Parent) -> some View {
        HStack(spacing: 2) {
            modeButton(.both, label: "Both go")
            modeButton(.solo, label: "Just \(partner.name)")
            modeButton(.split, label: "Split kids")
        }
        .padding(3)
        .background(Color(brown: 0.05), in: RoundedRectangle(cornerRadius: 10))
    }

    private func modeButton(_ mode: Mode, label: String) -> some View {
        let on = draftMode == mode
        return Button {
            draftMode = mode
            if mode == .solo, draftSoloPartnerId == nil {
                draftSoloPartnerId = partner?.id ?? store.linkedParent?.partner.id
            }
            if mode == .split, draftSplit.isEmpty, let p = partner {
                // Default split: alternate kids between you and partner.
                var assigned: [UUID: UUID] = [:]
                for (i, k) in matchingKids.enumerated() {
                    assigned[k.id] = (i % 2 == 0) ? store.selfParent.id : p.id
                }
                draftSplit = assigned
            }
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(on ? .warmTextPrimary : .warmTextTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8).padding(.horizontal, 6)
                .background(on ? Color.warmCard : .clear, in: RoundedRectangle(cornerRadius: 8))
                .shadow(color: on ? Color(brown: 0.06) : .clear, radius: 1, y: 1)
        }
        .buttonStyle(.plain)
    }

    private func modeCard(partner: Parent) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            switch draftMode {
            case .both:    bothBody(partner: partner)
            case .solo:    soloBody(partner: partner)
            case .split:   splitBody(partner: partner)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard(radius: 14)
    }

    private func bothBody(partner: Parent) -> some View {
        HStack(spacing: 14) {
            ParentChip(kind: .both, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text("You and \(partner.name), both kids")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.warmTextPrimary)
                Text("Adds the event to \(partner.name)'s calendar too.")
                    .font(.system(size: 12))
                    .foregroundStyle(.warmTextTertiary)
                    .lineSpacing(1.5)
            }
            Spacer(minLength: 0)
        }
    }

    private func soloBody(partner: Parent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WHO'S TAKING THE KIDS?")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.4)
                .foregroundStyle(.warmTextFaint)
                .padding(.bottom, 2)

            soloOption(parent: store.selfParent)
            soloOption(parent: partner)
        }
    }

    private func soloOption(parent: Parent) -> some View {
        let on = draftSoloPartnerId == parent.id
        return Button { draftSoloPartnerId = parent.id } label: {
            HStack(spacing: 12) {
                ParentChip(kind: .solo(parent), size: 28)
                Text(parent.role == .you ? "You" : parent.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.warmTextPrimary)
                Spacer(minLength: 0)
                if on {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(parent.color)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(
                on ? AnyShapeStyle(parent.softBG) : AnyShapeStyle(Color.clear),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(on ? parent.color : Color(brown: 0.08), lineWidth: on ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func splitBody(partner: Parent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ASSIGN PER KID")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.4)
                .foregroundStyle(.warmTextFaint)
                .padding(.bottom, 2)

            ForEach(matchingKids) { kid in
                splitRow(kid: kid, partner: partner)
            }

            Text("Tap any chip to swap.")
                .font(.system(size: 11.5))
                .foregroundStyle(.warmTextTertiary)
                .padding(.top, 2)
        }
    }

    private func splitRow(kid: Kid, partner: Parent) -> some View {
        let assignedParentId = draftSplit[kid.id] ?? store.selfParent.id
        let assignedParent = (assignedParentId == partner.id) ? partner : store.selfParent
        return HStack(spacing: 10) {
            Text(kid.initial)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(kid.avatarColor, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(kid.name)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.warmTextPrimary)
                Text("\(kid.ageYears) yrs")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.warmTextTertiary)
            }
            Spacer(minLength: 0)
            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.warmTextFaint)

            Button {
                // Swap which parent this kid is assigned to.
                draftSplit[kid.id] = (assignedParentId == partner.id) ? store.selfParent.id : partner.id
            } label: {
                HStack(spacing: 6) {
                    ParentChip(kind: .solo(assignedParent), size: 16)
                    Text(assignedParent.short)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(assignedParent.softInk)
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(assignedParent.softBG, in: Capsule())
                .overlay(Capsule().stroke(assignedParent.color, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Color.warmCanvas, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(brown: 0.07), lineWidth: 0.5)
        )
    }

    // MARK: - Actions

    private func actionRow(partner: Parent) -> some View {
        HStack(spacing: 8) {
            Button {
                withAnimation { expanded = false }
                if existingAssignment == nil {
                    // Reset drafts so re-opening is fresh.
                    draftSoloPartnerId = nil
                    draftSplit = [:]
                    draftMode = .both
                }
            } label: {
                Text(existingAssignment != nil ? "Remove" : "Cancel")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(existingAssignment != nil ? Color.dangerRed : Color.warmTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        existingAssignment != nil ? AnyShapeStyle(Color.dangerRedSoft) : AnyShapeStyle(Color(brown: 0.05)),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
            }
            .buttonStyle(.plain)
            .onTapGesture {
                if existingAssignment != nil {
                    store.clearAssignment(for: activity.activityId)
                    withAnimation { expanded = false }
                }
            }

            Button {
                save(partner: partner)
                withAnimation { expanded = false }
            } label: {
                Text(saveLabel(partner: partner))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.terracotta, in: RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.terracotta.opacity(0.22), radius: 8, y: 2)
            }
            .buttonStyle(.plain)
            .disabled(!canSave())
        }
    }

    private func saveLabel(partner: Parent) -> String {
        switch draftMode {
        case .both: return "Add to \(partner.name)'s calendar"
        case .solo:
            if draftSoloPartnerId == partner.id { return "\(partner.name) takes the kids" }
            return "You take the kids"
        case .split: return "Save split"
        }
    }

    private func canSave() -> Bool {
        switch draftMode {
        case .both: return true
        case .solo: return draftSoloPartnerId != nil
        case .split: return matchingKids.allSatisfy { draftSplit[$0.id] != nil }
        }
    }

    private func save(partner: Parent) {
        let kind: AssignmentKind
        switch draftMode {
        case .both:
            kind = .both
        case .solo:
            guard let pid = draftSoloPartnerId else { return }
            kind = .solo(parentId: pid)
        case .split:
            kind = .split(byKid: draftSplit)
        }
        store.setAssignment(kind, for: activity.activityId)
    }
}
