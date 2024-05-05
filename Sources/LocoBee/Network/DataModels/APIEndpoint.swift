import Foundation

enum APIEndpoint {
    case authenticate
    case refreshToken
    case sendLocation
        
    var path: String {
        switch self {
        case .authenticate:
            return "auth"
        case .refreshToken:
            return "auth/refresh"
        case .sendLocation:
            return "location"
        }
    }
    
    static let baseURL = URL(string: "https://dummy-api-mobile.api.sandbox.bird.one/")!
}

enum RequestMethod: String {
    case get = "GET"
    case post = "POST"
}
