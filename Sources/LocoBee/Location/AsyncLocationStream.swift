import Foundation
import CoreLocation
import Combine

public protocol LocationManagerProtocol {
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func requestAlwaysAuthorization()
    var delegate: CLLocationManagerDelegate? { get set }
}

extension CLLocationManager: LocationManagerProtocol {}

class AsyncLocationStream: NSObject, CLLocationManagerDelegate {
    let stream: AsyncStream<CLLocation>
    
    private let continuation: AsyncStream<CLLocation>.Continuation
    private var locationManager: LocationManagerProtocol
    private var userAuthorizationStatus: UserAuthorization = .notDetermined
    
    init(_ locationManager: LocationManagerProtocol = CLLocationManager()) {
        let (stream, continuation) = AsyncStream.makeStream(of: CLLocation.self)
        self.stream = stream
        self.continuation = continuation
        self.locationManager = locationManager
        super.init()
        self.locationManager.delegate = self
    }
    
    func requestAuthorization() -> Bool {
        if userAuthorizationStatus != .authorizedAlways {
            locationManager.requestAlwaysAuthorization()
            return false
        }
        return true
    }
    
    func startUpdatingLocation() throws {
        if requestAuthorization() {
            locationManager.startUpdatingLocation()
        } else {
            throw LocationError.locationAccessNotAuthorized
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        continuation.finish()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            continuation.yield(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        continuation.finish()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            userAuthorizationStatus = .authorizedAlways
        case .authorizedWhenInUse:
            userAuthorizationStatus = .authorizedWhenInUse
        case .denied:
            userAuthorizationStatus = .denied
        case .restricted:
            userAuthorizationStatus = .restricted
        case .notDetermined:
            userAuthorizationStatus = .notDetermined
        @unknown default:
            break
        }
    }
    
    enum UserAuthorization {
        case authorizedAlways, authorizedWhenInUse
        case denied, restricted
        case notDetermined
    }
    
    enum LocationError: Error {
        case locationAccessNotAuthorized
    }
}
