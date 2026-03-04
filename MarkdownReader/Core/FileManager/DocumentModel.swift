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

    enum FileType: String, CaseIterable, Identifiable {
        case markdown = "md"
        case json = "json"
        case yaml = "yaml"
        case javascript = "js"
        case plain = "txt"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .markdown: return "Markdown"
            case .json: return "JSON"
            case .yaml: return "YAML"
            case .javascript: return "JavaScript"
            case .plain: return "Plain Text"
            }
        }

        var icon: String {
            switch self {
            case .markdown: return "doc.richtext"
            case .json: return "curlybraces"
            case .yaml: return "doc.text"
            case .javascript: return "chevron.left.forwardslash.chevron.right"
            case .plain: return "doc"
            }
        }

        var primaryExtension: String { rawValue }

        /// Formats this type can be converted to.
        var convertibleTargets: [FileType] {
            switch self {
            case .markdown: return [.plain]
            case .json: return [.yaml]
            case .yaml: return [.json]
            case .plain: return [.markdown]
            case .javascript: return []
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
