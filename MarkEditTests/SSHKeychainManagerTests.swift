import XCTest
@testable import MarkEdit

final class SSHKeychainManagerTests: XCTestCase {

    private var testProfileID: UUID!

    override func setUp() {
        super.setUp()
        testProfileID = UUID()
    }

    override func tearDown() {
        SSHKeychainManager.deletePassword(for: testProfileID)
        super.tearDown()
    }

    // MARK: - Save & Load

    func testSaveAndLoadPassword() {
        SSHKeychainManager.savePassword("mySecret123", for: testProfileID)
        let loaded = SSHKeychainManager.loadPassword(for: testProfileID)
        XCTAssertEqual(loaded, "mySecret123")
    }

    func testLoadNonExistentReturnsNil() {
        let loaded = SSHKeychainManager.loadPassword(for: UUID())
        XCTAssertNil(loaded)
    }

    func testSaveOverwritesPrevious() {
        SSHKeychainManager.savePassword("first", for: testProfileID)
        SSHKeychainManager.savePassword("second", for: testProfileID)
        let loaded = SSHKeychainManager.loadPassword(for: testProfileID)
        XCTAssertEqual(loaded, "second")
    }

    // MARK: - Delete

    func testDeletePassword() {
        SSHKeychainManager.savePassword("toDelete", for: testProfileID)
        SSHKeychainManager.deletePassword(for: testProfileID)
        let loaded = SSHKeychainManager.loadPassword(for: testProfileID)
        XCTAssertNil(loaded)
    }

    func testDeleteNonExistentDoesNotCrash() {
        SSHKeychainManager.deletePassword(for: UUID())
        // No assertion needed — just verifying no crash
    }

    // MARK: - Special Characters

    func testPasswordWithSpecialCharacters() {
        let special = "p@$$w0rd!#%^&*()_+-=[]{}|;':\",./<>?`~"
        SSHKeychainManager.savePassword(special, for: testProfileID)
        let loaded = SSHKeychainManager.loadPassword(for: testProfileID)
        XCTAssertEqual(loaded, special)
    }

    func testPasswordWithUnicode() {
        let unicode = "密码パスワード🔑"
        SSHKeychainManager.savePassword(unicode, for: testProfileID)
        let loaded = SSHKeychainManager.loadPassword(for: testProfileID)
        XCTAssertEqual(loaded, unicode)
    }

    func testEmptyPassword() {
        SSHKeychainManager.savePassword("", for: testProfileID)
        let loaded = SSHKeychainManager.loadPassword(for: testProfileID)
        XCTAssertEqual(loaded, "")
    }

    // MARK: - Isolation

    func testDifferentProfilesAreIsolated() {
        let idA = UUID()
        let idB = UUID()

        SSHKeychainManager.savePassword("passwordA", for: idA)
        SSHKeychainManager.savePassword("passwordB", for: idB)

        XCTAssertEqual(SSHKeychainManager.loadPassword(for: idA), "passwordA")
        XCTAssertEqual(SSHKeychainManager.loadPassword(for: idB), "passwordB")

        SSHKeychainManager.deletePassword(for: idA)
        SSHKeychainManager.deletePassword(for: idB)
    }

    func testDeleteOneDoesNotAffectOther() {
        let idA = UUID()
        let idB = UUID()

        SSHKeychainManager.savePassword("A", for: idA)
        SSHKeychainManager.savePassword("B", for: idB)

        SSHKeychainManager.deletePassword(for: idA)

        XCTAssertNil(SSHKeychainManager.loadPassword(for: idA))
        XCTAssertEqual(SSHKeychainManager.loadPassword(for: idB), "B")

        SSHKeychainManager.deletePassword(for: idB)
    }
}
