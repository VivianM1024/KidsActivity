import SwiftUI

struct ActivityListView: View {
    @Environment(ActivityStore.self) private var store

    var body: some View {
        let filtered = store.filteredActivities
        List {
            if let m = store.manifest {
                Section {
                    HStack {
                        Text("\(filtered.count) of \(store.activities.count) activities")
                        Spacer()
                        Text("Updated \(Formatters.dayOnly.string(from: m.lastUpdated))")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
            }
            Section {
                ForEach(filtered) { activity in
                    NavigationLink(value: activity) {
                        ActivityRowView(activity: activity)
                    }
                }
                if filtered.isEmpty && store.activities.count > 0 {
                    Text("No activities match the current filters.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationDestination(for: Activity.self) { ActivityDetailView(activity: $0) }
    }
}
