import SwiftUI

@main
struct KidsActivityApp: App {
    @State private var store = ActivityStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .task { await store.load() }
        }
    }
}
