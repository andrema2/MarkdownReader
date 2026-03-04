import Foundation

class DocumentModel: ObservableObject {
    @Published var content: String = ""
    @Published var fileURL: URL?
    @Published var isDirty: Bool = false
    @Published var encoding: String.Encoding = .utf8
    @Published var fileType: FileType = .markdown

    var fileName: String {
        fileURL?.lastPathComponent ?? "Untitled"
    }

    var fileExtension: String {
        fileURL?.pathExtension.lowercased() ?? "md"
    }

    enum FileType: String, CaseIterable {
        case markdown = "md"
        case json = "json"
        case yaml = "yaml"
        case javascript = "js"
        case plain = "txt"

        var displayName: String {
            switch self {
            case .markdown: return "Markdown"
            case .json: return "JSON"
            case .yaml: return "YAML"
            case .javascript: return "JavaScript"
            case .plain: return "Plain Text"
            }
        }

        static func from(extension ext: String) -> FileType {
            switch ext.lowercased() {
            case "md", "markdown": return .markdown
            case "json": return .json
            case "yaml", "yml": return .yaml
            case "js": return .javascript
            default: return .plain
            }
        }
    }

    func updateContent(_ newContent: String) {
        content = newContent
        isDirty = true
    }

    func markClean() {
        isDirty = false
    }
}
