import Foundation

struct EventListResponse: Codable, Sendable {
    let data: [Event]
    let meta: PaginationMeta
}

struct Event: Codable, Sendable, Identifiable {
    let id: String
    let organizerId: String
    let name: String
    let description: String?
    let startDate: String
    let endDate: String?
    let location: String?
    let status: String
    let participantCount: Int?
    let checkedInCount: Int?
}

struct PaginationMeta: Codable, Sendable {
    let page: Int
    let perPage: Int
    let total: Int
    let totalPages: Int
}

enum EventStatus: String, Codable, Sendable {
    case draft, published, ongoing, completed, cancelled
}
