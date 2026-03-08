import SwiftUI

@main
struct EzqrinMobileApp: App {
    @State private var authViewModel: AuthViewModel

    init() {
        let keychainManager = KeychainManager()
        let interceptor = AuthInterceptor(
            keychainManager: keychainManager,
            baseURL: AppConfig.baseURL
        )
        let apiClient = APIClient(
            baseURL: AppConfig.baseURL,
            interceptor: interceptor
        )
        let authService = AuthService(client: apiClient)

        _authViewModel = State(initialValue: AuthViewModel(
            authService: authService,
            keychainManager: keychainManager
        ))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            .environment(authViewModel)
        }
    }
}

enum AppConfig {
    static let baseURL: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String else {
            fatalError("BASE_URL is not set in Info.plist")
        }
        return url
    }()
}
