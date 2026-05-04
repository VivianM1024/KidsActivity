import SwiftUI

struct OnboardingAvailabilityStep: View {
    @Binding var availability: Set<ActivityFilters.DayOfWeek>
    @Environment(ActivityStore.self) private var store

    private let weekdays: [ActivityFilters.DayOfWeek] = [.mon, .tue, .wed, .thu, .fri]
    private let weekends: [ActivityFilters.DayOfWeek] = [.sat, .sun]

    // Order shown in the grid: Mon Tue Wed Thu Fri Sat Sun (matches the
    // FilterSheet days row).
    private let displayOrder: [ActivityFilters.DayOfWeek] =
        [.mon, .tue, .wed, .thu, .fri, .sat, .sun]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHero(
                eyebrow: "Step 3",
                title: "When are you free?",
                subtitle: subtitle
            )

            VStack(spacing: 12) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    ForEach(displayOrder, id: \.self) { day in
                        dayButton(day)
                    }
                }

                presetRow
                    .padding(.top, 4)

                summaryCard
                    .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Spacer(minLength: 0)
        }
    }

    private var subtitle: String {
        let names = store.kids.map(\.name).filter { !$0.isEmpty }
        switch names.count {
        case 0:  return "Days you'd realistically take the kids to something."
        case 1:  return "Days you'd realistically take \(names[0]) to something."
        default: return "Days you'd realistically take the kids to something."
        }
    }

    private var presetRow: some View {
        HStack(spacing: 6) {
            preset("Weekdays", days: Set(weekdays))
            preset("Weekends", days: Set(weekends))
            preset("Any day", days: Set(displayOrder))
        }
    }

    private func preset(_ label: String, days: Set<ActivityFilters.DayOfWeek>) -> some View {
        Button {
            availability = days
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.warmTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.warmCard, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(brown: 0.10), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    /// Day pill: 1:1.1 aspect, letter on top + 3-letter day name below.
    /// Terracotta-filled when on, warm-card with hairline border when off.
    private func dayButton(_ day: ActivityFilters.DayOfWeek) -> some View {
        let isOn = availability.contains(day)
        return Button {
            if isOn { availability.remove(day) } else { availability.insert(day) }
        } label: {
            VStack(spacing: 1) {
                Text(day.letter)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.4)
                    .textCase(.uppercase)
                    .opacity(isOn ? 0.85 : 0.6)
                Text(day.short)
                    .font(.system(size: 13, weight: .semibold))
                    .kerning(-0.1)
            }
            .foregroundStyle(isOn ? .white : .warmTextPrimary)
            .frame(maxWidth: .infinity)
            .aspectRatio(1.0/1.1, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isOn ? Color.terracotta : Color.warmCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(brown: 0.10), lineWidth: isOn ? 0 : 0.5)
            )
            .shadow(color: isOn ? Color.terracotta.opacity(0.18) : Color(brown: 0.04),
                    radius: isOn ? 6 : 1, y: isOn ? 4 : 1)
        }
        .buttonStyle(.plain)
    }

    /// "You'll see {summary}" — collapses common patterns into friendly labels.
    private var summaryCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.oklch(0.45, 0.13, 22))
                .frame(width: 28, height: 28)
                .background(Color.oklch(0.94, 0.06, 22), in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text("YOU'LL SEE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(.warmTextFaint)
                Text(summaryLabel)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.warmTextPrimary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard()
    }

    private var summaryLabel: String {
        let selected = displayOrder.filter { availability.contains($0) }
        if selected.isEmpty { return "Pick at least one day" }
        if selected.count == 7 { return "Any day of the week" }
        if Set(selected) == Set(weekends) { return "Weekends" }
        if Set(selected) == Set(weekdays) { return "Weekdays" }
        return selected.map(\.short).joined(separator: ", ")
    }
}
