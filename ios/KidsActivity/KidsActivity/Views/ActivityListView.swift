import SwiftUI

// V5 Browse — search, kid picker, venue type bar, category chips, sort, list.
// (File kept under the original name to preserve the Xcode project mapping.)

struct BrowseView: View {
    @Environment(ActivityStore.self) private var store
    @State private var showFilters = false
    @State private var showSettings = false
    @State private var showWhyThis = false
    @State private var searchDebounceWorkItem: DispatchWorkItem?
    @State private var localSearch: String = ""

    private let visibleCategories: [ActivityCategory] = [.sports, .arts, .stem, .events, .storytime]

    var body: some View {
        @Bindable var store = store
        let filtered = store.filteredActivities

        ZStack(alignment: .top) {
            Color.warmCanvas.ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    titleBlock
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 6)

                    searchAndKids(searchBinding: $localSearch)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)

                    venueTypeBar
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)

                    categoryChips
                        .padding(.bottom, 4)

                    kindAndSortRow(matchCount: filtered.count)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)

                    if filtered.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 6) {
                            ForEach(filtered) { activity in
                                NavigationLink(value: activity) {
                                    ActivityRow(activity: activity)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 14)
                    }

                    Color.clear.frame(height: 32)
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.warmTextPrimary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showFilters = true } label: {
                    let n = store.filters.activeCount
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease")
                        if n > 0 {
                            Text("\(n)")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 5).padding(.vertical, 1)
                                .background(Color.terracotta, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                }
                .tint(.warmTextPrimary)
            }
        }
        .toolbarBackground(Color.warmCanvas, for: .navigationBar)
        .sheet(isPresented: $showFilters) {
            FilterSheet()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showWhyThis) {
            WhyThisSheet()
        }
        .onAppear { localSearch = store.searchText }
        .onChange(of: localSearch) { _, new in
            // Debounce 300ms, per README. Replace any pending work item.
            searchDebounceWorkItem?.cancel()
            let item = DispatchWorkItem { @MainActor in store.searchText = new }
            searchDebounceWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: item)
        }
    }

    // MARK: - Sections

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Chicagoland · \(store.activities.count) listings")
                .font(.v5Eyebrow)
                .tracking(0.5)
                .foregroundStyle(Color.oklch(0.55, 0.05, 60))
                .textCase(.uppercase)
            Text("What sounds good?")
                .font(.v5Display)
                .kerning(-0.6)
                .foregroundStyle(.warmTextPrimary)
                .lineLimit(1)
        }
    }

    private func searchAndKids(searchBinding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.warmTextMuted)
                TextField("Soccer, art, swim…", text: searchBinding)
                    .font(.system(size: 14))
                    .foregroundStyle(.warmTextPrimary)
                    .submitLabel(.search)
                    .textFieldStyle(.plain)
                if !searchBinding.wrappedValue.isEmpty {
                    Button { searchBinding.wrappedValue = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.warmTextMuted)
                    }
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .warmCard(radius: 12)

            HStack(alignment: .center, spacing: 6) {
                Text("FOR")
                    .font(.system(size: 10.5, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(.warmTextFaint)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(store.kids) { kid in
                            kidPill(kid: kid, on: store.selectedKidIds.contains(kid.id))
                                .onTapGesture { store.toggleSelectedKid(kid) }
                        }
                    }
                }
            }
        }
    }

    private func kidPill(kid: Kid, on: Bool) -> some View {
        HStack(spacing: 6) {
            kidAvatar(kid: kid, size: 20)
            Text("\(kid.name) · \(kid.ageYears)y")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(on ? AnyShapeStyle(kid.pillFG) : AnyShapeStyle(Color.warmTextSecondary))
        }
        .padding(.leading, 4).padding(.trailing, 10)
        .padding(.vertical, 4)
        .background(on ? AnyShapeStyle(kid.pillBG) : AnyShapeStyle(Color.warmCard), in: Capsule())
        .overlay(
            Capsule().stroke(on ? kid.pillBorder : .warmBorder, lineWidth: on ? 1.5 : 1)
        )
    }

    private var venueTypeBar: some View {
        @Bindable var store = store
        let allOn = store.filters.venueTypes == Set(VenueType.allCases)

        return HStack(spacing: 2) {
            segment(label: "All",
                    on: allOn,
                    action: { store.filters.venueTypes = Set(VenueType.allCases) })
            ForEach(VenueType.allCases, id: \.self) { type in
                let only = store.filters.venueTypes == [type]
                segment(label: shortLabel(type),
                        on: only,
                        action: { store.filters.venueTypes = [type] })
            }
        }
        .padding(2)
        .background(Color(brown: 0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    private func segment(label: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(on ? Color.warmTextPrimary : .warmTextMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6).padding(.horizontal, 4)
                .background(on ? Color.warmCard : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8))
                .shadow(color: on ? Color(brown: 0.08) : .clear, radius: 1, y: 1)
        }
        .buttonStyle(.plain)
    }

    private func shortLabel(_ t: VenueType) -> String {
        switch t {
        case .parkDistrict: return "Parks"
        case .library: return "Library"
        case .museum: return "Museum"
        case .communityCenter: return "Comm"
        }
    }

    private var categoryChips: some View {
        @Bindable var store = store
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                let allOn = store.filters.categories.isEmpty
                Button {
                    store.filters.categories = []
                } label: {
                    chipText("All", on: allOn)
                }.buttonStyle(.plain)

                ForEach(visibleCategories, id: \.self) { cat in
                    let on = store.filters.categories == [cat]
                    Button {
                        store.filters.categories = on ? [] : [cat]
                    } label: {
                        chipText(cat.label, on: on)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func chipText(_ label: String, on: Bool) -> some View {
        Text(label)
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 11).padding(.vertical, 5)
            .foregroundStyle(on ? Color.white : .warmTextSecondary)
            .background(on ? Color.warmTextPrimary : Color.clear, in: Capsule())
            .overlay(Capsule().stroke(on ? Color.warmTextPrimary : Color(brown: 0.15), lineWidth: 1))
    }

    private func kindAndSortRow(matchCount: Int) -> some View {
        @Bindable var store = store
        return HStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(ActivityFilters.KindFilter.allCases, id: \.self) { k in
                    let on = store.filters.kindFilter == k
                    Button {
                        store.filters.kindFilter = k
                    } label: {
                        Text(k.label)
                            .font(.system(size: 11.5, weight: .semibold))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .foregroundStyle(on ? Color.white : .warmTextSecondary)
                            .background(on ? Color.warmTextPrimary : .clear,
                                        in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
            .background(Color.warmCard, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8).stroke(Color(brown: 0.12), lineWidth: 0.5)
            )

            Spacer(minLength: 0)

            Button { showWhyThis = true } label: {
                HStack(spacing: 3) {
                    Text("\(matchCount) match")
                        .font(.system(size: 12).monospacedDigit())
                    Image(systemName: "info.circle")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(.warmTextTertiary)
            }
            .buttonStyle(.plain)

            HStack(spacing: 2) {
                ForEach(SortMode.allCases, id: \.self) { mode in
                    let on = store.sortMode == mode
                    Button { store.sortMode = mode } label: {
                        Text(mode.label)
                            .font(.system(size: 11.5, weight: .semibold))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .foregroundStyle(on ? Color.warmTextPrimary : .warmTextMuted)
                            .background(on ? Color(brown: 0.08) : .clear,
                                        in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        @Bindable var store = store
        return VStack(spacing: 8) {
            Text("Nothing matches that combination.")
                .font(.system(size: 13))
                .foregroundStyle(.warmTextMuted)
            Button("Clear filters") {
                store.resetFilters()
                localSearch = ""
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.terracotta)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Helpers

func kidAvatar(kid: Kid, size: CGFloat) -> some View {
    Text(kid.initial)
        .font(.system(size: size * 0.5, weight: .bold))
        .foregroundStyle(.white)
        .frame(width: size, height: size)
        .background(kid.avatarColor, in: Circle())
}

// Keep the legacy struct as a thin wrapper so any old call sites don't break.
struct ActivityListView: View {
    var body: some View { BrowseView() }
}
