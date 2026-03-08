import Foundation
import Observation

@Observable
@MainActor
final class EventListViewModel {
    var events: [Event] = []
    var isLoading = false
    var errorMessage: String?

    private let eventService: any EventServiceProtocol

    init(eventService: any EventServiceProtocol) {
        self.eventService = eventService
    }

    func loadEvents() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await eventService.listEvents(page: 1, perPage: 50)
            events = response.data
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
