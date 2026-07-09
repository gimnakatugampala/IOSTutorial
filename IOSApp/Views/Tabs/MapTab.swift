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
    
    // Starting position centered on Sri Lanka
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    var body: some View {
        Map(position: $position) {
            ForEach(statsVM.sessions) { session in
                Marker("\(session.score) pts", coordinate: CLLocationCoordinate2D(latitude: session.latitude, longitude: session.longitude))
                    .tint(colorFor(mode: session.mode))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            VStack(spacing: 10) {
                // Ensure there is no 'let' or 'var' inside these braces
                Button {
                    zoom(by: 0.5)
                } label: {
                    Image(systemName: "plus.circle.fill").font(.title)
                }
                
                Button {
                    zoom(by: 2.0)
                } label: {
                    Image(systemName: "minus.circle.fill").font(.title)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .padding()
        }
        .navigationTitle("Activity Map")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 🚨 THIS FUNCTION MUST BE INSIDE THE STRUCT 🚨
    private func colorFor(mode: GameMode) -> Color {
        switch mode {
        case .tapFrenzy: return .purple
        case .lightItUp: return .orange
        case .quizRush: return .cyan
        }
    }
    
    // 🚨 THIS FUNCTION MUST ALSO BE INSIDE THE STRUCT 🚨
    private func zoom(by factor: Double) {
        withAnimation {
            switch position {
            case .region(let region):
                let newSpan = MKCoordinateSpan(
                    latitudeDelta: region.span.latitudeDelta * factor,
                    longitudeDelta: region.span.longitudeDelta * factor
                )
                position = .region(MKCoordinateRegion(center: region.center, span: newSpan))
                
            case .camera(let camera):
                position = .camera(MapCamera(
                    centerCoordinate: camera.centerCoordinate,
                    distance: camera.distance * factor,
                    heading: camera.heading,
                    pitch: camera.pitch
                ))
            default:
                break
            }
        }
    }
}
