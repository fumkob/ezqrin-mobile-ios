import SwiftUI

struct SettingsView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(role: .destructive) {
                        Task {
                            await authViewModel.logout()
                        }
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#if DEBUG
private final class PreviewAuthServiceForSettings: AuthServiceProtocol, @unchecked Sendable {
    func login(email: String, password: String) async throws -> AuthResponse { throw APIError.unknown }
    func logout() async throws {}
}

#Preview {
    let vm = AuthViewModel(
        authService: PreviewAuthServiceForSettings(),
        keychainManager: KeychainManager()
    )
    SettingsView()
        .environment(vm)
}
#endif
