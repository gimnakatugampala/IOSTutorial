//
//  MapTab.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-08.
//
import SwiftUI
import MapKit

struct MapTab: View {
    @EnvironmentObject var statsVM: StatsVM
    
    // 1. Controls what the map is looking at
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    // 2. Tracks the exact, real-time camera data from the rendering engine
    @State private var liveCamera: MapCamera?
    
    var body: some View {
        Map(position: $position) {
            ForEach(statsVM.sessions) { session in
                Marker("\(session.score) pts", coordinate: CLLocationCoordinate2D(latitude: session.latitude, longitude: session.longitude))
                    .tint(colorFor(mode: session.mode))
            }
        }
        // 3. Constantly updates our liveCamera variable whenever the map renders or moves
        .onMapCameraChange(frequency: .continuous) { context in
            liveCamera = context.camera
        }
        .overlay(alignment: .bottomTrailing) {
            VStack(spacing: 10) {
                Button { zoom(by: 0.5) } label: { Image(systemName: "plus.circle.fill").font(.title) }
                Button { zoom(by: 2.0) } label: { Image(systemName: "minus.circle.fill").font(.title) }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .padding()
        }
        .navigationTitle("Activity Map")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func colorFor(mode: GameMode) -> Color {
        switch mode {
        case .tapFrenzy: return .purple
        case .lightItUp: return .orange
        case .quizRush: return .cyan
        }
    }
    
    // 4. Now we use the guaranteed liveCamera to calculate the new zoom!
    private func zoom(by factor: Double) {
        // If we don't have a live camera yet, do nothing
        guard let camera = liveCamera else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            // Force the map position to update using the live camera's distance
            position = .camera(
                MapCamera(
                    centerCoordinate: camera.centerCoordinate,
                    distance: camera.distance * factor, // Multiply or divide the altitude
                    heading: camera.heading,
                    pitch: camera.pitch
                )
            )
        }
    }
}
