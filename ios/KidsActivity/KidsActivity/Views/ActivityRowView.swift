import SwiftUI

struct ActivityRowView: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: activity.venueType.symbol)
                    .foregroundStyle(.secondary)
                    .imageScale(.small)
                Text(activity.name)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                Text(activity.price.displayPrice)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                Text(activity.venueName)
                Text("•")
                Text(activity.ageRange.displayAge)
                if activity.registration.isOpen == true {
                    Text("•")
                    Text("Open")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if !activity.schedule.weeklyTimes.isEmpty {
                Text(Formatters.weeklyTimes(activity.schedule.weeklyTimes))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else if let raw = activity.schedule.rawScheduleText {
                Text(raw)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}
