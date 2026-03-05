import XCTest
@testable import MarkEdit

final class SSHConnectionProfileTests: XCTestCase {

    private let defaultsKey = "sshConnectionProfiles"

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        super.tearDown()
    }

    // MARK: - Default Values

    func testDefaultPort() {
        let profile = SSHConnectionProfile(name: "Test", host: "example.com", username: "user")
        XCTAssertEqual(profile.port, 22)
    }

    func testDefaultAuthMethod() {
        let profile = SSHConnectionProfile(name: "Test", host: "example.com", username: "user")
        XCTAssertEqual(profile.authMethod, .password)
    }

    func testDefaultRemotePath() {
        let profile = SSHConnectionProfile(name: "Test", host: "example.com", username: "user")
        XCTAssertEqual(profile.defaultRemotePath, "/")
    }

    // MARK: - Identifiable

    func testUniqueIDs() {
        let a = SSHConnectionProfile(name: "A", host: "a.com", username: "user")
        let b = SSHConnectionProfile(name: "B", host: "b.com", username: "user")
        XCTAssertNotEqual(a.id, b.id)
    }

    // MARK: - Codable

    func testCodableRoundTripPassword() throws {
        let profile = SSHConnectionProfile(name: "Prod", host: "10.0.0.1", port: 2222, username: "deploy", authMethod: .password, defaultRemotePath: "/var/log")

        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(SSHConnectionProfile.self, from: data)

        XCTAssertEqual(decoded.id, profile.id)
        XCTAssertEqual(decoded.name, "Prod")
        XCTAssertEqual(decoded.host, "10.0.0.1")
        XCTAssertEqual(decoded.port, 2222)
        XCTAssertEqual(decoded.username, "deploy")
        XCTAssertEqual(decoded.authMethod, .password)
        XCTAssertEqual(decoded.defaultRemotePath, "/var/log")
    }

    func testCodableRoundTripPrivateKey() throws {
        let bookmarkData = Data([0x01, 0x02, 0x03])
        let profile = SSHConnectionProfile(name: "Key Server", host: "key.com", username: "admin", authMethod: .privateKey(bookmarkData: bookmarkData))

        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(SSHConnectionProfile.self, from: data)

        XCTAssertEqual(decoded.authMethod, .privateKey(bookmarkData: bookmarkData))
    }

    // MARK: - Hashable

    func testHashable() {
        let profile = SSHConnectionProfile(name: "Test", host: "h.com", username: "u")
        var set = Set<SSHConnectionProfile>()
        set.insert(profile)
        set.insert(profile)
        XCTAssertEqual(set.count, 1)
    }

    func testDifferentProfilesHash() {
        let a = SSHConnectionProfile(name: "A", host: "a.com", username: "u")
        let b = SSHConnectionProfile(name: "B", host: "b.com", username: "u")
        var set = Set<SSHConnectionProfile>()
        set.insert(a)
        set.insert(b)
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Persistence (saveAll / loadAll)

    func testSaveAndLoadAll() {
        let profiles = [
            SSHConnectionProfile(name: "Server A", host: "a.com", username: "ua"),
            SSHConnectionProfile(name: "Server B", host: "b.com", port: 8022, username: "ub"),
        ]

        SSHConnectionProfile.saveAll(profiles)
        let loaded = SSHConnectionProfile.loadAll()

        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].id, profiles[0].id)
        XCTAssertEqual(loaded[0].name, "Server A")
        XCTAssertEqual(loaded[0].host, "a.com")
        XCTAssertEqual(loaded[1].port, 8022)
        XCTAssertEqual(loaded[1].username, "ub")
    }

    func testLoadAllReturnsEmptyWhenNothingSaved() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        let loaded = SSHConnectionProfile.loadAll()
        XCTAssertTrue(loaded.isEmpty)
    }

    func testSaveAllOverwritesPrevious() {
        let first = [SSHConnectionProfile(name: "Old", host: "old.com", username: "u")]
        SSHConnectionProfile.saveAll(first)

        let second = [
            SSHConnectionProfile(name: "New1", host: "n1.com", username: "u"),
            SSHConnectionProfile(name: "New2", host: "n2.com", username: "u"),
        ]
        SSHConnectionProfile.saveAll(second)

        let loaded = SSHConnectionProfile.loadAll()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].name, "New1")
    }

    func testSaveEmptyArrayClearsList() {
        let profiles = [SSHConnectionProfile(name: "X", host: "x.com", username: "u")]
        SSHConnectionProfile.saveAll(profiles)
        SSHConnectionProfile.saveAll([])
        let loaded = SSHConnectionProfile.loadAll()
        XCTAssertTrue(loaded.isEmpty)
    }

    // MARK: - AuthMethod Equality

    func testAuthMethodPasswordEquality() {
        XCTAssertEqual(SSHConnectionProfile.AuthMethod.password, .password)
    }

    func testAuthMethodPrivateKeyEquality() {
        let data = Data([0xAA, 0xBB])
        XCTAssertEqual(
            SSHConnectionProfile.AuthMethod.privateKey(bookmarkData: data),
            .privateKey(bookmarkData: data)
        )
    }

    func testAuthMethodDifferentTypesNotEqual() {
        let pw: SSHConnectionProfile.AuthMethod = .password
        let key: SSHConnectionProfile.AuthMethod = .privateKey(bookmarkData: Data())
        XCTAssertNotEqual(pw, key)
    }
}
