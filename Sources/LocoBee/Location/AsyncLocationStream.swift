import Combine
import CoreLocation
import Foundation

protocol LocationManagerProtocol {
    var delegate: CLLocationManagerDelegate? { get set }

    func startUpdatingLocation()
    func stopUpdatingLocation()

    #if os(iOS) || os(tvOS)
        func requestWhenInUseAuthorization()
        func requestAlwaysAuthorization()
    #endif
}

extension CLLocationManager: LocationManagerProtocol {}

@available(macOS 10.15, iOS 13, *)
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

    #if os(iOS) || os(tvOS)
    func requestAuthorization() -> Bool {
        if userAuthorizationStatus != .authorizedAlways {
            locationManager.requestAlwaysAuthorization()
            return false
        }
        return true
    }
    #endif
    
    func startUpdatingLocation() throws {
        #if os(iOS) || os(tvOS)
            if requestAuthorization() {
                locationManager.startUpdatingLocation()
            } else {
                throw LocationError.locationAccessNotAuthorized
            }
        #else
            locationManager.startUpdatingLocation()
        #endif
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
