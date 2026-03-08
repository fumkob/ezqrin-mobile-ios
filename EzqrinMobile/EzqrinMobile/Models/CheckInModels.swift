import Foundation

struct CheckInRequest: Codable, Sendable {
    let method: String
    let qrCode: String?
    let deviceInfo: [String: String]?
}

struct CheckInResponse: Codable, Sendable {
    let id: String
    let eventId: String
    let participantId: String
    let participant: CheckInParticipant
    let checkedInAt: String
    let checkedInBy: CheckInOperator
    let checkinMethod: String
    let message: String
}

struct CheckInParticipant: Codable, Sendable {
    let name: String
    let email: String
}

struct CheckInOperator: Codable, Sendable {
    let id: String
    let name: String
}

enum CheckInMethod: String, Codable, Sendable {
    case qrcode, manual
}
