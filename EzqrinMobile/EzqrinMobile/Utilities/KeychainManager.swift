import Foundation
import Security

struct KeychainManager: Sendable {
    let service: String

    init(service: String = "com.ezqrin.mobile") {
        self.service = service
    }

    func save(key: String, data: Data) throws {
        var query = makeBaseQuery(key: key)
        query[kSecValueData as String] = data

        let updateStatus = SecItemUpdate(makeBaseQuery(key: key) as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if updateStatus == errSecItemNotFound {
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.saveFailed(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw KeychainError.saveFailed(updateStatus)
        }
    }

    func get(key: String) throws -> Data? {
        var query = makeBaseQuery(key: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.readFailed(status)
        }
    }

    func delete(key: String) throws {
        let status = SecItemDelete(makeBaseQuery(key: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    private func makeBaseQuery(key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }

    // MARK: - Convenience Methods (String)

    func saveString(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        try save(key: key, data: data)
    }

    func getString(forKey key: String) throws -> String? {
        guard let data = try get(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case readFailed(OSStatus)
    case deleteFailed(OSStatus)
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status): "Keychain save failed: \(status)"
        case .readFailed(let status): "Keychain read failed: \(status)"
        case .deleteFailed(let status): "Keychain delete failed: \(status)"
        case .encodingFailed: "Failed to encode string to data"
        }
    }
}
