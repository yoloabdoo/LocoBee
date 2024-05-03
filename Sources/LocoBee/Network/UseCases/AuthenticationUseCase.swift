import Foundation

protocol AuthenticationNetworkClient {
    func authenticate(_ token: Token) async throws -> Token
    func refreshToken(_ token: Token) async throws -> Token
}

struct AuthenticationUseCase: AuthenticationNetworkClient {
    private let client: NetworkClient
    
    init(client: NetworkClient = URLSessionAPIClient.shared) {
        self.client = client
    }
    
    func authenticate(_ token: Token) async throws -> Token {
        let headers = ["Authorization": token.bearerAccessToken]
        return try await client.performRequest(.authenticate, method: .post, headers: headers, body: nil)
    }
    
    func refreshToken(_ token: Token) async throws -> Token {
        let headers = ["Authorization": token.bearerRefreshToken]
        let refresh: RefreshTokenData = try await client.performRequest(.refreshToken, method: .post, headers: headers, body: nil)
        return .init(accessToken: refresh.accessToken, expiresAt: refresh.expiresAt, refreshToken: token.refreshToken)
    }
}

