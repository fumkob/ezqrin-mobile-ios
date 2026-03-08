import Foundation
import UIKit

protocol CheckInServiceProtocol: Sendable {
    func checkIn(eventId: String, qrCode: String) async throws -> CheckInResponse
}

struct CheckInService: CheckInServiceProtocol {
    let client: APIClient

    func checkIn(eventId: String, qrCode: String) async throws -> CheckInResponse {
        let device = await UIDevice.current
        let request = CheckInRequest(
            method: "qrcode",
            qrCode: qrCode,
            deviceInfo: [
                "device_type": "mobile",
                "os": "iOS",
                "os_version": await device.systemVersion,
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
                "device_model": await device.model,
            ]
        )
        return try await client.post("/events/\(eventId)/checkin", body: request)
    }
}
