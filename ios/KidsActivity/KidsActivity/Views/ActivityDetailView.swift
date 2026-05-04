import SwiftUI
import SafariServices

struct ActivityDetailView: View {
    let activity: Activity
    @Environment(ActivityStore.self) private var store
    @State private var showSafari = false

    private var category: ActivityCategory { activity.inferredCategory }
    private var status: ActivityStatus { ActivityStatus.compute(for: activity) }
    private var isSaved: Bool { store.savedActivityIds.contains(activity.activityId) }
    private var distance: Double? {
        Formatters.distanceMiles(home: store.homeCoordinate,
                                 venue: store.venueBySlug[activity.venueSlug])
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.warmCanvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroBand
                    hero
                    keyFacts
                        .padding(.horizontal, 16).padding(.bottom, 14)
                    statusBanner
                        .padding(.horizontal, 16).padding(.bottom, 14)

                    section("Schedule",
                            trailing: activity.kind == .series && activity.schedule.numSessions != nil
                                ? "\(activity.schedule.numSessions!) sessions" : nil) {
                        scheduleContent
                    }
                    section("Location") {
                        locationContent
                    }
                    if let desc = activity.description, !desc.isEmpty {
                        section("About") {
                            Text(desc)
                                .font(.system(size: 13))
                                .foregroundStyle(.warmTextSecondary)
                                .padding(.horizontal, 20)
                        }
                    }
                    section("Hosted by") {
                        hostCard
                    }
                    section("Original listing") {
                        sourceCard
                    }

                    Color.clear.frame(height: 120)
                }
            }
            .scrollIndicators(.hidden)

            ctaBar
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSafari) {
            SafariView(url: activity.sourceUrl).ignoresSafeArea()
        }
    }

    // MARK: - Hero

    private var heroBand: some View {
        ZStack {
            LinearGradient(
                colors: [category.style.swatchBG, category.style.swatchBG.opacity(0)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 160)
            .ignoresSafeArea(edges: .top)

            HStack {
                NavigationBackButton()
                Spacer()
                HStack(spacing: 8) {
                    SaveCircleButton(isSaved: isSaved) { store.toggleSaved(activity) }
                    ShareCircleButton(url: activity.sourceUrl)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 56)
        }
        .frame(height: 100)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle().fill(category.style.dot).frame(width: 6, height: 6)
                Text("\(category.label) · \(activity.venueType.label)")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(category.style.chipFG)
                    .textCase(.uppercase)
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(category.style.chipBG, in: RoundedRectangle(cornerRadius: 6))

            Text(activity.name)
                .font(.system(size: 26, weight: .bold))
                .kerning(-0.6)
                .foregroundStyle(.warmTextPrimary)
                .lineLimit(3)

            Text(subtitleText)
                .font(.system(size: 13.5))
                .foregroundStyle(.warmTextSecondary)
                .padding(.top, 2)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtitleText: String {
        switch activity.kind {
        case .series:
            let n = activity.schedule.numSessions ?? activity.schedule.weeklyTimes.count
            return "\(n)-week series · \(activity.venueName)"
        case .oneTime:
            return "One-time at \(activity.venueName)"
        }
    }

    // MARK: - Key facts

    private var keyFacts: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            fact("Ages", value: Formatters.ageRange(activity.ageRange), sub: nil)
            fact("Price", value: Formatters.price(activity.price),
                 sub: pricePerSessionSub)
            fact("When",
                 value: "\(Formatters.days(activity.dayLetters)) \(Formatters.firstTime(activity.schedule.weeklyTimes))"
                    .trimmingCharacters(in: .whitespaces),
                 sub: activity.schedule.startDate.map { "Starts \(Formatters.monthDay.string(from: $0))" })
            fact("Distance",
                 value: distance.map { String(format: "%.1f mi", $0) } ?? "—",
                 sub: distance == nil ? nil : "from home")
        }
        .padding(14)
        .background(Color.warmCard, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(brown: 0.06), lineWidth: 0.5)
        )
        .shadow(color: Color(brown: 0.04), radius: 1, y: 1)
    }

    private var pricePerSessionSub: String? {
        guard activity.kind == .series,
              let p = activity.lowestPrice, p > 0,
              let n = activity.schedule.numSessions, n > 1 else { return nil }
        return String(format: "$%.0f/session", p / Double(n))
    }

    private func fact(_ label: String, value: String, sub: String?) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.warmTextFaint)
                .textCase(.uppercase)
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 16, weight: .bold).monospacedDigit())
                .kerning(-0.2)
                .foregroundStyle(.warmTextPrimary)
                .padding(.top, 2)
            if let sub {
                Text(sub)
                    .font(.system(size: 11))
                    .foregroundStyle(.warmTextTertiary)
                    .padding(.top, 1)
            }
        }
    }

    // MARK: - Status banner

    private var statusBanner: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .overlay(
                    Group {
                        if case .open = status {
                            Circle().stroke(statusColor.opacity(0.2), lineWidth: 4)
                        }
                    }
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(statusHeadline)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.warmTextPrimary)
                Text(statusBody)
                    .font(.system(size: 13))
                    .foregroundStyle(.warmTextSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(statusBG, in: RoundedRectangle(cornerRadius: 12))
    }

    private var statusColor: Color {
        switch status {
        case .open, .dropIn: return .registeredGreen
        case .opensSoon:     return .opensSoonText
        case .full, .closed: return .warmTextTertiary
        }
    }

    private var statusBG: Color {
        switch status {
        case .open, .dropIn: return .registeredBg
        case .opensSoon:     return .opensSoonBg
        case .full, .closed: return Color(brown: 0.06)
        }
    }

    private var statusHeadline: String {
        switch status {
        case .open:          return "Registration is open"
        case .dropIn:        return "Drop-in"
        case .opensSoon:     return "Opens soon"
        case .full:          return "Full"
        case .closed:        return "Registration closed"
        }
    }

    private var statusBody: String {
        switch status {
        case .open:          return "Tap Register to head to the host site."
        case .dropIn:        return "No registration needed — just show up."
        case .opensSoon(let d):
            return "Opens \(Formatters.dayOnly.string(from: d))"
        case .full:          return "Try the waitlist or check the next session."
        case .closed:        return "Registration window has closed."
        }
    }

    // MARK: - Schedule

    private var scheduleContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if activity.kind == .series, let n = activity.schedule.numSessions, n > 1 {
                ForEach(Array(generatedSessions().prefix(3).enumerated()), id: \.offset) { idx, item in
                    HStack(spacing: 12) {
                        Text("\(idx + 1)")
                            .font(.system(size: 12, weight: .bold).monospacedDigit())
                            .foregroundStyle(category.style.chipFG)
                            .frame(width: 28, height: 28)
                            .background(category.style.chipBG, in: RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.dateLine)
                                .font(.system(size: 13.5, weight: .semibold))
                                .foregroundStyle(.warmTextPrimary)
                            Text(item.timeLine)
                                .font(.system(size: 12))
                                .foregroundStyle(.warmTextTertiary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .overlay(alignment: .top) {
                        if idx > 0 {
                            Rectangle().fill(Color(brown: 0.08)).frame(height: 0.5)
                        }
                    }
                }
                if n > 3 {
                    Text("+ \(n - 3) more weeks · same time")
                        .font(.system(size: 12.5))
                        .foregroundStyle(.warmTextMuted)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(alignment: .top) {
                            Rectangle().fill(Color(brown: 0.08)).frame(height: 0.5)
                        }
                }
            } else {
                Text("\(Formatters.days(activity.dayLetters)) · \(Formatters.firstTime(activity.schedule.weeklyTimes))"
                    .trimmingCharacters(in: .whitespaces))
                    .font(.system(size: 13.5))
                    .foregroundStyle(.warmTextPrimary)
                    .padding(.horizontal, 16).padding(.vertical, 10)
            }
        }
    }

    private struct SessionPreview {
        let dateLine: String
        let timeLine: String
    }

    private func generatedSessions() -> [SessionPreview] {
        guard let start = activity.schedule.startDate else { return [] }
        let cal = Calendar(identifier: .iso8601)
        let dayMap: [String: Int] = [
            "Sun": 1, "Mon": 2, "Tue": 3, "Wed": 4, "Thu": 5, "Fri": 6, "Sat": 7
        ]
        let weekly = activity.schedule.weeklyTimes
        var result: [SessionPreview] = []
        var cursor = start
        let maxDays = 60
        for _ in 0..<maxDays where result.count < 3 {
            let weekday = cal.component(.weekday, from: cursor)
            if let m = weekly.first(where: { dayMap[$0.dayOfWeek] == weekday }) {
                let line = "\(Formatters.weekdayLong.string(from: cursor).prefix(3)) \(Formatters.monthDay.string(from: cursor))"
                let time = "\(Formatters.firstTime([m]))"
                result.append(SessionPreview(dateLine: String(line), timeLine: time))
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }

    // MARK: - Location

    private var locationContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                LinearGradient(
                    colors: [Color.oklch(0.9, 0.04, 150), Color.oklch(0.86, 0.05, 200)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    Image(systemName: "mappin")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.terracotta)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(brown: 0.08), lineWidth: 0.5)
                )
            }
            Text(activity.venueName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.warmTextPrimary)
            Text(locationLine)
                .font(.system(size: 12.5))
                .foregroundStyle(.warmTextTertiary)
        }
        .padding(.horizontal, 16).padding(.bottom, 14)
    }

    private var locationLine: String {
        var parts: [String] = []
        if !activity.location.isEmpty { parts.append(activity.location) }
        if let m = Formatters.miles(distance) { parts.append("\(m) away") }
        return parts.isEmpty ? "—" : parts.joined(separator: " · ")
    }

    // MARK: - Host

    private var hostCard: some View {
        HStack(spacing: 12) {
            Text(initials(of: activity.venueName))
                .font(.system(size: 13, weight: .bold))
                .tracking(0.4)
                .foregroundStyle(.warmTextSecondary)
                .frame(width: 38, height: 38)
                .background(Color.oklch(0.85, 0.05, 60), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(activity.venueName)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.warmTextPrimary)
                Text(activity.venueType.label)
                    .font(.system(size: 12))
                    .foregroundStyle(.warmTextTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.warmCard, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(brown: 0.06), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
    }

    private var sourceCard: some View {
        Button {
            showSafari = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.warmTextSecondary)
                    .frame(width: 38, height: 38)
                    .background(Color(brown: 0.05), in: RoundedRectangle(cornerRadius: 9))
                VStack(alignment: .leading, spacing: 1) {
                    Text("View on \(activity.sourceUrl.host ?? "host site")")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(.warmTextPrimary)
                    Text(activity.sourceUrl.absoluteString)
                        .font(.system(size: 11.5).monospaced())
                        .foregroundStyle(.warmTextTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.warmTextFaint)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.warmCard, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(brown: 0.06), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    // MARK: - CTA

    private var ctaBar: some View {
        HStack(spacing: 10) {
            Button {
                store.toggleSaved(activity)
            } label: {
                Image(systemName: isSaved ? "heart.fill" : "heart")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSaved ? Color.terracotta : .warmTextPrimary)
                    .frame(width: 50, height: 50)
                    .background(Color.warmCard, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(brown: 0.12), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button {
                showSafari = true
            } label: {
                HStack(spacing: 8) {
                    VStack(spacing: 2) {
                        HStack(spacing: 6) {
                            Text(ctaTitle)
                                .font(.system(size: 16, weight: .bold))
                                .kerning(-0.2)
                            if let p = activity.lowestPrice, p > 0 {
                                Text("· $\(Int(p))")
                                    .font(.system(size: 13))
                                    .opacity(0.85)
                            } else if activity.lowestPrice == 0 {
                                Text("· Free")
                                    .font(.system(size: 13))
                                    .opacity(0.85)
                            }
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 11, weight: .semibold))
                                .opacity(0.85)
                        }
                        Text(activity.sourceUrl.host ?? "")
                            .font(.system(size: 10.5).monospaced())
                            .opacity(0.75)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .background(Color.terracotta, in: RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.oklch(0.6, 0.15, 22).opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
        .padding(.top, 12)
        .background(
            LinearGradient(
                colors: [Color.warmCanvas.opacity(0), .warmCanvas],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    private var ctaTitle: String {
        switch status {
        case .open, .dropIn:    return "Register"
        case .opensSoon:        return "Remind me"
        case .full:             return "Join waitlist"
        case .closed:           return "View listing"
        }
    }

    // MARK: -

    private func section<Content: View>(
        _ title: String, trailing: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(.warmTextFaint)
                    .textCase(.uppercase)
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundStyle(.warmTextFaint)
                }
            }
            .padding(.horizontal, 20)

            content()
        }
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func initials(of name: String) -> String {
        let words = name.split(separator: " ").prefix(3)
        return words.compactMap { $0.first.map(String.init) }.joined()
    }
}

// MARK: - Helper buttons

private struct NavigationBackButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.warmTextPrimary)
                .frame(width: 32, height: 32)
                .background(Color.warmCard.opacity(0.92), in: Circle())
                .overlay(Circle().stroke(Color(brown: 0.08), lineWidth: 0.5))
        }
    }
}

private struct SaveCircleButton: View {
    let isSaved: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isSaved ? "heart.fill" : "heart")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSaved ? Color.terracotta : .warmTextPrimary)
                .frame(width: 32, height: 32)
                .background(Color.warmCard.opacity(0.92), in: Circle())
                .overlay(Circle().stroke(Color(brown: 0.08), lineWidth: 0.5))
        }
    }
}

private struct ShareCircleButton: View {
    let url: URL
    var body: some View {
        ShareLink(item: url) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.warmTextPrimary)
                .frame(width: 32, height: 32)
                .background(Color.warmCard.opacity(0.92), in: Circle())
                .overlay(Circle().stroke(Color(brown: 0.08), lineWidth: 0.5))
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
