import SwiftUI

struct FilterSheet: View {
    @Environment(ActivityStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            ZStack {
                Color.warmCanvas.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        activeSummary
                            .padding(.horizontal, 16)
                            .padding(.top, 12).padding(.bottom, 18)

                        kidsSection
                        agesSection
                        distanceSection
                        daysSection
                        priceSection
                        registrationSection
                        venueTypeSection
                        categoriesSection

                        Color.clear.frame(height: 100)
                    }
                }
                .scrollIndicators(.hidden)

                applyCTA
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.warmCanvas, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") { store.resetFilters() }
                        .tint(.terracotta)
                        .font(.system(size: 14, weight: .semibold))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.warmTextSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var activeSummary: some View {
        let count = store.filters.activeCount
        return VStack(alignment: .leading, spacing: 6) {
            Text("ACTIVE FILTERS")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.4)
                .foregroundStyle(.warmTextFaint)
            Text(summaryText)
                .font(.system(size: 13))
                .foregroundStyle(.warmTextPrimary)
                .lineLimit(3)
            Text("\(count) active filter\(count == 1 ? "" : "s")")
                .font(.system(size: 11))
                .foregroundStyle(.warmTextMuted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard(radius: 12)
    }

    private var summaryText: AttributedString {
        var out = AttributedString("")
        let kids = store.selectedKids
        if kids.isEmpty {
            out += AttributedString("No kids selected")
        } else {
            for (i, k) in kids.enumerated() {
                if i > 0 { out += AttributedString(" + ") }
                var name = AttributedString(k.name)
                name.foregroundColor = k.deepText
                name.font = .system(size: 13, weight: .bold)
                out += name
            }
        }
        if let limit = store.filters.maxDistanceMiles {
            out += AttributedString(" · within \(Int(limit)) mi")
        }
        if !store.filters.daysOfWeek.isEmpty {
            let days = store.filters.daysOfWeek.sorted { $0.rawValue < $1.rawValue }.map(\.short).joined(separator: " ")
            out += AttributedString(" · \(days)")
        }
        if store.filters.registrationFilter != .any {
            out += AttributedString(" · \(store.filters.registrationFilter.label.lowercased())")
        }
        return out
    }

    private var kidsSection: some View {
        @Bindable var store = store
        return Section_(label: "Kids", subtitle: "Filter ages from your kids' profiles") {
            VStack(spacing: 4) {
                ForEach(store.kids) { kid in
                    let on = store.selectedKidIds.contains(kid.id)
                    Button {
                        store.toggleSelectedKid(kid)
                    } label: {
                        HStack(spacing: 12) {
                            Text(kid.initial)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(kid.avatarColor, in: Circle())
                            VStack(alignment: .leading, spacing: 1) {
                                Text(kid.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.warmTextPrimary)
                                Text("\(kid.ageYears) yrs old · ages \(max(0, kid.ageYears - 1))–\(kid.ageYears + 1) programs")
                                    .font(.system(size: 11.5))
                                    .foregroundStyle(.warmTextTertiary)
                            }
                            Spacer(minLength: 0)
                            checkbox(on: on, color: kid.avatarColor)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .background(Color.warmCard, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(brown: 0.06), lineWidth: 0.5)
                        )
                        .overlay(alignment: .leading) {
                            if on {
                                Rectangle().fill(kid.avatarColor)
                                    .frame(width: 3)
                                    .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .bottomLeft]))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var agesSection: some View {
        @Bindable var store = store
        return Section_(
            label: "Ages",
            subtitle: store.filters.ageMode == .kids ? "Auto-fit from selected kids" : "Manual override"
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    modeButton(label: "Use kids' ages", on: store.filters.ageMode == .kids) {
                        store.filters.ageMode = .kids
                    }
                    modeButton(label: "Manual range", on: store.filters.ageMode == .manual) {
                        store.filters.ageMode = .manual
                    }
                }
                .padding(.horizontal, 16)

                if store.filters.ageMode == .kids {
                    if store.selectedKids.isEmpty {
                        Text("Pick a kid above first.")
                            .font(.system(size: 12))
                            .foregroundStyle(.warmTextFaint)
                            .padding(.horizontal, 24)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(store.selectedKids) { kid in
                                kidAgeWindow(kid: kid)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                } else {
                    manualAgeRange
                        .padding(.horizontal, 24)
                }
            }
        }
    }

    private func modeButton(label: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7).padding(.horizontal, 8)
                .foregroundStyle(on ? Color.warmTextPrimary : .warmTextMuted)
                .background(on ? Color.warmCard : .clear, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(on ? Color.warmTextPrimary : Color(brown: 0.12),
                                lineWidth: on ? 1.5 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func kidAgeWindow(kid: Kid) -> some View {
        HStack(spacing: 10) {
            Text(kid.initial)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(kid.avatarColor, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text("\(kid.name)'s window")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.warmTextPrimary)
                GeometryReader { geo in
                    let total = max(geo.size.width, 1)
                    let leftPct = max(0, Double(kid.ageYears - 1) / 18)
                    let widthPct = 2.0 / 18.0
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(brown: 0.10))
                            .frame(height: 4)
                        Capsule()
                            .fill(kid.avatarColor)
                            .frame(width: total * widthPct, height: 4)
                            .offset(x: total * leftPct)
                    }
                }
                .frame(height: 4)
            }
            Text("\(max(0, kid.ageYears - 1))–\(kid.ageYears + 1)y")
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
                .foregroundStyle(.warmTextSecondary)
        }
    }

    private var manualAgeRange: some View {
        @Bindable var store = store
        return VStack(spacing: 8) {
            HStack {
                Text("Min")
                    .font(.system(size: 13))
                Spacer()
                TextField("any", value: $store.filters.ageMinMonths, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 13).monospacedDigit())
                Text("mo").font(.system(size: 11)).foregroundStyle(.warmTextFaint)
            }
            HStack {
                Text("Max")
                    .font(.system(size: 13))
                Spacer()
                TextField("any", value: $store.filters.ageMaxMonths, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 13).monospacedDigit())
                Text("mo").font(.system(size: 11)).foregroundStyle(.warmTextFaint)
            }
        }
    }

    private var distanceSection: some View {
        @Bindable var store = store
        let value = Binding<Double>(
            get: { store.filters.maxDistanceMiles ?? 25 },
            set: { v in
                store.filters.maxDistanceMiles = v >= 25 ? nil : v
            }
        )
        return Section_(label: "Distance") {
            VStack(spacing: 8) {
                HStack {
                    Text("Within ")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.warmTextPrimary)
                    + Text(store.filters.maxDistanceMiles == nil ? "any"
                           : "\(Int(store.filters.maxDistanceMiles!))")
                        .font(.system(size: 14, weight: .semibold).monospacedDigit())
                        .foregroundStyle(.warmTextPrimary)
                    + Text(" mi")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.warmTextPrimary)
                    Spacer()
                }
                Slider(value: value, in: 1...25, step: 1)
                    .tint(.terracotta)
                HStack {
                    Text("1").font(.system(size: 10).monospacedDigit())
                    Spacer()
                    Text("5").font(.system(size: 10).monospacedDigit())
                    Spacer()
                    Text("10").font(.system(size: 10).monospacedDigit())
                    Spacer()
                    Text("25+").font(.system(size: 10).monospacedDigit())
                }
                .foregroundStyle(.warmTextFaint)
            }
            .padding(.horizontal, 24)
        }
    }

