import Foundation

protocol AuthServiceProtocol: Sendable {
    func login(email: String, password: String) async throws -> AuthResponse
    func logout() async throws
}

struct AuthService: AuthServiceProtocol {
    let client: APIClient

    func login(email: String, password: String) async throws -> AuthResponse {
        try await client.post(
            "/auth/login",
            body: LoginRequest(email: email, password: password),
            authenticated: false
        )
    }

    func logout() async throws {
        try await client.postVoid("/auth/logout")
    }
}
