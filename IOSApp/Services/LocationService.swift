//
//  LocationService.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-08.
//

import Foundation
import CoreLocation
import Combine

// We use NSObject and CLLocationManagerDelegate to listen for GPS updates from Apple's hardware
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    
    override init() {
        super.init()
        manager.delegate = self
        // Best practice: Don't drain the battery, we only need a rough location for a high score
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    // Call this when the app launches to ask for permission
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    // Call this right when a game ends to get the exact location
    func fetchLocation() {
        manager.requestLocation()
    }
    
    // MARK: - Delegate Methods
    
    // This triggers automatically when the GPS hardware finds the phone
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        DispatchQueue.main.async {
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
        }
    }
    
    // Required fail-safe in case the user is in a tunnel or has no signal
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}
