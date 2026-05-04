import SwiftUI

struct ContentView: View {
    @Environment(ActivityStore.self) private var store

    var body: some View {
        switch store.state {
        case .idle, .loading:
            ZStack {
                Color.warmCanvas.ignoresSafeArea()
                ProgressView("Loading activities…")
                    .tint(.terracotta)
                    .foregroundStyle(.warmTextSecondary)
            }
        case .ready:
            V5TabView()
        case .error(let msg):
            ZStack {
                Color.warmCanvas.ignoresSafeArea()
                ContentUnavailableView(
                    "Couldn't load data",
                    systemImage: "wifi.exclamationmark",
                    description: Text(msg)
                )
            }
        }
    }
}

private struct V5TabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                BrowseView()
                    .navigationDestination(for: Activity.self) { ActivityDetailView(activity: $0) }
            }
            .tabItem { Label("Browse", systemImage: "magnifyingglass") }

            NavigationStack {
                SavedView()
                    .navigationDestination(for: Activity.self) { ActivityDetailView(activity: $0) }
            }
            .tabItem { Label("Saved", systemImage: "bookmark") }

            NavigationStack {
                CalendarView()
                    .navigationDestination(for: Activity.self) { ActivityDetailView(activity: $0) }
            }
            .tabItem { Label("Calendar", systemImage: "calendar") }
        }
        .tint(.terracotta)
    }
}
