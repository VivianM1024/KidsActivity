import SwiftUI

/// Pulsing rectangle for loading skeletons. Mirrors `Bone` from
/// `v5-loading.jsx`. Animated via `TimelineView` so the pulse keeps
/// running without a stored phase.
struct Bone: View {
    var width: CGFloat?
    var height: CGFloat = 12
    var radius: CGFloat = 6

    var body: some View {
        TimelineView(.animation) { context in
            let phase = context.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 1.4) / 1.4
            let opacity = 0.55 + 0.30 * (sin(phase * 2 * .pi) * 0.5 + 0.5)
            RoundedRectangle(cornerRadius: radius)
                .fill(Color(brown: 0.08))
                .opacity(opacity)
                .frame(width: width, height: height)
        }
    }
}

/// Browse skeleton — title, search, chip rail, sort row, 6 row skeletons.
struct BrowseSkeletonView: View {
    var body: some View {
        ZStack(alignment: .top) {
            Color.warmCanvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        Bone(width: 140, height: 11)
                        Bone(width: 240, height: 28)
                    }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 6)

                    VStack(alignment: .leading, spacing: 8) {
                        Bone(height: 38, radius: 12)
                        HStack(spacing: 6) {
                            Bone(width: 28, height: 11)
                            Bone(width: 86, height: 26, radius: 100)
                            Bone(width: 86, height: 26, radius: 100)
                            Bone(width: 86, height: 26, radius: 100)
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 8)

                    HStack(spacing: 6) {
                        ForEach([60, 70, 80, 60, 90], id: \.self) { w in
                            Bone(width: CGFloat(w), height: 28, radius: 100)
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 8)

                    HStack {
                        Bone(width: 70, height: 12)
                        Spacer()
                        Bone(width: 150, height: 26, radius: 8)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 6)

                    VStack(spacing: 6) {
                        ForEach(0..<6, id: \.self) { _ in skelRow }
                    }
                    .padding(.horizontal, 14)
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var skelRow: some View {
        HStack(alignment: .top, spacing: 10) {
            Bone(width: 40, height: 40, radius: 9)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Bone(width: nil, height: 14)
                    Bone(width: 40, height: 14)
                }
                Bone(width: nil, height: 11)
                HStack(spacing: 4) {
                    Bone(width: 50, height: 14, radius: 4)
                    Bone(width: 40, height: 14, radius: 4)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .warmCard()
    }
}

/// Calendar skeleton — title, month grid, three day groups with skeleton events.
struct CalendarSkeletonView: View {
    var body: some View {
        ZStack(alignment: .top) {
            Color.warmCanvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Bone(width: 100, height: 11)
                            Bone(width: 170, height: 28)
                        }
                        Spacer()
                        Bone(width: 70, height: 26, radius: 8)
                    }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 8)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
                              spacing: 4) {
                        ForEach(0..<35, id: \.self) { _ in
                            Bone(height: 32, radius: 8)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .warmCard(radius: 14)
                    .padding(.horizontal, 16).padding(.top, 8)

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(0..<3, id: \.self) { i in dayBlock(double: i == 0) }
                    }
                    .padding(.horizontal, 16).padding(.top, 12)
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func dayBlock(double: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Bone(width: 28, height: 22)
                Bone(width: 70, height: 13)
            }
            VStack(spacing: 6) {
                skelEvent
                if double { skelEvent }
            }
        }
    }

    private var skelEvent: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .trailing, spacing: 3) {
                Bone(width: 42, height: 13)
                Bone(width: 28, height: 9)
            }.frame(width: 56, alignment: .trailing).padding(.top, 10)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Bone(width: 18, height: 18, radius: 9)
                    Bone(width: 50, height: 11, radius: 4)
                    Bone(width: nil, height: 13)
                }
                Bone(width: nil, height: 11)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .warmCard()
        }
    }
}

/// Stale-data banner shown above the Browse list when offline.
/// Triggered by the host view when network is down. V1 wires this from
/// `ActivityStore.state == .error(...)` falling back to cached data.
struct CachedBanner: View {
    var lastUpdated: String  // e.g. "2 hours ago"
    var onRetry: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "icloud.slash.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.amberWarn)
                .frame(width: 24, height: 24)
                .background(Color.warmCard, in: Circle())
                .overlay(Circle().stroke(Color.amberWarn, lineWidth: 1))

            VStack(alignment: .leading, spacing: 1) {
                Text("Showing cached results")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.amberWarnInk)
                Text("last updated \(lastUpdated)")
                    .font(.system(size: 11))
                    .foregroundStyle(.warmTextTertiary)
            }

            Spacer(minLength: 0)

            Button(action: onRetry) {
                Text("Retry")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.amberWarnInk)
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(Color.warmCard, in: Capsule())
                    .overlay(Capsule().stroke(Color.amberWarn, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(Color.amberWarnSoft, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.amberWarn, lineWidth: 0.5)
        )
    }
}
