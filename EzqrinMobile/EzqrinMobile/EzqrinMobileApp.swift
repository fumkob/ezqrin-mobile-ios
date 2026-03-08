import SwiftUI

@main
struct EzqrinMobileApp: App {
    @State private var authViewModel: AuthViewModel
    private let serviceContainer: ServiceContainer

    init() {
        let container = ServiceContainer()
        self.serviceContainer = container
        _authViewModel = State(initialValue: AuthViewModel(
            authService: container.authService,
            keychainManager: container.keychainManager
        ))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    MainTabView()
                        .environment(serviceContainer)
                } else {
                    LoginView()
                }
            }
            .environment(authViewModel)
        }
    }
}

@Observable
final class ServiceContainer {
    let keychainManager: KeychainManager
    let apiClient: APIClient
    let authService: AuthService
    let eventService: EventService
    let checkInService: CheckInService

    init() {
        let keychain = KeychainManager()
        let interceptor = AuthInterceptor(
            keychainManager: keychain,
            baseURL: AppConfig.baseURL
        )
        let client = APIClient(baseURL: AppConfig.baseURL, interceptor: interceptor)

        self.keychainManager = keychain
        self.apiClient = client
        self.authService = AuthService(client: client)
        self.eventService = EventService(client: client)
        self.checkInService = CheckInService(client: client)
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
