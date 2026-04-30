import SwiftUI

struct FilterSheet: View {
    @Environment(ActivityStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            Form {
                Section("Venue type") {
                    ForEach(VenueType.allCases, id: \.self) { type in
                        Toggle(isOn: Binding(
                            get: { store.filters.venueTypes.contains(type) },
                            set: { isOn in
                                if isOn {
                                    store.filters.venueTypes.insert(type)
                                } else {
                                    store.filters.venueTypes.remove(type)
                                }
                            }
                        )) {
                            Label(type.label, systemImage: type.symbol)
                        }
                    }
                }

                Section("Age (months)") {
                    HStack {
                        Text("Min")
                        Spacer()
                        TextField("any", value: $store.filters.ageMinMonths, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Max")
                        Spacer()
                        TextField("any", value: $store.filters.ageMaxMonths, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Date range") {
                    DateRow(label: "From", date: $store.filters.startDate)
                    DateRow(label: "Until", date: $store.filters.endDate)
                }

                Section {
                    Toggle("Registration open only", isOn: $store.filters.registrationOpenOnly)
                    TextField("Keyword", text: $store.filters.keyword)
                }

                Section {
                    Button("Reset filters", role: .destructive) {
                        store.filters = .default
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct DateRow: View {
    let label: String
    @Binding var date: Date?

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            if let d = date {
                DatePicker("", selection: Binding(
                    get: { d },
                    set: { date = $0 }
                ), displayedComponents: .date)
                .labelsHidden()
                Button {
                    date = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
            } else {
                Button("Pick date") { date = Date() }
            }
        }
    }
}
