import SwiftUI

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var selectedEvent: Event?
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Scan", systemImage: "qrcode.viewfinder", value: 0) {
                scanTab
            }
            Tab("Settings", systemImage: "gearshape", value: 1) {
                SettingsView()
            }
        }
    }

    @ViewBuilder
    private var scanTab: some View {
        NavigationStack {
            if let event = selectedEvent {
                ScannerView(
                    event: event,
                    checkInService: makeCheckInService(),
                    onChangeEvent: { selectedEvent = nil }
                )
                .navigationBarHidden(true)
            } else {
                EventListView(
                    eventService: makeEventService(),
                    onEventSelected: { event in
                        selectedEvent = event
                    }
                )
            }
        }
    }

    // MARK: - Service Factory

    private func makeAPIClient() -> APIClient {
        let keychainManager = KeychainManager()
        let interceptor = AuthInterceptor(
            keychainManager: keychainManager,
            baseURL: AppConfig.baseURL
        )
        return APIClient(baseURL: AppConfig.baseURL, interceptor: interceptor)
    }

    private func makeEventService() -> EventService {
        EventService(client: makeAPIClient())
    }

    private func makeCheckInService() -> CheckInService {
        CheckInService(client: makeAPIClient())
    }
}

#if DEBUG
private final class PreviewAuthServiceForMain: AuthServiceProtocol, @unchecked Sendable {
    func login(email: String, password: String) async throws -> AuthResponse { throw APIError.unknown }
    func logout() async throws {}
}

#Preview {
    let vm = AuthViewModel(
        authService: PreviewAuthServiceForMain(),
        keychainManager: KeychainManager()
    )
    MainTabView()
        .environment(vm)
}
#endif
