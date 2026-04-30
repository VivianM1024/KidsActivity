import SwiftUI

struct ContentView: View {
    @Environment(ActivityStore.self) private var store
    @State private var showFilters = false

    var body: some View {
        NavigationStack {
            Group {
                switch store.state {
                case .idle, .loading:
                    ProgressView("Loading activities…")
                case .ready:
                    ActivityListView()
                case .error(let msg):
                    ContentUnavailableView(
                        "Couldn't load data",
                        systemImage: "wifi.exclamationmark",
                        description: Text(msg)
                    )
                }
            }
            .navigationTitle("Kids Activities")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showFilters = true } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filters")
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await store.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh")
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet()
            }
        }
    }
}
