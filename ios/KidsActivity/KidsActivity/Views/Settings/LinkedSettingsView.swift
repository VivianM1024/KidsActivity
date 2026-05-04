import SwiftUI

/// Settings face shown to users with an active partner link. Hosts the
/// partner-hero card, this-week's load summary, sync activity log, and the
/// management rows (regen code, partner device, unlink).
///
/// Mirrors `v5-share.jsx::V5LinkedSettings` + `v5-coparent.jsx::V5LinkedLoad`
/// rolled into a single screen — both prototypes share the linked-state
/// header.
struct LinkedSettingsView: View {
    @Environment(ActivityStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showUnlinkConfirm = false

    private var partner: Parent? { store.linkedParent?.partner }
    private var code: String { store.linkedParent?.inviteCode ?? "" }
    private var linkedAt: Date { store.linkedParent?.linkedAt ?? Date() }

    var body: some View {
        ZStack {
            Color.warmCanvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    partnerHero
                    loadSummary
                    activityLog
                    manageSection
                    unlinkRow
                    privacyFooter
                    Color.clear.frame(height: 32)
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Linked")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.warmCanvas, for: .navigationBar)
        .alert("Unlink \(partner?.name ?? "partner")?", isPresented: $showUnlinkConfirm) {
            Button("Unlink", role: .destructive) {
                store.unlinkPartner()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Stops sharing on both phones. Your saves and calendar stay; their devices clear.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("LINKED")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.warmTextFaint)
            Text("You + \(partner?.name ?? "Sam")")
                .font(.v5Display)
                .kerning(-0.6)
                .foregroundStyle(.warmTextPrimary)
            Text("Planning together. Changes show up on both phones within a few seconds.")
                .font(.system(size: 13))
                .foregroundStyle(.warmTextTertiary)
                .padding(.top, 2)
                .lineSpacing(1.5)
        }
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 16)
    }

    // MARK: - Partner hero

    private var partnerHero: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 4) {
                avatarStack(parent: store.selfParent, label: "You")
                Spacer(minLength: 0)
                connectorBar
                Spacer(minLength: 0)
                if let partner {
                    avatarStack(parent: partner, label: partner.name)
                }
            }

