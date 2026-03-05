import AppKit
import SwiftUI

/// Observable object that passes file open requests from the system to the SwiftUI views.
class FileOpenRequest: ObservableObject {
    @Published var url: URL?
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let fileOpenRequest = FileOpenRequest()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let tabStates = UserDefaults.standard.array(forKey: "tabSessionStates") as? [[String: Any]] ?? []
        let savedActiveIndex = UserDefaults.standard.integer(forKey: "activeTabIndex")

        // Try to restore multiple tabs first
        if let paths = UserDefaults.standard.stringArray(forKey: "openTabs"), !paths.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                for (index, path) in paths.enumerated() {
                    // Check if this tab was a remote file
                    if index < tabStates.count,
                       let refData = tabStates[index]["remoteFileRef"] as? Data,
                       let ref = try? JSONDecoder().decode(RemoteFileReference.self, from: refData) {
                        NotificationCenter.default.post(name: .openRemoteFile, object: ref)
                        if index < tabStates.count {
                            let state = tabStates[index]
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 * Double(index + 1)) {
                                NotificationCenter.default.post(name: .restoreTabState, object: state)
                            }
                        }
                        continue
                    }

                    let url: URL?
                    if let bookmarkedURL = FileIO.resolveBookmark(for: path) {
                        let gained = bookmarkedURL.startAccessingSecurityScopedResource()
                        url = bookmarkedURL
                        if gained { bookmarkedURL.stopAccessingSecurityScopedResource() }
                    } else if FileManager.default.fileExists(atPath: path) {
                        url = URL(fileURLWithPath: path)
                    } else {
                        url = nil
                    }
                    if let url {
                        self.fileOpenRequest.url = url

                        // Apply saved tab state after a brief delay to let the tab load
                        if index < tabStates.count {
                            let state = tabStates[index]
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 * Double(index + 1)) {
                                // Post notification with tab state for TabContainerView to apply
                                NotificationCenter.default.post(
                                    name: .restoreTabState,
                                    object: state
                                )
                            }
                        }
                    }
                }

                // Restore active tab index
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 * Double(paths.count + 1)) {
                    NotificationCenter.default.post(
                        name: .restoreActiveTabIndex,
                        object: savedActiveIndex
                    )
                }
            }
        } else if let path = UserDefaults.standard.string(forKey: "lastOpenedFile") {
            // Legacy: restore single file
            if let bookmarkedURL = FileIO.resolveBookmark(for: path) {
                let gained = bookmarkedURL.startAccessingSecurityScopedResource()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.fileOpenRequest.url = bookmarkedURL
                    if gained { bookmarkedURL.stopAccessingSecurityScopedResource() }
                }
            } else {
                let url = URL(fileURLWithPath: path)
                if FileManager.default.fileExists(atPath: path) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.fileOpenRequest.url = url
                    }
                }
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    /// Called when the user double-clicks files associated with this app in Finder.
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            fileOpenRequest.url = url
        }
    }
}
