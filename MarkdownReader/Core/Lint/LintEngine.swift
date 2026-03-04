import Foundation

struct LintIssue: Identifiable, Hashable {
    let id = UUID()
    let line: Int
    let column: Int?
    let severity: Severity
    let message: String
    let source: String

    enum Severity: String {
        case error
        case warning
        case info
    }
}

protocol Linter {
    var supportedExtensions: Set<String> { get }
    func lint(content: String, fileExtension: String) async -> [LintIssue]
}

class LintEngine: ObservableObject {
    @Published var issues: [LintIssue] = []
    @Published var isRunning: Bool = false

    private let linters: [Linter] = [
        JSONLinter(),
        YAMLLinter(),
        JSLinter(),
    ]

    @MainActor
    func run(content: String, fileExtension: String) async {
        isRunning = true
        defer { isRunning = false }

        let applicableLinters = linters.filter { $0.supportedExtensions.contains(fileExtension) }

        var allIssues: [LintIssue] = []
        for linter in applicableLinters {
            let result = await linter.lint(content: content, fileExtension: fileExtension)
            allIssues.append(contentsOf: result)
        }

        issues = allIssues.sorted { $0.line < $1.line }
    }

    func clear() {
        issues = []
    }
}
