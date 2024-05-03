import Foundation

protocol AuthorisedNetworkClient {
    func performRequest<T: Decodable>(
        _ endpoint: APIEndpoint,
        method: RequestMethod,
        body: Data?
    ) async throws -> T
}

protocol NetworkClient {
    func performRequest<T: Decodable>(
        _ endpoint: APIEndpoint,
        method: RequestMethod,
        headers: [String: String],
        body: Data?
    ) async throws -> T
}

@globalActor actor URLSessionAPIClient: NetworkClient, AuthorisedNetworkClient {
    static let shared = URLSessionAPIClient()
    
    private var authManager: AuthTokenManager!
    private let session: URLSession
    private let baseURL: URL
    private let jsonDecoder: JSONDecoder
    
    init(session: URLSession = .shared, baseURL: URL = APIEndpoint.baseURL, jsonDecoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.baseURL = baseURL
        self.jsonDecoder = jsonDecoder
    }
    
    func setup() async {
        configureJSONDecoder()
        self.authManager = await .init(AuthenticationUseCase(), initialToken: .initial)
    }
    
    func performRequest<T: Decodable>(
        _ endpoint: APIEndpoint,
        method: RequestMethod,
        headers: [String: String],
        body: Data? = nil
    ) async throws -> T {
        guard let url = URL(string: endpoint.path, relativeTo: baseURL) else {
            throw ClientError.invalidURL
        }
        
        let request = request(url, method: method, headers: headers, body: body)
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClientError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 403 {
                    await authManager.invalidateToken()
                    return try await performRequest(endpoint, method: method, body: body)
                } else {
                    throw ClientError.invalidResponse
                }
            }
            
            let decodedResponse = try jsonDecoder.decode(T.self, from: data)
            return decodedResponse
        } catch let error as DecodingError {
            throw ClientError.decodingError(error)
        } catch {
            throw ClientError.requestFailed(error)
        }
    }
    
    func performRequest<T>(
        _ endpoint: APIEndpoint,
        method: RequestMethod,
        body: Data?
    ) async throws -> T where T : Decodable {
        let token = try await authManager.validToken()
        let headers = ["Authorization": token.bearerAccessToken]
        return try await performRequest(endpoint, method: method, headers: headers, body: body)
    }
    
}

private extension URLSessionAPIClient {
    private func request(_ url: URL,  method: RequestMethod, headers: [String: String], body: Data?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        headers.forEach { request.addValue($1, forHTTPHeaderField: $0) }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }
    
    private func configureJSONDecoder() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
    }
}

extension URLSessionAPIClient {
    enum ClientError: Error {
        case invalidURL
        case requestFailed(Error)
        case invalidResponse
        case decodingError(Error)
    }
}
