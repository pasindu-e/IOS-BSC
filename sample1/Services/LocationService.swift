//
//  LocationService.swift
//  sample1
//

import CoreLocation
import Observation

@Observable
final class LocationService {
    var lastLocation: CLLocation?

    private let coordinator: Coordinator

    init() {
        coordinator = Coordinator()
        coordinator.service = self
    }

    func requestPermission() {
        coordinator.manager.requestWhenInUseAuthorization()
    }

    // NSObject subclass handles CLLocationManagerDelegate so LocationService
    // doesn't need to inherit from NSObject (which blocks @Observable).
    final class Coordinator: NSObject, CLLocationManagerDelegate {
        let manager = CLLocationManager()
        weak var service: LocationService?

        override init() {
            super.init()
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        }

        nonisolated func locationManager(_ manager: CLLocationManager,
                                         didUpdateLocations locations: [CLLocation]) {
            guard let loc = locations.last else { return }
            Task { @MainActor in self.service?.lastLocation = loc }
        }

        nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            let status = manager.authorizationStatus
            Task { @MainActor in
                if status == .authorizedWhenInUse || status == .authorizedAlways {
                    self.manager.startUpdatingLocation()
                }
            }
        }
    }
}
