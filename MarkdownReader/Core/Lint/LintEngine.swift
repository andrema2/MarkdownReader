import Foundation
import Combine

struct LintIssue: Identifiable, Hashable {
    let id = UUID()
    let line: Int
    let column: Int?
    let severity: Severity
    let message: String
    let source: String
    let rule: String?

    init(line: Int, column: Int? = nil, severity: Severity, message: String, source: String, rule: String? = nil) {
        self.line = line
        self.column = column
        self.severity = severity
        self.message = message
        self.source = source
        self.rule = rule
    }

    enum Severity: String, Comparable {
        case error
        case warning
        case info

        static func < (lhs: Severity, rhs: Severity) -> Bool {
            let order: [Severity] = [.error, .warning, .info]
            return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
        }
    }
}

protocol Linter {
    var supportedExtensions: Set<String> { get }
    func lint(content: String, fileExtension: String) async -> [LintIssue]
}

class LintEngine: ObservableObject {
    @Published var issues: [LintIssue] = []
    @Published var isRunning: Bool = false
    @Published var selectedIssue: LintIssue?

    private let linters: [Linter] = [
        JSONLinter(),
        YAMLLinter(),
        JSLinter(),
        CSSLinter(),
    ]

    /// Debounce: cancel previous lint if a new one starts.
    private var currentTask: Task<Void, Never>?

    @MainActor
    func run(content: String, fileExtension: String) {
        currentTask?.cancel()
        currentTask = Task {
            isRunning = true
            defer { isRunning = false }

            let ext = fileExtension.lowercased()
            let applicable = linters.filter { $0.supportedExtensions.contains(ext) }

            var allIssues: [LintIssue] = []
            for linter in applicable {
                if Task.isCancelled { return }
                let result = await linter.lint(content: content, fileExtension: ext)
                allIssues.append(contentsOf: result)
            }

            if !Task.isCancelled {
                issues = allIssues.sorted { ($0.severity, $0.line) < ($1.severity, $1.line) }
            }
        }
    }

    func clear() {
        currentTask?.cancel()
        issues = []
        selectedIssue = nil
    }

    var errorCount: Int { issues.filter { $0.severity == .error }.count }
    var warningCount: Int { issues.filter { $0.severity == .warning }.count }
    var infoCount: Int { issues.filter { $0.severity == .info }.count }
}
