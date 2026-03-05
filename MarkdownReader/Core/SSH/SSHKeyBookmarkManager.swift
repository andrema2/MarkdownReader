import AppKit

struct SSHKeyBookmarkManager {
    /// Presents an open panel for the user to select a private key file.
    static func selectKeyFile(completion: @escaping (Data?) -> Void) {
        let panel = NSOpenPanel()
        panel.title = "Select SSH Private Key"
        panel.showsHiddenFiles = true
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")

        panel.begin { response in
            guard response == .OK, let url = panel.url else {
                completion(nil)
                return
            }
            let bookmarkData = try? url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            completion(bookmarkData)
        }
    }

    /// Resolves a security-scoped bookmark and reads the key content.
    static func resolveKeyFile(from bookmarkData: Data) -> (url: URL, keyContent: String)? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return nil }

        guard url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return (url, content)
    }
}
