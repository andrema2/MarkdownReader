import XCTest
@testable import MarkEdit

final class DocumentModelRemoteTests: XCTestCase {

    // MARK: - isRemote

    func testIsRemoteFalseByDefault() {
        let doc = DocumentModel()
        XCTAssertFalse(doc.isRemote)
    }

    func testIsRemoteTrueWhenRefSet() {
        let doc = DocumentModel()
        doc.remoteFileRef = RemoteFileReference(profileID: UUID(), remotePath: "/test.yaml")
        XCTAssertTrue(doc.isRemote)
    }

    func testIsRemoteFalseWhenRefCleared() {
        let doc = DocumentModel()
        doc.remoteFileRef = RemoteFileReference(profileID: UUID(), remotePath: "/test.yaml")
        doc.remoteFileRef = nil
        XCTAssertFalse(doc.isRemote)
    }

    // MARK: - fileName with Remote

    func testFileNameFromRemoteRef() {
        let doc = DocumentModel()
        doc.remoteFileRef = RemoteFileReference(profileID: UUID(), remotePath: "/var/log/app.log")
        XCTAssertEqual(doc.fileName, "app.log")
    }

    func testFileNamePrefersRemoteOverLocal() {
        let doc = DocumentModel()
        doc.fileURL = URL(fileURLWithPath: "/tmp/local.txt")
        doc.remoteFileRef = RemoteFileReference(profileID: UUID(), remotePath: "/remote/server.yaml")
        XCTAssertEqual(doc.fileName, "server.yaml")
    }

    func testFileNameFallsBackToLocalWhenNoRemote() {
        let doc = DocumentModel()
        doc.fileURL = URL(fileURLWithPath: "/tmp/local.txt")
        XCTAssertEqual(doc.fileName, "local.txt")
    }

    func testFileNameUntitledWhenNoURLOrRemote() {
        let doc = DocumentModel()
        XCTAssertEqual(doc.fileName, "Untitled")
    }

    // MARK: - fileExtension with Remote

    func testFileExtensionFromRemoteRef() {
        let doc = DocumentModel()
        doc.remoteFileRef = RemoteFileReference(profileID: UUID(), remotePath: "/etc/config.json")
        XCTAssertEqual(doc.fileExtension, "json")
    }

    func testFileExtensionPrefersRemoteOverLocal() {
        let doc = DocumentModel()
        doc.fileURL = URL(fileURLWithPath: "/tmp/local.md")
        doc.remoteFileRef = RemoteFileReference(profileID: UUID(), remotePath: "/remote/data.csv")
        XCTAssertEqual(doc.fileExtension, "csv")
    }

    func testFileExtensionFallsBackToLocal() {
        let doc = DocumentModel()
        doc.fileURL = URL(fileURLWithPath: "/tmp/style.css")
        XCTAssertEqual(doc.fileExtension, "css")
    }

    func testFileExtensionDefaultMd() {
        let doc = DocumentModel()
        XCTAssertEqual(doc.fileExtension, "md")
    }

    // MARK: - remoteFileRef initial state

    func testRemoteFileRefNilByDefault() {
        let doc = DocumentModel()
        XCTAssertNil(doc.remoteFileRef)
    }
}
