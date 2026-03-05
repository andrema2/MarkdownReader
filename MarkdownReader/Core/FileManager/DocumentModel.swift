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
    @Published var columnSelectionInfo: ColumnSelectionInfo?
    @Published var wordWrapEnabled: Bool = true
    @Published var matchingBracketRange: NSRange?
    @Published var remoteFileRef: RemoteFileReference?

    var isRemote: Bool { remoteFileRef != nil }

    var fileName: String {
        if let ref = remoteFileRef { return ref.fileName }
        return fileURL?.lastPathComponent ?? "Untitled"
    }

    var fileExtension: String {
        if let ref = remoteFileRef { return ref.fileExtension }
        return fileURL?.pathExtension.lowercased() ?? "md"
    }

    enum FileType: String, CaseIterable, Identifiable {
        case markdown = "md"
        case html = "html"
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
            case .html: return "HTML"
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
            case .html: return "globe"
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
            case .markdown: return [.html, .plain]
            case .html: return [.markdown]
            case .json: return [.yaml]
            case .yaml: return [.json]
            case .plain: return [.markdown]
            case .javascript, .typescript, .css: return []
            }
        }

        static func from(extension ext: String) -> FileType {
            switch ext.lowercased() {
            case "md", "markdown": return .markdown
            case "html", "htm": return .html
            case "json", "jsonl": return .json
            case "yaml", "yml": return .yaml
            case "js", "jsx", "mjs", "cjs": return .javascript
            case "ts", "tsx", "mts", "cts": return .typescript
            case "css", "scss", "less": return .css
            default: return .plain
            }
        }
    }

    // MARK: - YAML Subtype Detection

    enum YAMLSubtype: Equatable {
        case dockerCompose
        case kubernetes
        case githubActions
        case gitlabCI
        case generic
    }

    var yamlSubtype: YAMLSubtype {
        guard fileType == .yaml else { return .generic }
        let name = fileURL?.lastPathComponent.lowercased() ?? ""
        let pathComponents = fileURL?.pathComponents.map { $0.lowercased() } ?? []

        // Filename-based (fast, unambiguous)
        if name.hasPrefix("docker-compose") || name.hasPrefix("compose") { return .dockerCompose }
        if name == ".gitlab-ci.yml" || name == ".gitlab-ci.yaml" { return .gitlabCI }
        if pathComponents.contains(".github") && pathComponents.contains("workflows") { return .githubActions }

        // Content-based (first 4KB)
        let preview = String(content.prefix(4096))
        let lines = preview.components(separatedBy: .newlines)

        let hasApiVersion = lines.contains { $0.hasPrefix("apiVersion:") }
        let hasKind = lines.contains { $0.hasPrefix("kind:") }
        if hasApiVersion && hasKind { return .kubernetes }

        let hasOn = lines.contains { $0 == "on:" || $0.hasPrefix("on:") }
        let hasJobs = lines.contains { $0.hasPrefix("jobs:") }
        if hasOn && hasJobs { return .githubActions }

        let hasServices = lines.contains { $0.hasPrefix("services:") }
        if hasServices { return .dockerCompose }

        let hasStages = lines.contains { $0.hasPrefix("stages:") }
        if hasStages && !hasApiVersion { return .gitlabCI }

        return .generic
    }

    // MARK: - JSON Subtype Detection

    enum JSONSubtype: Equatable {
        case packageJSON
        case tsconfig
        case eslint
        case generic
    }

    var jsonSubtype: JSONSubtype {
        guard fileType == .json else { return .generic }
        let name = fileURL?.lastPathComponent.lowercased() ?? ""
        if name == "package.json" { return .packageJSON }
        if name.contains("tsconfig") { return .tsconfig }
        if name.contains("eslint") { return .eslint }
        return .generic
    }

    // MARK: - Content

    func updateContent(_ newContent: String) {
        content = newContent
        isDirty = true
    }

    func markClean() {
        isDirty = false
    }
}
