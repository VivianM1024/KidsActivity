import SwiftUI

struct ContentView: View {
    @Environment(ActivityStore.self) private var store

    var body: some View {
        rootScene
            .fullScreenCover(isPresented: Binding(
                get: { !store.hasCompletedOnboarding },
                set: { _ in }
            )) {
                OnboardingFlow()
                    .interactiveDismissDisabled()
            }
    }

    @ViewBuilder
    private var rootScene: some View {
        switch store.state {
        case .idle, .loading:
            // Show the Browse skeleton instead of a centered spinner so the
            // shape of the UI is already in place when the data arrives —
            // matches `v5-loading.jsx` and avoids a layout pop.
            BrowseSkeletonView()
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
