import AppKit
import SwiftUI

/// Observable object that passes file open requests from the system to the SwiftUI views.
class FileOpenRequest: ObservableObject {
    @Published var url: URL?
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let fileOpenRequest = FileOpenRequest()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Restore last opened file via security-scoped bookmark
        if let path = UserDefaults.standard.string(forKey: "lastOpenedFile") {
            if let bookmarkedURL = FileIO.resolveBookmark(for: path) {
                let gained = bookmarkedURL.startAccessingSecurityScopedResource()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.fileOpenRequest.url = bookmarkedURL
                    if gained { bookmarkedURL.stopAccessingSecurityScopedResource() }
                }
            } else {
                // Fallback: try direct path (works outside sandbox or if file was opened before)
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

    /// Called when the user double-clicks a file associated with this app in Finder.
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        fileOpenRequest.url = url
    }
}
