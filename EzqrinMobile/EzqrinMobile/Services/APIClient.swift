import Alamofire
import Foundation

final class APIClient: @unchecked Sendable {
    let session: Session
    let baseURL: String
    let decoder: JSONDecoder
    let encoder: JSONEncoder

    init(baseURL: String, interceptor: RequestInterceptor? = nil) {
        self.baseURL = baseURL

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase

        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase

        self.session = Session(interceptor: interceptor)
    }

    func post<Req: Encodable, Res: Decodable>(
        _ path: String,
        body: Req,
        authenticated: Bool = true
    ) async throws -> Res {
        var urlRequest = try URLRequest(url: baseURL + path, method: .post)
        urlRequest.httpBody = try encoder.encode(body)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !authenticated {
            urlRequest.setValue("true", forHTTPHeaderField: "X-Skip-Auth")
        }
        return try await perform(urlRequest)
    }

    func postVoid(_ path: String, authenticated: Bool = true) async throws {
        var urlRequest = try URLRequest(url: baseURL + path, method: .post)
        if !authenticated {
            urlRequest.setValue("true", forHTTPHeaderField: "X-Skip-Auth")
        }
        let _ = try await session.request(urlRequest).validate().serializingData().value
    }

    func get<Res: Decodable>(
        _ path: String,
        query: [String: String]? = nil,
        authenticated: Bool = true
    ) async throws -> Res {
        var components = URLComponents(string: baseURL + path)!
        if let query {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        var urlRequest = try URLRequest(url: components.url!, method: .get)
        if !authenticated {
            urlRequest.setValue("true", forHTTPHeaderField: "X-Skip-Auth")
        }
        return try await perform(urlRequest)
    }

    private func perform<Res: Decodable>(_ urlRequest: URLRequest) async throws -> Res {
        let response = await session.request(urlRequest)
            .validate()
            .serializingData()
            .response

        switch response.result {
        case .success(let data):
            do {
                return try decoder.decode(Res.self, from: data)
            } catch {
                throw APIError.decodingFailed(error)
            }
        case .failure(let afError):
            if let data = response.data,
               let problem = try? decoder.decode(ProblemDetails.self, from: data) {
                throw APIError.server(problem)
            }
            throw APIError.network(afError)
        }
    }
}
