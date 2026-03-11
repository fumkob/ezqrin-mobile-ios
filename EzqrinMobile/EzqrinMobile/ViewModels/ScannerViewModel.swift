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
    var event: Event
    var toastState: ToastState = .hidden
    var isProcessing = false

    private let checkInService: any CheckInServiceProtocol
    private let eventService: any EventServiceProtocol
    private var dismissTask: Task<Void, Never>?

    init(
        event: Event,
        checkInService: any CheckInServiceProtocol,
        eventService: any EventServiceProtocol
    ) {
        self.event = event
        self.checkInService = checkInService
        self.eventService = eventService
    }

    func handleScannedCode(_ code: String) async {
        guard !isProcessing else { return }
        isProcessing = true

        do {
            let response = try await checkInService.checkIn(eventId: event.id, qrCode: code)
            showToast(.success(response.participant.name))
            await refreshEvent()
        } catch let error as APIError where error.isAlreadyCheckedIn {
            showToast(.alreadyCheckedIn)
        } catch {
            showToast(.error(error.localizedDescription))
        }

        isProcessing = false
    }

    private func refreshEvent() async {
        if let updated = try? await eventService.getEvent(eventId: event.id) {
            event = updated
        }
    }

    private func showToast(_ state: ToastState) {
        dismissTask?.cancel()
        toastState = state

        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            self?.toastState = .hidden
        }
    }
}
