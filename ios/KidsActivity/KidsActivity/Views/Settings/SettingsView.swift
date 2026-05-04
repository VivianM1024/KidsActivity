import SwiftUI

/// Hub for the gear-icon entry on Browse. Branches on linked state:
/// - Not linked → two CTAs: "Generate a code" (ShareCodeView) and
///   "Enter a code" (EnterCodeView).
/// - Linked → routes the user straight to LinkedSettingsView.
struct SettingsView: View {
    @Environment(ActivityStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.warmCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header

                        if store.linkedParent != nil {
                            linkedHero
                        } else {
                            unlinkedSection
                        }

                        managementSection

                        Color.clear.frame(height: 40)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.warmCanvas, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.warmTextSecondary)
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PROFILE")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.warmTextFaint)
            Text(store.linkedParent != nil
                 ? "You + \(store.linkedParent!.partner.name)"
                 : "You")
                .font(.v5Display)
                .kerning(-0.6)
                .foregroundStyle(.warmTextPrimary)
            Text(store.linkedParent != nil
                 ? "Planning together. Changes show up on both phones."
                 : "Plan together with another parent if it helps.")
                .font(.system(size: 13))
                .foregroundStyle(.warmTextTertiary)
                .padding(.top, 2)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12).padding(.bottom, 18)
    }

    private var linkedHero: some View {
        NavigationLink {
            LinkedSettingsView()
        } label: {
            HStack(spacing: 14) {
                ParentChip(kind: .both, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text("You & \(store.linkedParent?.partner.name ?? "Sam") are linked")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.warmTextPrimary)
                    Text("Manage code, devices, and load summary →")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.warmTextTertiary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.warmTextFaint)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .warmCard()
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    private var unlinkedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LINK A CO-PARENT")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.warmTextFaint)
                .padding(.horizontal, 20)

            VStack(spacing: 8) {
                NavigationLink { ShareCodeView() } label: {
                    settingRow(
                        icon: "qrcode",
                        iconBG: Color.terracottaSoft,
                        iconFG: Color.terracottaDeep,
                        title: "Generate a code",
                        subtitle: "Send to your co-parent — they enter it on their phone"
                    )
                }.buttonStyle(.plain)

                NavigationLink { EnterCodeView() } label: {
                    settingRow(
                        icon: "keyboard",
                        iconBG: Color.partnerBlueSoft,
                        iconFG: Color.partnerBlueInk,
                        title: "Enter a code",
                        subtitle: "If your partner already shared one with you"
                    )
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 18)
    }

    private var managementSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ABOUT")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.warmTextFaint)
                .padding(.horizontal, 20)

            VStack(spacing: 8) {
                infoRow(label: "Kids", value: "\(store.kids.count)")
                infoRow(label: "Saved", value: "\(store.savedActivityIds.count)")
                infoRow(label: "Registered", value: "\(store.registeredActivityIds.count)")
                infoRow(
                    label: "Home",
                    value: store.homeZIP.isEmpty ? "Not set" : store.homeZIP
                )
            }
            .padding(.horizontal, 16)
        }
    }

    private func settingRow(
        icon: String, iconBG: Color, iconFG: Color,
        title: String, subtitle: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconFG)
                .frame(width: 32, height: 32)
                .background(iconBG, in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.warmTextPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.warmTextTertiary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.warmTextFaint)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard()
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.warmTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundStyle(.warmTextPrimary)
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard()
    }
}
