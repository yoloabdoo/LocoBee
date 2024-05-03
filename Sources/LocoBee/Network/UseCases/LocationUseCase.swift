import Foundation

struct LocationUseCase {
    private let client: AuthorisedNetworkClient
    
    init(client: AuthorisedNetworkClient = URLSessionAPIClient.shared) {
        self.client = client
    }
    
    func updateLocation(latitude: Double, longitude: Double) async throws -> MessageResponse {
        let body: [String: Double] = ["latitude": latitude, "longitude": longitude]
        do {
            let bodyData = try JSONEncoder().encode(body)
            return try await client.performRequest(.sendLocation, method: .post, body: bodyData)
        } catch let error as EncodingError {
            throw UseCaseError.encodingError(error)
        }
    }
}
