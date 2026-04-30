import SwiftUI
import SafariServices

struct ActivityDetailView: View {
    let activity: Activity
    @State private var showSafari = false

    var body: some View {
        Form {
            Section(activity.name) {
                LabeledContent("Venue") { Text(activity.venueName) }
                LabeledContent("Type") { Text(activity.venueType.label) }
                if !activity.location.isEmpty {
                    LabeledContent("Location") { Text(activity.location) }
                }
                if let cat = activity.category {
                    LabeledContent("Category") { Text(cat.capitalized) }
                }
            }

            Section("Schedule") {
                Text(Formatters.scheduleSummary(activity.schedule))
                if !activity.schedule.weeklyTimes.isEmpty {
                    Text(Formatters.weeklyTimes(activity.schedule.weeklyTimes))
                        .foregroundStyle(.secondary)
                }
                if let n = activity.schedule.numSessions {
                    LabeledContent("Sessions") { Text("\(n)") }
                }
            }

            Section("Details") {
                LabeledContent("Ages") { Text(activity.ageRange.displayAge) }
                LabeledContent("Price") { Text(activity.price.displayPrice) }
                if let isOpen = activity.registration.isOpen {
                    LabeledContent("Registration") {
                        Text(isOpen ? "Open" : "Closed")
                            .foregroundStyle(isOpen ? .green : .red)
                    }
                }
                if let opens = activity.registration.opensAt {
                    LabeledContent("Opens") {
                        Text(Formatters.dayOnly.string(from: opens))
                    }
                }
            }

            if let desc = activity.description, !desc.isEmpty {
                Section("Description") {
                    Text(desc)
                }
            }

            Section {
                Button {
                    showSafari = true
                } label: {
                    Label("Open registration page", systemImage: "safari")
                }
            }
        }
        .navigationTitle(activity.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSafari) {
            SafariView(url: activity.sourceUrl)
                .ignoresSafeArea()
        }
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