    private var daysSection: some View {
        @Bindable var store = store
        return Section_(label: "Days") {
            HStack(spacing: 6) {
                ForEach(ActivityFilters.DayOfWeek.allCases, id: \.self) { day in
                    let on = store.filters.daysOfWeek.contains(day)
                    Button {
                        if on { store.filters.daysOfWeek.remove(day) }
                        else { store.filters.daysOfWeek.insert(day) }
                    } label: {
                        Text(day.letter)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(on ? Color.white : .warmTextSecondary)
                            .frame(width: 38, height: 38)
                            .background(on ? Color.warmTextPrimary : Color.warmCard,
                                        in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(on ? Color.clear : Color(brown: 0.12), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var priceSection: some View {
        @Bindable var store = store
        return Section_(label: "Price") {
            FlowLayout(spacing: 6) {
                ForEach(ActivityFilters.PriceFilter.allCases, id: \.self) { p in
                    let on = store.filters.priceFilter == p
                    Button {
                        store.filters.priceFilter = p
                    } label: {
                        Text(p.label)
                            .font(.system(size: 12.5, weight: .semibold))
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .foregroundStyle(on ? Color.white : .warmTextSecondary)
                            .background(on ? Color.warmTextPrimary : Color.warmCard, in: Capsule())
                            .overlay(
                                Capsule().stroke(on ? Color.clear : Color(brown: 0.12), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var registrationSection: some View {
        @Bindable var store = store
        return Section_(label: "Registration") {
            HStack(spacing: 6) {
                ForEach(ActivityFilters.RegistrationFilter.allCases, id: \.self) { r in
                    let on = store.filters.registrationFilter == r
                    Button {
                        store.filters.registrationFilter = r
                    } label: {
                        Text(r.label)
                            .font(.system(size: 12.5, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8).padding(.horizontal, 10)
                            .foregroundStyle(on ? Color.warmTextPrimary : .warmTextMuted)
                            .background(on ? Color.warmCard : .clear,
                                        in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(on ? Color.warmTextPrimary : Color(brown: 0.12),
                                            lineWidth: on ? 1.5 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var venueTypeSection: some View {
        @Bindable var store = store
        return Section_(label: "Venue type", subtitle: "Where the activity happens") {
            VStack(spacing: 4) {
                ForEach(VenueType.allCases, id: \.self) { type in
                    let on = store.filters.venueTypes.contains(type)
                    Button {
                        if on { store.filters.venueTypes.remove(type) }
                        else  { store.filters.venueTypes.insert(type) }
                    } label: {
                        HStack(spacing: 12) {
                            checkbox(on: on, color: .terracotta)
                            Text(type.label)
                                .font(.system(size: 14.5))
                                .foregroundStyle(.warmTextPrimary)
                            Spacer(minLength: 0)
                            Text("\(store.activities.filter { $0.venueType == type }.count)")
                                .font(.system(size: 12).monospacedDigit())
                                .foregroundStyle(.warmTextFaint)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .background(Color.warmCard, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(brown: 0.06), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var categoriesSection: some View {
        @Bindable var store = store
        return Section_(label: "Category") {
            FlowLayout(spacing: 6) {
                ForEach(ActivityCategory.allCases, id: \.self) { cat in
                    let on = store.filters.categories.contains(cat)
                    Button {
                        if on { store.filters.categories.remove(cat) }
                        else  { store.filters.categories.insert(cat) }
                    } label: {
                        HStack(spacing: 5) {
                            Circle().fill(cat.style.dot).opacity(on ? 1 : 0.5).frame(width: 8, height: 8)
                            Text(cat.label)
                                .font(.system(size: 12.5, weight: .semibold))
                        }
                        .padding(.horizontal, 11).padding(.vertical, 7)
                        .foregroundStyle(on ? cat.style.chipFG : .warmTextSecondary)
                        .background(on ? cat.style.chipBG : Color.warmCard, in: Capsule())
                        .overlay(
                            Capsule().stroke(on ? cat.style.border : Color(brown: 0.12),
                                             lineWidth: on ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Apply CTA

    private var applyCTA: some View {
        let count = store.filteredActivities.count
        return VStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("Show \(count) result\(count == 1 ? "" : "s")")
                    .font(.system(size: 16, weight: .bold))
                    .kerning(-0.2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(Color.terracotta, in: RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.oklch(0.6, 0.15, 22).opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .background(
                LinearGradient(
                    colors: [Color.warmCanvas.opacity(0), .warmCanvas],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 100)
                .allowsHitTesting(false)
            )
        }
    }

    // MARK: - Shared bits

    private func checkbox(on: Bool, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(on ? AnyShapeStyle(color) : AnyShapeStyle(Color.warmCard))
                .frame(width: 20, height: 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(on ? Color.clear : Color(brown: 0.25), lineWidth: 1.5)
                )
            if on {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Section header layout

private struct Section_<Content: View>: View {
    let label: String
    var subtitle: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(.warmTextFaint)
                    .textCase(.uppercase)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.warmTextMuted)
                }
            }
            .padding(.horizontal, 20)

            content()
        }
        .padding(.bottom, 18)
    }
}

// MARK: - Flow layout for chip rows

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let result = arrange(width: width, subviews: subviews)
        return CGSize(width: result.width, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (i, frame) in result.frames.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                              proposal: ProposedViewSize(frame.size))
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (frames: [CGRect], width: CGFloat, height: CGFloat) {
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (frames, width, y + rowHeight)
    }
}
