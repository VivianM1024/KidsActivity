import SwiftUI

/// Standalone "this week's load" surface, intended as a lightweight
/// alternative entry point if the user wants to read just the load summary
/// without the full LinkedSettingsView. Currently unused — the load card is
/// inlined in LinkedSettingsView — but kept here for parity with the
/// prototype's `V5LinkedLoad` artboard.
struct LinkedLoadView: View {
    @Environment(ActivityStore.self) private var store

    private var partner: Parent? { store.linkedParent?.partner }

    var body: some View {
        ZStack {
            Color.warmCanvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("LINKED LOAD")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(.warmTextFaint)
                    Text(store.linkedParent != nil
                         ? "You + \(partner?.name ?? "Sam") this week"
                         : "Link a partner to see load")
                        .font(.v5Display)
                        .kerning(-0.6)
                        .foregroundStyle(.warmTextPrimary)
                }
                .padding(.horizontal, 20).padding(.top, 12)
            }
        }
        .navigationTitle("Load")
        .navigationBarTitleDisplayMode(.inline)
    }
}
