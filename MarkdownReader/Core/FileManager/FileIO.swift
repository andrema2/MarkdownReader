import AppKit
import UniformTypeIdentifiers

struct FileIO {
    static func open(completion: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = supportedTypes
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        panel.begin { response in
            completion(response == .OK ? panel.url : nil)
        }
    }

    static func save(suggestedName: String, completion: @escaping (URL?) -> Void) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = supportedTypes
        panel.nameFieldStringValue = suggestedName
        panel.canCreateDirectories = true

        panel.begin { response in
            completion(response == .OK ? panel.url : nil)
        }
    }

    static func read(from url: URL) throws -> (String, String.Encoding) {
        var detectedEncoding: String.Encoding = .utf8
        let content = try String(contentsOf: url, usedEncoding: &detectedEncoding)
        return (content, detectedEncoding)
    }

    static func write(_ content: String, to url: URL, encoding: String.Encoding = .utf8) throws {
        try content.write(to: url, atomically: true, encoding: encoding)
    }

    // MARK: - Security-Scoped Bookmarks

    static func saveBookmark(for url: URL) {
        guard let data = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }
        UserDefaults.standard.set(data, forKey: "fileBookmark_\(url.path)")
    }

    static func resolveBookmark(for path: String) -> URL? {
        guard let data = UserDefaults.standard.data(forKey: "fileBookmark_\(path)") else { return nil }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return nil }

        if isStale {
            saveBookmark(for: url)
        }
        return url
    }

    // MARK: - Supported Types

    private static var supportedTypes: [UTType] {
        [
            // Markdown
            UTType(filenameExtension: "md")!,
            UTType(filenameExtension: "markdown")!,
            // JSON
            .json,
            // YAML
            UTType(filenameExtension: "yaml")!,
            UTType(filenameExtension: "yml")!,
            // JavaScript
            .javaScript,
            // TypeScript
            UTType(filenameExtension: "ts")!,
            UTType(filenameExtension: "tsx")!,
            // CSS
            UTType(filenameExtension: "css")!,
            UTType(filenameExtension: "scss")!,
            // Plain text
            .plainText,
        ]
    }
}
