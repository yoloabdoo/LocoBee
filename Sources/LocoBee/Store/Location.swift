import Foundation
import CoreLocation

struct Location {
    let latitude: Double
    let longitude: Double
    var date = Date()
    
    init(latitude: Double, longitude: Double, date: Date = Date()) {
        self.latitude = latitude
        self.longitude = longitude
        self.date = date
    }
}

extension Location {
    init(_ location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
    }
}
