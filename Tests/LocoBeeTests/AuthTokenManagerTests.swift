import XCTest
@testable import LocoBee

final class AuthTokenManagerTests: XCTestCase {

    private var mockNetworkClient: MockAuthenticationNetworkClient!
    private var authTokenManager: AuthTokenManager!
    private var initialToken: Token!
    
    @URLSessionAPIClient 
    override func setUp() {
        super.setUp()
        mockNetworkClient = MockAuthenticationNetworkClient()
        initialToken = .initial
        authTokenManager = AuthTokenManager(
            mockNetworkClient,
            initialToken: Token(
                accessToken: "initialAccessToken",
                expiresAt: Date().addingTimeInterval(5),
                refreshToken: ""
            )
        )
    }
    
    override func tearDown() {
        mockNetworkClient = nil
        authTokenManager = nil
        initialToken = nil
        super.tearDown()
    }
    
    func testValidToken_ShouldAuthenticate_WhenNotAuthenticated() async throws {
        mockNetworkClient.shouldThrowAuthenticateError = false
        
        let result = try await authTokenManager.validToken()
        
        XCTAssertEqual(result.token.accessToken, "newAccessToken")
        XCTAssertEqual(result.token.refreshToken, "newRefreshToken")
    }
    
    func testValidToken_ShouldRefresh_WhenTokenIsInvalid() async throws {
        mockNetworkClient.shouldThrowRefreshError = false
        
        _ = try await authTokenManager.validToken()
        await authTokenManager.invalidateToken()
        let result2 = try await authTokenManager.validToken()

        XCTAssertEqual(result2.token.accessToken, "refreshedAccessToken")
        XCTAssertEqual(result2.token.refreshToken, "refreshedRefreshToken")
    }
    
    func testValidToken_ShouldReturnSameToken_WhenAlreadyAuthenticatedAndValid() async throws {
        let result = try await authTokenManager.validToken()
        
        XCTAssertEqual(result.token.accessToken, "newAccessToken")
        XCTAssertEqual(result.token.refreshToken, "newRefreshToken")
    }
    
    func testValidToken_ShouldThrowError_WhenAuthenticateFails() async {
        mockNetworkClient.shouldThrowAuthenticateError = true
        
        do {
            _ = try await authTokenManager.validToken()
            XCTFail("Expected an error to be thrown")
        } catch _ as URLSessionAPIClient.ClientError {
            XCTAssert(true, "Correct error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testValidToken_ShouldThrowError_WhenRefreshFails() async {
        mockNetworkClient.shouldThrowRefreshError = true
        
        do {
            _ = try await authTokenManager.validToken()
            await authTokenManager.invalidateToken()
            _ = try await authTokenManager.validToken()
            XCTFail("Expected an error to be thrown")
        } catch _ as URLSessionAPIClient.ClientError {
            XCTAssert(true, "Correct error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testInvalidateToken() async throws {
        _ = try await authTokenManager.validToken()
        await authTokenManager.invalidateToken()
        let result = try await authTokenManager.validToken()
        XCTAssertEqual(result.token.accessToken, "refreshedAccessToken")
        XCTAssertEqual(result.token.refreshToken, "refreshedRefreshToken")
    }
}

class MockAuthenticationNetworkClient: AuthenticationNetworkClient {
    var shouldThrowAuthenticateError = false
    var shouldThrowRefreshError = false
    
    func authenticate(_ token: TokenData) async throws -> TokenData {
        if shouldThrowAuthenticateError {
            throw URLSessionAPIClient.ClientError.invalidResponse
        }
        return TokenData(token: .init(accessToken: "newAccessToken", expiresAt: Date().addingTimeInterval(5), refreshToken: "newRefreshToken"))
    }
    
    func refreshToken(_ token: TokenData) async throws -> TokenData {
        if shouldThrowRefreshError {
            throw URLSessionAPIClient.ClientError.invalidResponse
        }
        return TokenData(token: .init(accessToken: "refreshedAccessToken", expiresAt: Date().addingTimeInterval(5), refreshToken: "refreshedRefreshToken"))
    }
}
