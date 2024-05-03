import Foundation

struct Token: Decodable {
    let accessToken: String
    let expiresAt: Date
    let refreshToken: String
    var invalidateToken = false
}

extension Token {
    var isValid: Bool {
        !invalidateToken && Date() < expiresAt
    }
    
    var isAuthenticated: Bool {
        !refreshToken.isEmpty
    }
    
    var bearerAccessToken: String {
        bearer(accessToken)
    }
    
    var bearerRefreshToken: String {
        bearer(refreshToken)
    }
    
    private func bearer(_ key: String) -> String{
        "Bearer \(key)"
    }
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
