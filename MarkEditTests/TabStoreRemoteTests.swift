import XCTest
@testable import MarkEdit

final class TabStoreRemoteTests: XCTestCase {

    // MARK: - openRemoteFile

    func testOpenRemoteFileReusesEmptyTab() {
        let store = TabStore()
        XCTAssertEqual(store.tabs.count, 1)

        let ref = RemoteFileReference(profileID: UUID(), remotePath: "/test.yaml")
        let tab = store.openRemoteFile(ref: ref)

        // Should reuse the initial empty tab
        XCTAssertEqual(store.tabs.count, 1)
        XCTAssertEqual(tab.id, store.tabs[0].id)
    }

    func testOpenRemoteFileCreatesNewTabWhenActiveNotEmpty() {
        let store = TabStore()
        store.activeTab.document.updateContent("some content")

        let ref = RemoteFileReference(profileID: UUID(), remotePath: "/test.yaml")
        let tab = store.openRemoteFile(ref: ref)

        XCTAssertEqual(store.tabs.count, 2)
        XCTAssertEqual(store.selectedTabID, tab.id)
    }

    func testOpenRemoteFileDeduplicatesSameRef() {
        let store = TabStore()
        let profileID = UUID()
        let ref = RemoteFileReference(profileID: profileID, remotePath: "/etc/config.yaml")

        let tab1 = store.openRemoteFile(ref: ref)
        tab1.document.remoteFileRef = ref
        tab1.document.updateContent("content")

        let tab2 = store.openRemoteFile(ref: ref)

        XCTAssertEqual(tab1.id, tab2.id, "Should reuse existing tab with same remote file")
    }

    func testOpenRemoteFileDifferentRefsCreateDifferentTabs() {
        let store = TabStore()
        let profileID = UUID()

        let ref1 = RemoteFileReference(profileID: profileID, remotePath: "/a.yaml")
        let tab1 = store.openRemoteFile(ref: ref1)
        tab1.document.remoteFileRef = ref1
        tab1.document.updateContent("a")

        let ref2 = RemoteFileReference(profileID: profileID, remotePath: "/b.yaml")
        let tab2 = store.openRemoteFile(ref: ref2)

        XCTAssertNotEqual(tab1.id, tab2.id)
        XCTAssertEqual(store.tabs.count, 2)
    }

    func testOpenRemoteFileDoesNotReuseLocalTab() {
        let store = TabStore()
        store.activeTab.document.fileURL = URL(fileURLWithPath: "/tmp/local.txt")

        let ref = RemoteFileReference(profileID: UUID(), remotePath: "/remote.txt")
        let tab = store.openRemoteFile(ref: ref)

        XCTAssertEqual(store.tabs.count, 2)
        XCTAssertNotEqual(tab.id, store.tabs[0].id)
    }

    // MARK: - Session State with Remote

    func testSessionStateIncludesRemoteFileRef() throws {
        let tab = TabItem()
        let ref = RemoteFileReference(profileID: UUID(), remotePath: "/var/log/app.log")
        tab.document.remoteFileRef = ref

        let state = tab.sessionState
        let data = state["remoteFileRef"] as? Data
        XCTAssertNotNil(data)

        let decoded = try JSONDecoder().decode(RemoteFileReference.self, from: data!)
        XCTAssertEqual(decoded.remotePath, "/var/log/app.log")
        XCTAssertEqual(decoded.profileID, ref.profileID)
    }

    func testSessionStateWithoutRemoteHasNoRef() {
        let tab = TabItem()
        let state = tab.sessionState
        XCTAssertNil(state["remoteFileRef"])
    }

    func testRestoreFromStateWithRemoteFileRef() throws {
        let ref = RemoteFileReference(profileID: UUID(), remotePath: "/etc/nginx.conf")
        let data = try JSONEncoder().encode(ref)

        let tab = TabItem()
        tab.restore(from: ["remoteFileRef": data, "showPreview": false])

        XCTAssertEqual(tab.document.remoteFileRef, ref)
        XCTAssertFalse(tab.showPreview)
    }

    func testRestoreFromStateWithoutRemoteDoesNotSetRef() {
        let tab = TabItem()
        tab.restore(from: ["showPreview": true])
        XCTAssertNil(tab.document.remoteFileRef)
    }

    // MARK: - openTabPaths with Remote

    func testOpenTabPathsIncludesRemotePlaceholder() {
        let store = TabStore()
        let profileID = UUID()
        let ref = RemoteFileReference(profileID: profileID, remotePath: "/test.yaml")
        store.activeTab.document.remoteFileRef = ref

        let paths = store.openTabPaths
        XCTAssertEqual(paths.count, 1)
        XCTAssertTrue(paths[0].hasPrefix("remote://"))
        XCTAssertTrue(paths[0].contains(profileID.uuidString))
    }

    func testOpenTabPathsMixedLocalAndRemote() {
        let store = TabStore()
        store.activeTab.document.fileURL = URL(fileURLWithPath: "/tmp/local.txt")

        let newTab = store.newTab()
        newTab.document.remoteFileRef = RemoteFileReference(profileID: UUID(), remotePath: "/remote.yaml")

        let paths = store.openTabPaths
        XCTAssertEqual(paths.count, 2)
        XCTAssertEqual(paths[0], "/tmp/local.txt")
        XCTAssertTrue(paths[1].hasPrefix("remote://"))
    }
}
