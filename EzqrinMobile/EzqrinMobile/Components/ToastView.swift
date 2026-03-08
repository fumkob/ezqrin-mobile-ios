import SwiftUI

struct ToastView: View {
    let state: ToastState

    var body: some View {
        switch state {
        case .hidden:
            EmptyView()
        case .success(let name):
            toastContent(
                icon: "checkmark.circle.fill",
                text: "\(name) checked in",
                color: .app.success
            )
        case .alreadyCheckedIn:
            toastContent(
                icon: "exclamationmark.circle.fill",
                text: "Already checked in",
                color: .app.warning
            )
        case .error(let message):
            toastContent(
                icon: "xmark.circle.fill",
                text: message,
                color: .app.destructive
            )
        }
    }

    private func toastContent(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
            Text(text)
                .font(.body.weight(.medium))
            Spacer()
        }
        .foregroundStyle(.white)
        .padding()
        .background(color.gradient, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#if DEBUG
#Preview("Success") {
    ToastView(state: .success("Jane Smith"))
        .padding(.top)
    Spacer()
}

#Preview("Already Checked In") {
    ToastView(state: .alreadyCheckedIn)
        .padding(.top)
}

#Preview("Error") {
    ToastView(state: .error("QR code not recognized"))
        .padding(.top)
}
#endif
