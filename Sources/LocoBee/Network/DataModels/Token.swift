import Foundation

struct Token: Decodable {
    let accessToken: String
    let expiresAt: Date
    let refreshToken: String
}

struct MessageResponse: Decodable {
    let message: String
}

extension Token {
    static let initialAccessToken = "xdk8ih3kvw2c66isndihzke5"
    
    static let initial = Token(
        accessToken: initialAccessToken,
        expiresAt: Date() - 1,
        refreshToken: ""
    )
}

struct RefreshTokenData: Decodable {
    let accessToken: String
    let expiresAt: Date
}
