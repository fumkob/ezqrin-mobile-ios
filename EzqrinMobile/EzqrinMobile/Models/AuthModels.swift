import Foundation

struct LoginRequest: Codable, Sendable {
    let email: String
    let password: String
}

struct RefreshTokenRequest: Codable, Sendable {
    let refreshToken: String
}

struct AuthResponse: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
    let user: User
}

struct LogoutResponse: Codable, Sendable {
    let message: String
}

struct User: Codable, Sendable, Identifiable {
    let id: String
    let email: String
    let name: String
    let role: String
    let createdAt: String?
    let updatedAt: String?
}
