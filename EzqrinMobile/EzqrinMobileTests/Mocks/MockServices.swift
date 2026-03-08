import Foundation
@testable import EzqrinMobile

final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    var loginResult: Result<AuthResponse, Error> = .failure(MockError.notConfigured)
    var logoutResult: Result<Void, Error> = .success(())
    var loginCallCount = 0

    func login(email: String, password: String) async throws -> AuthResponse {
        loginCallCount += 1
        return try loginResult.get()
    }

    func logout() async throws {
        try logoutResult.get()
    }
}

final class MockEventService: EventServiceProtocol, @unchecked Sendable {
    var listEventsResult: Result<EventListResponse, Error> = .failure(MockError.notConfigured)

    func listEvents(page: Int, perPage: Int) async throws -> EventListResponse {
        try listEventsResult.get()
    }
}

final class MockCheckInService: CheckInServiceProtocol, @unchecked Sendable {
    var checkInResult: Result<CheckInResponse, Error> = .failure(MockError.notConfigured)
    var lastQrCode: String?

    func checkIn(eventId: String, qrCode: String) async throws -> CheckInResponse {
        lastQrCode = qrCode
        return try checkInResult.get()
    }
}

enum MockError: Error {
    case notConfigured
}

// MARK: - Test Data

enum TestData {
    static let user = User(
        id: "user-1",
        email: "test@example.com",
        name: "Test User",
        role: "organizer",
        createdAt: "2026-01-01T00:00:00Z",
        updatedAt: "2026-01-01T00:00:00Z"
    )

    static let authResponse = AuthResponse(
        accessToken: "test-access-token",
        refreshToken: "test-refresh-token",
        tokenType: "Bearer",
        expiresIn: 900,
        user: user
    )

    static let event = Event(
        id: "event-1",
        organizerId: "user-1",
        name: "Test Event",
        description: "A test event",
        startDate: "2026-03-15T09:00:00Z",
        endDate: "2026-03-15T18:00:00Z",
        location: "Tokyo",
        status: "published",
        participantCount: 100,
        checkedInCount: 25
    )

    static let eventListResponse = EventListResponse(
        data: [event],
        meta: PaginationMeta(page: 1, perPage: 50, total: 1, totalPages: 1)
    )

    static let checkInResponse = CheckInResponse(
        id: "checkin-1",
        eventId: "event-1",
        participantId: "participant-1",
        participant: CheckInParticipant(name: "Jane Smith", email: "jane@example.com"),
        checkedInAt: "2026-03-15T09:15:00Z",
        checkedInBy: CheckInOperator(id: "user-1", name: "Test User"),
        checkinMethod: "qrcode",
        message: "Participant successfully checked in"
    )
}
