//
//  LocationManager.swift
//  PSI
//
//  Created by OpenAI Codex on 14/05/26.
//

import CoreLocation
import Observation

@MainActor
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    @ObservationIgnored private let manager = CLLocationManager()

    var authorizationStatus: CLAuthorizationStatus
    var userCoordinate: CLLocationCoordinate2D?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestWhenInUseAuthorization() {
        guard authorizationStatus == .notDetermined else {
            if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
                manager.requestLocation()
            }
            return
        }

        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else { return }
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userCoordinate = locations.last?.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        #if DEBUG
        print("Location update failed: \(error.localizedDescription)")
        #endif
    }
}
