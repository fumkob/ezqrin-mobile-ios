import Foundation
import Testing
@testable import EzqrinMobile

@MainActor
struct AuthViewModelTests {
    @Test func loginSuccess() async {
        let mockAuth = MockAuthService()
        mockAuth.loginResult = .success(TestData.authResponse)
        let keychain = KeychainManager(service: "com.ezqrin.mobile.test.\(UUID().uuidString)")
        let vm = AuthViewModel(authService: mockAuth, keychainManager: keychain)

        await vm.login(email: "test@example.com", password: "password")

        #expect(vm.isAuthenticated == true)
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)

        // Token is stored
        let token = try? keychain.getString(forKey: "access_token")
        #expect(token == "test-access-token")

        // cleanup
        try? keychain.delete(key: "access_token")
        try? keychain.delete(key: "refresh_token")
    }

    @Test func loginFailure() async {
        let mockAuth = MockAuthService()
        mockAuth.loginResult = .failure(APIError.server(ProblemDetails(
            type: nil, title: "Unauthorized", status: 401,
            detail: "Invalid email or password", instance: nil, code: "INVALID_CREDENTIALS"
        )))
        let keychain = KeychainManager(service: "com.ezqrin.mobile.test.\(UUID().uuidString)")
        let vm = AuthViewModel(authService: mockAuth, keychainManager: keychain)

        await vm.login(email: "test@example.com", password: "wrong")

        #expect(vm.isAuthenticated == false)
        #expect(vm.errorMessage != nil)
    }

    @Test func logoutClearsState() async {
        let mockAuth = MockAuthService()
        let keychain = KeychainManager(service: "com.ezqrin.mobile.test.\(UUID().uuidString)")
        try? keychain.saveString("token", forKey: "access_token")
        let vm = AuthViewModel(authService: mockAuth, keychainManager: keychain)
        vm.isAuthenticated = true

        await vm.logout()

        #expect(vm.isAuthenticated == false)
        let token = try? keychain.getString(forKey: "access_token")
        #expect(token == nil)
    }
}
