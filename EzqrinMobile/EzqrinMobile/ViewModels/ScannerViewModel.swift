import Foundation
import Observation

enum ToastState: Equatable {
    case hidden
    case success(String) // participant name
    case alreadyCheckedIn
    case error(String)
}

@Observable
@MainActor
final class ScannerViewModel {
    var toastState: ToastState = .hidden
    var isProcessing = false

    private let checkInService: any CheckInServiceProtocol
    private let eventId: String
    private var dismissTask: Task<Void, Never>?

    init(checkInService: any CheckInServiceProtocol, eventId: String) {
        self.checkInService = checkInService
        self.eventId = eventId
    }

    func handleScannedCode(_ code: String) async {
        guard !isProcessing else { return }
        isProcessing = true

        do {
            let response = try await checkInService.checkIn(eventId: eventId, qrCode: code)
            showToast(.success(response.participant.name))
        } catch let error as APIError where error.isAlreadyCheckedIn {
            showToast(.alreadyCheckedIn)
        } catch let error as APIError {
            showToast(.error(error.localizedDescription))
        } catch {
            showToast(.error(error.localizedDescription))
        }

        isProcessing = false
    }

    private func showToast(_ state: ToastState) {
        dismissTask?.cancel()
        toastState = state

        dismissTask = Task {
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled {
                toastState = .hidden
            }
        }
    }
}
