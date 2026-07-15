//
//  MapTab.swift
//  IOSApp
//
import SwiftUI
import MapKit

struct MapTab: View {
    @EnvironmentObject var statsVM: StatsVM
    @EnvironmentObject var locationService: LocationService

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    @State private var liveCamera: MapCamera?

    // Filters — reuses StatsDateRange from StatsTab.swift so "7 Days" means
    // the same thing on both screens.
    @State private var modeFilter: MapFilterOption = .all
    @State private var dateRange: StatsDateRange = .allTime

    // Tapping a pin opens a detail sheet instead of only showing the floating label.
    @State private var selectedSession: GameSession?

    private var filteredSessions: [GameSession] {
        statsVM.sessions.filter { session in
            let matchesMode: Bool
            switch modeFilter {
            case .all: matchesMode = true
            case .mode(let m): matchesMode = session.mode == m
            }
            return matchesMode && dateRange.contains(session.timestamp)
        }
    }

    private var bestSession: GameSession? {
        filteredSessions.max(by: { $0.score < $1.score })
    }

    var body: some View {
        ZStack {
            Map(position: $position) {
                ForEach(filteredSessions) { session in
                    Annotation(session.mode.rawValue, coordinate: getJitteredCoordinate(for: session)) {
                        pinView(for: session)
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedSession = session
                            }
                    }
                }
            }
            .onMapCameraChange(frequency: .continuous) { context in
                liveCamera = context.camera
            }
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 8) {
                filterBar
                if filteredSessions.isEmpty {
                    emptyState
                }
                Spacer()
            }

            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    legendCard
                    Spacer()
                    controlsStack
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
        .navigationTitle("Activity Map")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSession) { session in
            sessionDetailSheet(session)
        }
    }

    // MARK: - Filter Bar

    var filterBar: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    modeChip(.all, label: "All", color: AppTheme.brand)
                    ForEach(GameMode.allCases) { mode in
                        modeChip(.mode(mode), label: mode.shortLabel, color: mode.themeColor)
                    }
                }
                .padding(.horizontal)
            }

            SegmentedFilterBar(
                options: StatsDateRange.allCases,
                selection: $dateRange,
                label: { $0.rawValue }
            )
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    func modeChip(_ option: MapFilterOption, label: String, color: Color) -> some View {
        let isSelected = modeFilter == option
        return Button {
            withAnimation(.spring(response: 0.3)) { modeFilter = option }
        } label: {
            HStack(spacing: 6) {
                if case .mode = option {
                    Circle().fill(color).frame(width: 8, height: 8)
                }
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color.white.opacity(0.06))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? Color.clear : AppTheme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: - Legend / Summary Card

    var legendCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(filteredSessions.count) \(filteredSessions.count == 1 ? "session" : "sessions")")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            if let best = bestSession {
                HStack(spacing: 6) {
                    Circle().fill(best.mode.themeColor).frame(width: 8, height: 8)
                    Text("Best: \(best.score) pts")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(AppTheme.radiusButton)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusButton)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Empty State

    var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 26))
                .foregroundColor(AppTheme.textMuted)
            Text("No sessions match these filters")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(.ultraThinMaterial)
        .cornerRadius(AppTheme.radiusCard)
        .padding(.horizontal, 40)
    }

    // MARK: - Pin

    func pinView(for session: GameSession) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(session.mode.rawValue.uppercased())
                    .font(.system(size: 10, weight: .black))

                Text("\(session.score) pts")
                    .font(.system(size: 14, weight: .bold))

                Text(session.timestamp.formatted(date: .numeric, time: .shortened))
                    .font(.system(size: 9))
                    .opacity(0.9)
            }
            .padding(8)
            .background(session.mode.themeColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.3), radius: 5, y: 5)

            Image(systemName: "triangle.fill")
                .font(.caption2)
                .foregroundColor(session.mode.themeColor)
                .rotationEffect(.degrees(180))
                .offset(y: -2)
        }
    }

    // MARK: - Controls (recenter + zoom)

    var controlsStack: some View {
        VStack(spacing: 10) {
            Button { recenterOnUser() } label: {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.brand)
            }
            Divider().frame(width: 24)
            Button { zoom(by: 0.5) } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(AppTheme.textPrimary)
            }
            Button { zoom(by: 2.0) } label: {
                Image(systemName: "minus")
                    .font(.title2)
                    .foregroundColor(AppTheme.textPrimary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(AppTheme.radiusButton)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusButton)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
        .buttonStyle(PressableStyle())
    }

    // MARK: - Session Detail Sheet

    @ViewBuilder
    func sessionDetailSheet(_ session: GameSession) -> some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(AppTheme.cardBorderStrong)
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(session.mode.themeColor.opacity(0.18)).frame(width: 50, height: 50)
                    Image(systemName: session.mode.icon)
                        .foregroundColor(session.mode.themeColor)
                        .font(.system(size: 20, weight: .bold))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.mode.rawValue)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(session.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textMuted)
                }
                Spacer()
            }

            HStack(spacing: 12) {
                detailPill(title: "Score", value: "\(session.score)")
                if let detail = session.detailText {
                    detailPill(title: "Details", value: detail)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .presentationDetents([.height(220)])
        .background(AppTheme.background.ignoresSafeArea())
    }

    func detailPill(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial.opacity(0.5))
        .cornerRadius(AppTheme.radiusButton - 4)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusButton - 4)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func getJitteredCoordinate(for session: GameSession) -> CLLocationCoordinate2D {
        let seed = abs(session.id.hashValue)
        let latOffset = (Double(seed % 1000) - 500) / 100_000.0
        let lonOffset = (Double((seed / 1000) % 1000) - 500) / 100_000.0
        return CLLocationCoordinate2D(
            latitude: session.latitude + latOffset,
            longitude: session.longitude + lonOffset
        )
    }

    private func zoom(by factor: Double) {
        guard let camera = liveCamera else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            position = .camera(
                MapCamera(
                    centerCoordinate: camera.centerCoordinate,
                    distance: camera.distance * factor,
                    heading: camera.heading,
                    pitch: camera.pitch
                )
            )
        }
    }

    private func recenterOnUser() {
        locationService.fetchLocation()
        let coordinate = CLLocationCoordinate2D(
            latitude: locationService.latitude,
            longitude: locationService.longitude
        )
        // Guards against snapping to (0,0) before a first fix has ever arrived.
        guard coordinate.latitude != 0 || coordinate.longitude != 0 else { return }
        withAnimation(.easeInOut(duration: 0.6)) {
            position = .region(
                MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            )
        }
    }
}

enum MapFilterOption: Hashable {
    case all
    case mode(GameMode)
}

#Preview {
    NavigationStack {
        MapTab()
            .environmentObject(StatsVM())
            .environmentObject(LocationService())
    }
}
