import Foundation


/**
 `AuthTokenManager` is responsible for managing authentication tokens.
 
 - The class interacts with an `AuthenticationNetworkClient` to authenticate or refresh tokens as needed.
 - It handles the following scenarios:
 - Initial authentication
 - Refreshing an expired or invalid token
 - Invalidation of tokens. */
@available(macOS 10.15, iOS 13, *)
@URLSessionAPIClient
class AuthTokenManager {
    enum AuthError: Error {
        case missingRefreshToken
    }
    
    private let network: AuthenticationNetworkClient
    private var currentToken: TokenData
    private var networkTask: Task<TokenData, Error>?
    
    init(_ network: AuthenticationNetworkClient, initialToken: Token) {
        self.network = network
        self.currentToken = TokenData(token: initialToken)
    }

    func validToken() async throws -> TokenData {
        if let task = networkTask {
            return try await task.value
        }

        guard currentToken.isAuthenticated else {
            currentToken = try await authenticate()
            return currentToken
        }
        
        guard currentToken.isValid else {
            currentToken = try await refreshToken()
            return currentToken
        }

        return currentToken
    }
    
    func invalidateToken() {
        currentToken.invalidateToken = true
    }
    
    private func authenticate() async throws -> TokenData {
        if let authTask = networkTask {
            return try await authTask.value
        }
        
        let task = Task { () throws -> TokenData in
            defer { networkTask = nil }
            return try await network.authenticate(currentToken)
        }
        
        networkTask = task
        return try await task.value
    }

    private func refreshToken() async throws -> TokenData {
        if let refreshTask = networkTask {
            return try await refreshTask.value
        }
        
        let task = Task { () throws -> TokenData in
            defer { networkTask = nil }
            guard !currentToken.refreshToken.isEmpty else {
                throw AuthError.missingRefreshToken
            }
            
            return try await network.refreshToken(currentToken)
        }
        
        networkTask = task
        return try await task.value
    }
}
