import Foundation

@URLSessionAPIClient
class AuthTokenManager {
    enum AuthError: Error {
        case missingToken
        case missingRefreshToken
    }
    
    private let network: AuthenticationNetworkClient
    private var currentToken: Token!
    private var refreshTask: Task<Token, Error>?
    private var authTask: Task<Token, Error>?
    
    init(_ network: AuthenticationNetworkClient, initialToken: Token) {
        self.network = network
        self.currentToken = initialToken
    }

    func validToken() async throws -> Token {
        if let handle = refreshTask {
            return try await handle.value
        }
        
        if let authTask = authTask {
            return try await authTask.value
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
    
    private func authenticate() async throws -> Token {
        if let authTask = authTask {
            return try await authTask.value
        }
        
        let task = Task { () throws -> Token in
            defer { authTask = nil }
            return try await network.authenticate(currentToken)
        }
        
        authTask = task
        return try await task.value
    }

    private func refreshToken() async throws -> Token {
        if let refreshTask = refreshTask {
            return try await refreshTask.value
        }
        
        let task = Task { () throws -> Token in
            defer { refreshTask = nil }
            guard !currentToken.refreshToken.isEmpty else {
                throw AuthError.missingRefreshToken
            }
            
            return try await network.refreshToken(currentToken)
        }
        
        self.refreshTask = task
        return try await task.value
    }
}
