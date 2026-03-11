import SwiftUI

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(ServiceContainer.self) private var services
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
            EventListView(
                eventService: services.eventService,
                onEventSelected: { event in selectedEvent = event }
            )
            .navigationDestination(item: $selectedEvent) { event in
                ScannerView(
                    event: event,
                    checkInService: services.checkInService,
                    eventService: services.eventService
                )
            }
        }
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
        .environment(ServiceContainer())
}
#endif
