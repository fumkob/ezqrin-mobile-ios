import Foundation

protocol EventServiceProtocol: Sendable {
    func listEvents(page: Int, perPage: Int) async throws -> EventListResponse
    func getEvent(eventId: String) async throws -> Event
}

struct EventService: EventServiceProtocol {
    let client: APIClient

    func listEvents(page: Int = 1, perPage: Int = 50) async throws -> EventListResponse {
        try await client.get("/events", query: [
            "page": "\(page)",
            "per_page": "\(perPage)",
        ])
    }

    func getEvent(eventId: String) async throws -> Event {
        try await client.get("/events/\(eventId)")
    }
}
