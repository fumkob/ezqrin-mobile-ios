import Foundation

struct ProblemDetails: Codable, Sendable {
    let type: String?
    let title: String?
    let status: Int?
    let detail: String?
    let instance: String?
    let code: String?
}
