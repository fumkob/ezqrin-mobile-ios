import Foundation

protocol EventServiceProtocol: Sendable {
    func listEvents(page: Int, perPage: Int) async throws -> EventListResponse
}

struct EventService: EventServiceProtocol {
    let client: APIClient

    func listEvents(page: Int = 1, perPage: Int = 50) async throws -> EventListResponse {
        try await client.get("/events", query: [
            "page": "\(page)",
            "per_page": "\(perPage)",
        ])
    }
}
