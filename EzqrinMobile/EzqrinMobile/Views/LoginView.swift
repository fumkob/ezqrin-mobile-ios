import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case email, password
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Logo
                VStack(spacing: 8) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.accentColor)
                    Text("ezQRin")
                        .font(.largeTitle.bold())
                }

                // Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .padding()
                        .background(.fill.tertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .padding()
                        .background(.fill.tertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                // Error
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(Color.app.destructive)
                        .padding(.horizontal)
                }

                // Login button
                Button {
                    focusedField = nil
                    Task {
                        await authViewModel.login(email: email, password: password)
                    }
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Login")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("")
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = nil
            }
        }
    }
}

#if DEBUG
private final class PreviewAuthService: AuthServiceProtocol, @unchecked Sendable {
    func login(email: String, password: String) async throws -> AuthResponse {
        try await Task.sleep(nanoseconds: 500_000_000)
        throw APIError.unknown
    }
    func logout() async throws {}
}

#Preview("Default") {
    let vm = AuthViewModel(
        authService: PreviewAuthService(),
        keychainManager: KeychainManager()
    )
    LoginView()
        .environment(vm)
}

#Preview("With Error") {
    let vm = AuthViewModel(
        authService: PreviewAuthService(),
        keychainManager: KeychainManager()
    )
    vm.errorMessage = "Invalid email or password"
    return LoginView()
        .environment(vm)
}
#endif
