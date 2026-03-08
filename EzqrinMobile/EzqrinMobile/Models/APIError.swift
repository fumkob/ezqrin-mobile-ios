import Alamofire
import Foundation

struct ProblemDetails: Codable, Sendable {
    let type: String?
    let title: String?
    let status: Int?
    let detail: String?
    let instance: String?
    let code: String?
}

enum APIError: Error, LocalizedError {
    case server(ProblemDetails)
    case network(AFError)
    case decodingFailed(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .server(let problem):
            problem.detail ?? problem.title ?? "Server error"
        case .network(let error):
            error.localizedDescription
        case .decodingFailed(let error):
            "Decoding failed: \(error.localizedDescription)"
        case .unknown:
            "Unknown error occurred"
        }
    }

    var isAlreadyCheckedIn: Bool {
        if case .server(let problem) = self, problem.status == 409 {
            return true
        }
        return false
    }
}
