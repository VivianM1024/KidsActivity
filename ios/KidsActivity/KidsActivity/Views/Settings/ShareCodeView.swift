import SwiftUI

/// Generates an invite code for the user to share. Local-only: tapping
/// "Copy code" copies it; "Send via..." opens a share sheet. The code
/// itself is just a memory aid — there's no backend handshake yet, so any
/// well-formed code unlocks the partner-link flow on the receiving side.
///
/// Mirrors `v5-share.jsx::V5ShareCode`.
struct ShareCodeView: View {
    @Environment(ActivityStore.self) private var store
    @State private var code: String = InviteCode.generate()
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            Color.warmCanvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    codeCard
                    whatYoullShareSection
                    privacyNote
                    footerHelp
                    Color.clear.frame(height: 24)
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Share")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.warmCanvas, for: .navigationBar)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: ["Plan kids' activities with me on KidsActivity. Use code: \(code)"])
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(Color.terracotta).frame(width: 6, height: 6)
                Text("PLAN TOGETHER")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(Color.oklch(0.45, 0.13, 22))
            }
            Text("Share your list with\nanother parent.")
                .font(.system(size: 24, weight: .bold))
                .kerning(-0.5)
                .foregroundStyle(.warmTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("They'll enter this code on their phone and you'll both see the same Saved activities, calendar, and kids — in real time.")
                .font(.system(size: 13))
                .foregroundStyle(.warmTextTertiary)
                .lineSpacing(2)
                .padding(.top, 4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24).padding(.top, 8).padding(.bottom, 14)
    }

    // MARK: - Code card

    private var codeCard: some View {
        VStack(spacing: 0) {
            Text("YOUR CODE")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(.warmTextFaint)
                .padding(.bottom, 10)

            codeText
                .padding(.bottom, 6)

            Text("Expires in 24 hours · single use")
                .font(.system(size: 11.5))
                .foregroundStyle(.warmTextTertiary)
                .padding(.bottom, 16)

            HStack(spacing: 8) {
                actionPill(icon: "doc.on.doc", label: "Copy code", filled: true) {
                    UIPasteboard.general.string = code
                }
                actionPill(icon: "square.and.arrow.up", label: "Send via…", filled: false) {
                    showShareSheet = true
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .background(Color.warmCard, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(brown: 0.06), lineWidth: 0.5)
        )
        .shadow(color: Color(brown: 0.06), radius: 12, y: 2)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var codeText: some View {
        let parts = code.split(separator: "-").map(String.init)
        return HStack(alignment: .firstTextBaseline, spacing: 4) {
            if parts.count == 3 {
                Text(parts[0])
                    .foregroundStyle(.warmTextPrimary)
                Text("–").foregroundStyle(.warmTextFaint)
                Text(parts[1])
                    .foregroundStyle(.warmTextPrimary)
                Text("–").foregroundStyle(.warmTextFaint)
                Text(parts[2])
                    .foregroundStyle(.warmTextPrimary)
            } else {
                Text(code).foregroundStyle(.warmTextPrimary)
            }
        }
        .font(.system(size: 26, weight: .bold, design: .monospaced))
        .kerning(-0.5)
    }

    private func actionPill(icon: String, label: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
                    .font(.system(size: 12.5, weight: .semibold))
            }
            .foregroundStyle(filled ? .white : .warmTextPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(filled ? AnyShapeStyle(Color.terracotta) : AnyShapeStyle(Color(brown: 0.05)))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - What you'll share

    private var whatYoullShareSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionEyebrow("What you'll share")
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                syncRow(
                    icon: AnyView(syncIcon(systemName: "person.2.fill", hue: 22)),
                    label: "Kids",
                    value: store.kids.isEmpty
                        ? "0 kids"
                        : store.kids.map { "\($0.name) (\($0.ageYears))" }.joined(separator: ", "),
                    showDivider: true
                )
                syncRow(
                    icon: AnyView(syncIcon(systemName: "heart.fill", hue: 350)),
                    label: "Saved activities",
                    value: "\(store.savedActivityIds.count) saved · hearts sync both ways",
                    showDivider: true
                )
                syncRow(
                    icon: AnyView(syncIcon(systemName: "calendar", hue: 145)),
                    label: "Calendar",
                    value: "Confirmed registrations show on both devices",
                    showDivider: false
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .warmCard()
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 12)
    }

    private func syncIcon(systemName: String, hue: Double) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.oklch(0.50, 0.13, hue))
            .frame(width: 30, height: 30)
            .background(Color.oklch(0.95, 0.06, hue), in: Circle())
    }

    private func syncRow(icon: AnyView, label: String, value: String, showDivider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                icon
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.warmTextPrimary)
                    Text(value)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.warmTextTertiary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(Color.terracotta, in: Circle())
            }
            .padding(.horizontal, 14).padding(.vertical, 12)

            if showDivider {
                Rectangle().fill(Color(brown: 0.07))
                    .frame(height: 0.5)
                    .padding(.leading, 14)
            }
        }
    }

    private var privacyNote: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionEyebrow("Stays on your phone")
                .padding(.horizontal, 20)
            Text("Filters, location, and search history are device-local. We don't make accounts — the code is the only link.")
                .font(.system(size: 12.5))
                .foregroundStyle(.warmTextTertiary)
                .lineSpacing(2)
                .padding(.horizontal, 14).padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(brown: 0.03), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
    }

    private var footerHelp: some View {
        Text("Need to undo this? Manage in Settings →")
            .font(.system(size: 12))
            .foregroundStyle(.warmTextTertiary)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
    }

    private func sectionEyebrow(_ label: String) -> some View {
        Text(label.uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(0.5)
            .foregroundStyle(.warmTextFaint)
    }
}

// MARK: - Share sheet shim

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
