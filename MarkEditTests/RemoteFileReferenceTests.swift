import XCTest
@testable import MarkEdit

final class RemoteFileReferenceTests: XCTestCase {

    // MARK: - File Name

    func testFileNameFromPath() {
        let ref = RemoteFileReference(profileID: UUID(), remotePath: "/var/log/syslog.log")
        XCTAssertEqual(ref.fileName, "syslog.log")
    }

    func testFileNameFromRootFile() {
        let ref = RemoteFileReference(profileID: UUID(), remotePath: "/config.yaml")
        XCTAssertEqual(ref.fileName, "config.yaml")
    }

    func testFileNameFromDeepPath() {
        let ref = RemoteFileReference(profileID: UUID(), remotePath: "/home/user/.config/app/settings.json")
        XCTAssertEqual(ref.fileName, "settings.json")
    }

    // MARK: - File Extension

    func testFileExtensionYAML() {
        let ref = RemoteFileReference(profileID: UUID(), remotePath: "/etc/config.yaml")
        XCTAssertEqual(ref.fileExtension, "yaml")
    }

    func testFileExtensionJSON() {
        let ref = RemoteFileReference(profileID: UUID(), remotePath: "/data/package.json")
        XCTAssertEqual(ref.fileExtension, "json")
    }

    func testFileExtensionUpperCase() {
        let ref = RemoteFileReference(profileID: UUID(), remotePath: "/docs/README.MD")
        XCTAssertEqual(ref.fileExtension, "md")
    }

    func testFileExtensionNoExtension() {
        let ref = RemoteFileReference(profileID: UUID(), remotePath: "/etc/hosts")
        XCTAssertEqual(ref.fileExtension, "")
    }

    func testFileExtensionDotFile() {
        // NSString.pathExtension returns "" for dotfiles like .bashrc
        let ref = RemoteFileReference(profileID: UUID(), remotePath: "/home/user/.bashrc")
        XCTAssertEqual(ref.fileExtension, "")
    }

    // MARK: - Display String

    func testDisplayString() {
        let ref = RemoteFileReference(profileID: UUID(), remotePath: "/var/log/app.log")
        XCTAssertEqual(ref.displayString(with: "Production"), "app.log — Production")
    }

    func testDisplayStringWithEmptyName() {
        let ref = RemoteFileReference(profileID: UUID(), remotePath: "/test.txt")
        XCTAssertEqual(ref.displayString(with: ""), "test.txt — ")
    }

    // MARK: - Unique Key

    func testUniqueKeyContainsProfileAndPath() {
        let id = UUID()
        let ref = RemoteFileReference(profileID: id, remotePath: "/etc/nginx.conf")
        XCTAssertEqual(ref.uniqueKey, "\(id.uuidString):/etc/nginx.conf")
    }

    func testDifferentPathsProduceDifferentKeys() {
        let id = UUID()
        let a = RemoteFileReference(profileID: id, remotePath: "/a.txt")
        let b = RemoteFileReference(profileID: id, remotePath: "/b.txt")
        XCTAssertNotEqual(a.uniqueKey, b.uniqueKey)
    }

    func testDifferentProfilesProduceDifferentKeys() {
        let a = RemoteFileReference(profileID: UUID(), remotePath: "/same.txt")
        let b = RemoteFileReference(profileID: UUID(), remotePath: "/same.txt")
        XCTAssertNotEqual(a.uniqueKey, b.uniqueKey)
    }

    // MARK: - Codable

    func testCodableRoundTrip() throws {
        let id = UUID()
        let ref = RemoteFileReference(profileID: id, remotePath: "/home/user/data.csv")

        let data = try JSONEncoder().encode(ref)
        let decoded = try JSONDecoder().decode(RemoteFileReference.self, from: data)

        XCTAssertEqual(decoded.profileID, id)
        XCTAssertEqual(decoded.remotePath, "/home/user/data.csv")
        XCTAssertEqual(decoded.fileName, "data.csv")
        XCTAssertEqual(decoded.fileExtension, "csv")
    }

    // MARK: - Hashable

    func testHashableSameValues() {
        let id = UUID()
        let a = RemoteFileReference(profileID: id, remotePath: "/test.txt")
        let b = RemoteFileReference(profileID: id, remotePath: "/test.txt")
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func testHashableDifferentValues() {
        let a = RemoteFileReference(profileID: UUID(), remotePath: "/a.txt")
        let b = RemoteFileReference(profileID: UUID(), remotePath: "/b.txt")
        XCTAssertNotEqual(a, b)
    }

    func testHashableInSet() {
        let id = UUID()
        let ref = RemoteFileReference(profileID: id, remotePath: "/test.txt")
        var set = Set<RemoteFileReference>()
        set.insert(ref)
        set.insert(RemoteFileReference(profileID: id, remotePath: "/test.txt"))
        XCTAssertEqual(set.count, 1)
    }
}
