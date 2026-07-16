//
//  LocationService.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-08.
//

import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0

    /// True once we've received at least one real GPS fix this app session.
    /// Callers should check this before trusting latitude/longitude — a
    /// value of (0,0) with hasFix == false means "no location yet," not
    /// "the user is at 0,0 in the Gulf of Guinea."
    @Published var hasFix: Bool = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func fetchLocation() {
        manager.requestLocation()
    }

    /// Calls back with a coordinate once a real fix is available. If one is
    /// already cached, returns immediately; otherwise waits (briefly) for
    /// the delegate to deliver one, so callers never save (0,0) by mistake.
    func awaitLocation(timeout: TimeInterval = 3.0, completion: @escaping (Double, Double) -> Void) {
        if hasFix {
            completion(latitude, longitude)
            return
        }

        fetchLocation()

        var didComplete = false
        let cancellable = $hasFix
            .filter { $0 }
            .first()
            .sink { _ in
                guard !didComplete else { return }
                didComplete = true
                completion(self.latitude, self.longitude)
            }

        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            guard !didComplete else { return }
            didComplete = true
            cancellable.cancel()
            // Still no fix after timeout — report whatever we have (may be
            // 0,0) rather than hang the game-over screen indefinitely.
            completion(self.latitude, self.longitude)
        }
    }

    // MARK: - Delegate Methods

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        DispatchQueue.main.async {
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
            self.hasFix = true
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }

    /// Re-requests a fix automatically the moment permission is actually
    /// granted, instead of only trying once at app launch before the user
    /// has necessarily responded to the system prompt yet.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            fetchLocation()
        }
    }
}
