import Foundation

class DocumentModel: ObservableObject {
    @Published var content: String = ""
    @Published var fileURL: URL?
    @Published var isDirty: Bool = false
    @Published var encoding: String.Encoding = .utf8
    @Published var fileType: FileType = .markdown
    @Published var cursorLine: Int = 1
    @Published var cursorColumn: Int = 1
    @Published var currentLineIssue: LintIssue?

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
        case typescript = "ts"
        case css = "css"
        case plain = "txt"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .markdown: return "Markdown"
            case .json: return "JSON"
            case .yaml: return "YAML"
            case .javascript: return "JavaScript"
            case .typescript: return "TypeScript"
            case .css: return "CSS"
            case .plain: return "Plain Text"
            }
        }

        var icon: String {
            switch self {
            case .markdown: return "doc.richtext"
            case .json: return "curlybraces"
            case .yaml: return "doc.text"
            case .javascript: return "chevron.left.forwardslash.chevron.right"
            case .typescript: return "chevron.left.forwardslash.chevron.right"
            case .css: return "paintbrush"
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
            case .javascript, .typescript, .css: return []
            }
        }

        static func from(extension ext: String) -> FileType {
            switch ext.lowercased() {
            case "md", "markdown": return .markdown
            case "json", "jsonl": return .json
            case "yaml", "yml": return .yaml
            case "js", "jsx", "mjs", "cjs": return .javascript
            case "ts", "tsx", "mts", "cts": return .typescript
            case "css", "scss", "less": return .css
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
