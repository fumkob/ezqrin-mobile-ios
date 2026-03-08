import Foundation
import Observation

@Observable
@MainActor
final class AuthViewModel {
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?

    private let authService: any AuthServiceProtocol
    private let keychainManager: KeychainManager
    @ObservationIgnored nonisolated(unsafe) private var notificationTask: Task<Void, Never>?

    init(authService: any AuthServiceProtocol, keychainManager: KeychainManager) {
        self.authService = authService
        self.keychainManager = keychainManager

        // Consider authenticated if an existing token is present
        self.isAuthenticated = (try? keychainManager.getString(forKey: "access_token")) != nil

        // Observe for session expiry notifications
        notificationTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .authSessionExpired) {
                self?.handleSessionExpired()
            }
        }
    }

    deinit {
        notificationTask?.cancel()
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await authService.login(email: email, password: password)
            try keychainManager.saveString(response.accessToken, forKey: "access_token")
            try keychainManager.saveString(response.refreshToken, forKey: "refresh_token")
            isAuthenticated = true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() async {
        do {
            try await authService.logout()
        } catch {
            // Clear local session even if logout API fails
        }
        clearSession()
    }

    private func handleSessionExpired() {
        clearSession()
    }

    private func clearSession() {
        try? keychainManager.delete(key: "access_token")
        try? keychainManager.delete(key: "refresh_token")
        isAuthenticated = false
    }
}
