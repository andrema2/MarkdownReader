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

    private static var supportedTypes: [UTType] {
        [
            UTType(filenameExtension: "md")!,
            UTType(filenameExtension: "markdown")!,
            .json,
            UTType(filenameExtension: "yaml")!,
            UTType(filenameExtension: "yml")!,
            .javaScript,
            .plainText,
        ]
    }
}
