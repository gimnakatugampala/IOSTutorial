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
    
    // Starting position
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    @State private var liveCamera: MapCamera?
    
    var body: some View {
        Map(position: $position) {
            ForEach(statsVM.sessions) { session in
                
                // 🚨 1. We now use our jittered coordinate function instead of the raw coordinates!
                Annotation(session.mode.rawValue, coordinate: getJitteredCoordinate(for: session)) {
                    
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
                        .background(colorFor(mode: session.mode))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.3), radius: 5, y: 5)
                        
                        Image(systemName: "triangle.fill")
                            .font(.caption2)
                            .foregroundColor(colorFor(mode: session.mode))
                            .rotationEffect(.degrees(180))
                            .offset(y: -2)
                    }
                }
            }
        }
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
    
    // MARK: - Helpers
    
    // Returns the correct color based on the game mode
    private func colorFor(mode: GameMode) -> Color {
        switch mode {
        case .tapFrenzy: return .purple
        case .lightItUp: return .orange
        case .quizRush: return .cyan
        }
    }
    
    // 🚨 2. The Jitter Logic
    private func getJitteredCoordinate(for session: GameSession) -> CLLocationCoordinate2D {
        // We use the unique ID of the session to generate a stable, deterministic random number.
        // This ensures the pins scatter randomly, but they don't "dance" around every time the screen redraws!
        let seed = abs(session.id.hashValue)
        
        // Creates a tiny offset (roughly 20-50 meters)
        let latOffset = (Double(seed % 1000) - 500) / 100_000.0
        let lonOffset = (Double((seed / 1000) % 1000) - 500) / 100_000.0
        
        return CLLocationCoordinate2D(
            latitude: session.latitude + latOffset,
            longitude: session.longitude + lonOffset
        )
    }
    
    // Zoom logic
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
}
