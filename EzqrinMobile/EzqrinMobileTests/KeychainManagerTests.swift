import Foundation
import Testing
@testable import EzqrinMobile

struct KeychainManagerTests {
    let manager = KeychainManager(service: "com.ezqrin.mobile.test")

    @Test func saveAndRetrieve() throws {
        try manager.save(key: "testKey", data: "testValue".data(using: .utf8)!)
        let result = try manager.get(key: "testKey")
        #expect(result == "testValue".data(using: .utf8)!)
        try manager.delete(key: "testKey")
    }

    @Test func getReturnsNilForMissingKey() throws {
        let result = try manager.get(key: "nonexistent_key_\(UUID().uuidString)")
        #expect(result == nil)
    }

    @Test func deleteRemovesValue() throws {
        try manager.save(key: "deleteMe", data: "value".data(using: .utf8)!)
        try manager.delete(key: "deleteMe")
        let result = try manager.get(key: "deleteMe")
        #expect(result == nil)
    }

    @Test func saveOverwritesExistingValue() throws {
        try manager.save(key: "overwrite", data: "first".data(using: .utf8)!)
        try manager.save(key: "overwrite", data: "second".data(using: .utf8)!)
        let result = try manager.get(key: "overwrite")
        #expect(result == "second".data(using: .utf8)!)
        try manager.delete(key: "overwrite")
    }
}
