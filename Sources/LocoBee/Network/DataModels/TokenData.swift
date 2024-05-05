import Foundation

@dynamicMemberLookup
struct TokenData {
    var invalidateToken = false
    let token: Token
    
    subscript<Value>(dynamicMember keyPath: KeyPath<Token, Value>) -> Value {
        self.token[keyPath: keyPath]
    }
}

extension TokenData {
    var isValid: Bool {
        !invalidateToken && Date() < token.expiresAt
    }
    
    var isAuthenticated: Bool {
        !token.refreshToken.isEmpty
    }
    
    var bearerAccessToken: String {
        bearer(token.accessToken)
    }
    
    var bearerRefreshToken: String {
        bearer(token.refreshToken)
    }
    
    private func bearer(_ key: String) -> String{
        "Bearer \(key)"
    }
}