            // Stats row
            HStack(spacing: 0) {
                stat(value: "\(store.kids.count)", label: "kids", divider: false)
                stat(value: "\(store.savedActivityIds.count)", label: "saved", divider: true)
                stat(
                    value: "\(store.calendarEvents.filter { $0.date >= Date() }.count)",
                    label: "upcoming", divider: true
                )
            }
            .padding(.top, 12)
            .overlay(alignment: .top) {
                Rectangle().fill(Color(brown: 0.08)).frame(height: 0.5)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Color.warmCard, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(brown: 0.06), lineWidth: 0.5)
        )
        .shadow(color: Color(brown: 0.05), radius: 12, y: 2)
        .padding(.horizontal, 16).padding(.bottom, 18)
    }

    private func avatarStack(parent: Parent, label: String) -> some View {
        VStack(spacing: 6) {
            Text(parent.initial)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(parent.color, in: Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(color: Color(brown: 0.06), radius: 1)
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.warmTextPrimary)
        }
    }

    private var connectorBar: some View {
        VStack(spacing: 4) {
            Text("LINKED")
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.warmTextTertiary)
            // Animated dashed line. Going dashed-static for now; an animated
            // dot would need a TimelineView; the linked state itself reads
            // alive enough through the colored avatars.
            ZStack {
                Rectangle()
                    .fill(Color(brown: 0.10))
                    .frame(height: 1.5)
                    .overlay(
                        Rectangle()
                            .stroke(Color(brown: 0.10), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                            .frame(height: 1.5)
                    )
            }
            .frame(maxWidth: 80)
            Text("last sync · now")
                .font(.system(size: 10.5, weight: .semibold).monospacedDigit())
                .foregroundStyle(.partnerBlue)
        }
        .padding(.bottom, 14)
    }

    private func stat(value: String, label: String, divider: Bool) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .bold).monospacedDigit())
                .kerning(-0.5)
                .foregroundStyle(.warmTextPrimary)
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.3)
                .foregroundStyle(.warmTextFaint)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .leading) {
            if divider {
                Rectangle().fill(Color(brown: 0.08)).frame(width: 0.5)
            }
        }
    }

    // MARK: - Load summary

    private var loadSummary: some View {
        let summary = store.loadSummaryThisWeek()
        let total = max(1, summary.you + summary.partner + summary.both)
        return VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("THIS WEEK'S LOAD")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(.warmTextFaint)
                Text("On-demand only — we don't notify you about it.")
                    .font(.system(size: 11))
                    .foregroundStyle(.warmTextTertiary)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                loadBar(
                    you: CGFloat(summary.you),
                    partner: CGFloat(summary.partner),
                    both: CGFloat(summary.both),
                    total: CGFloat(total)
                )

                HStack(spacing: 8) {
                    loadCell(parent: store.selfParent, count: summary.you, isBoth: false)
                    loadCellBoth(count: summary.both)
                    loadCell(parent: partner ?? .defaultPartner, count: summary.partner, isBoth: false)
                }

                if summary.you > summary.partner + summary.both {
                    loadAdvice("You've got an extra event this week. Tap an event in Calendar to swap.")
                } else if summary.you + summary.partner + summary.both == 0 {
                    loadAdvice("No assignments yet. Open any event in Calendar to assign Both / Solo / Split.")
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .warmCard(radius: 14)
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 18)
    }

    private func loadBar(you: CGFloat, partner: CGFloat, both: CGFloat, total: CGFloat) -> some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                Rectangle().fill(store.selfParent.color)
                    .frame(width: max(0, you / total * geo.size.width))
                Rectangle().fill(Color.oklch(0.70, 0.05, 60))
                    .frame(width: max(0, both / total * geo.size.width))
                Rectangle().fill(Color.partnerBlue)
                    .frame(width: max(0, partner / total * geo.size.width))
            }
            .background(Color(brown: 0.06))
        }
        .frame(height: 10)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private func loadCell(parent: Parent, count: Int, isBoth: Bool) -> some View {
        VStack(spacing: 4) {
            ParentChip(kind: .solo(parent), size: 20)
            Text("\(count)")
                .font(.system(size: 18, weight: .bold).monospacedDigit())
                .foregroundStyle(parent.softInk)
            Text(parent.short)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(parent.softInk.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(parent.softBG, in: RoundedRectangle(cornerRadius: 10))
    }

    private func loadCellBoth(count: Int) -> some View {
        VStack(spacing: 4) {
            ParentChip(kind: .both, size: 20)
            Text("\(count)")
                .font(.system(size: 18, weight: .bold).monospacedDigit())
                .foregroundStyle(.warmTextPrimary)
            Text("Both")
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(.warmTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(brown: 0.04), in: RoundedRectangle(cornerRadius: 10))
    }

    private func loadAdvice(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11.5))
            .foregroundStyle(.warmTextTertiary)
            .lineSpacing(2)
            .padding(.horizontal, 12).padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.warmCanvas, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Activity log

    private var activityLog: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RECENT ACTIVITY")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.warmTextFaint)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                logRow(role: .you, when: "—", what: "linked", target: "with code \(code)", showDivider: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .warmCard()
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 18)
    }

    private func logRow(role: Parent.Role, when: String, what: String, target: String, showDivider: Bool) -> some View {
        let parent = role == .you ? store.selfParent : (partner ?? .defaultPartner)
        return VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Text(parent.initial)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(parent.color, in: Circle())
                Group {
                    Text(role == .you ? "You" : parent.name).foregroundStyle(parent.color).fontWeight(.semibold)
                    + Text(" \(what) ").foregroundStyle(.warmTextTertiary)
                    + Text(target).foregroundStyle(.warmTextPrimary)
                }
                .font(.system(size: 12.5))
                .lineSpacing(1.5)
                Spacer(minLength: 0)
                Text(when)
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(.warmTextFaint)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)

            if showDivider {
                Rectangle().fill(Color(brown: 0.07)).frame(height: 0.5)
                    .padding(.leading, 14)
            }
        }
    }

    // MARK: - Manage

    private var manageSection: some View {
        VStack(spacing: 0) {
            manageRow(icon: "barcode", label: "Get a new code", detail: "If your code expired or got out", danger: false, last: false) {
                // TODO: regenerate the code (currently no UI to view it again here)
            }
            manageRow(icon: "iphone", label: "\(partner?.name ?? "Partner")'s device", detail: "iPhone · added \(monthDay(linkedAt))", danger: false, last: true) {}
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard()
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private func manageRow(icon: String, label: String, detail: String, danger: Bool, last: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(danger ? Color.dangerRed : Color.warmTextPrimary)
                        .frame(width: 30, height: 30)
                        .background(
                            danger ? AnyShapeStyle(Color.dangerRedSoft) : AnyShapeStyle(Color(brown: 0.05)),
                            in: RoundedRectangle(cornerRadius: 9)
                        )
                    VStack(alignment: .leading, spacing: 1) {
                        Text(label)
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(danger ? Color.dangerRed : Color.warmTextPrimary)
                        Text(detail)
                            .font(.system(size: 11.5))
                            .foregroundStyle(.warmTextTertiary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.warmTextFaint)
                }
                .padding(.horizontal, 14).padding(.vertical, 12)

                if !last {
                    Rectangle().fill(Color(brown: 0.07)).frame(height: 0.5)
                        .padding(.leading, 14)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Unlink

    private var unlinkRow: some View {
        Button { showUnlinkConfirm = true } label: {
            Text("Unlink \(partner?.name ?? "partner")")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.dangerRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16).padding(.bottom, 12)
    }

    private var privacyFooter: some View {
        Text("Linked devices share Saved, Calendar, and Kids. Filters and search history stay on each device.")
            .font(.system(size: 11.5))
            .foregroundStyle(.warmTextTertiary)
            .lineSpacing(2)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24).padding(.bottom, 24)
    }

    private func monthDay(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: d)
    }
}
