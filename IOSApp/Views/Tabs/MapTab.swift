//
//  MapTab.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-08.
//

import SwiftUI
import MapKit

struct MapTab: View {
    // Default starting position (we will update this with user location later)
    @State private var position: MapCameraPosition = .automatic
    
    var body: some View {
        // Native iOS Map Component
        Map(position: $position) {
            // We will loop through your GameSession array here
            // Example of what the pin will look like:
            // Marker("Tap Frenzy - 150 pts", coordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612))
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .navigationTitle("Activity Map")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MapTab()
    }
}
