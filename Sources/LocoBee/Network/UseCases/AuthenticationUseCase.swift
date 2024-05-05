import Foundation

protocol AuthenticationNetworkClient {
    func authenticate(_ token: TokenData) async throws -> TokenData
    func refreshToken(_ token: TokenData) async throws -> TokenData
}

struct AuthenticationUseCase: AuthenticationNetworkClient {
    private let client: NetworkClient
    
    init(client: NetworkClient = URLSessionAPIClient.shared) {
        self.client = client
    }
    
    func authenticate(_ token: TokenData) async throws -> TokenData {
        let headers = ["Authorization": token.bearerAccessToken]
        return TokenData(token: try await client.performRequest(.authenticate, method: .post, headers: headers, body: nil))
    }
    
    func refreshToken(_ token: TokenData) async throws -> TokenData {
        let headers = ["Authorization": token.bearerRefreshToken]
        let refresh: RefreshTokenData = try await client.performRequest(.refreshToken, method: .post, headers: headers, body: nil)
        return TokenData(token: Token(accessToken: refresh.accessToken, expiresAt: refresh.expiresAt, refreshToken: token.refreshToken))
    }
}

