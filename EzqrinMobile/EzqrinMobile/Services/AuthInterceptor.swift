import Alamofire
import Foundation

extension Notification.Name {
    static let authSessionExpired = Notification.Name("authSessionExpired")
}

final class AuthInterceptor: RequestInterceptor, @unchecked Sendable {
    private let keychainManager: KeychainManager
    private let baseURL: String
    private let refreshSession: Session
    private let lock = NSLock()
    private var isRefreshing = false

    init(keychainManager: KeychainManager, baseURL: String) {
        self.keychainManager = keychainManager
        self.baseURL = baseURL
        self.refreshSession = Session()
    }

    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        var request = urlRequest

        // Skip authentication if X-Skip-Auth header is present
        if request.value(forHTTPHeaderField: "X-Skip-Auth") != nil {
            request.setValue(nil, forHTTPHeaderField: "X-Skip-Auth")
            completion(.success(request))
            return
        }

        if let token = try? keychainManager.getString(forKey: "access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        completion(.success(request))
    }

    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401 else {
            completion(.doNotRetry)
            return
        }

        // Do not retry requests that skipped authentication
        if request.request?.value(forHTTPHeaderField: "X-Skip-Auth") != nil {
            completion(.doNotRetry)
            return
        }

        lock.lock()
        guard !isRefreshing else {
            lock.unlock()
            completion(.retryWithDelay(0.5))
            return
        }
        isRefreshing = true
        lock.unlock()

        Task {
            defer {
                lock.lock()
                isRefreshing = false
                lock.unlock()
            }

            do {
                guard let refreshToken = try keychainManager.getString(forKey: "refresh_token") else {
                    notifySessionExpired()
                    completion(.doNotRetry)
                    return
                }

                let body = RefreshTokenRequest(refreshToken: refreshToken)
                let encoder = JSONEncoder()
                encoder.keyEncodingStrategy = .convertToSnakeCase
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase

                var urlRequest = try URLRequest(
                    url: baseURL + "/auth/refresh",
                    method: .post
                )
                urlRequest.httpBody = try encoder.encode(body)
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let data = try await refreshSession.request(urlRequest)
                    .validate()
                    .serializingData()
                    .value

                let authResponse = try decoder.decode(AuthResponse.self, from: data)
                try keychainManager.saveString(authResponse.accessToken, forKey: "access_token")
                try keychainManager.saveString(authResponse.refreshToken, forKey: "refresh_token")
                completion(.retry)
            } catch {
                try? keychainManager.delete(key: "access_token")
                try? keychainManager.delete(key: "refresh_token")
                notifySessionExpired()
                completion(.doNotRetry)
            }
        }
    }

    private func notifySessionExpired() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .authSessionExpired, object: nil)
        }
    }
}
