import Foundation

/// Lints JavaScript and TypeScript files.
/// Uses ESLint via Process if available, otherwise falls back to heuristic checks.
struct JSLinter: Linter {
    let supportedExtensions: Set<String> = ["js", "ts", "jsx", "tsx", "mjs", "cjs"]

    func lint(content: String, fileExtension: String) async -> [LintIssue] {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        // Try eslint
        if let eslintPath = ExternalTool.find("eslint") {
            let external = await runESLint(eslintPath, content: content, ext: fileExtension)
            if !external.isEmpty { return external }
        }

        // Fallback
        return builtinLint(content: content, fileExtension: fileExtension)
    }

    // MARK: - ESLint via Process

    private func runESLint(_ path: String, content: String, ext: String) async -> [LintIssue] {
        await ExternalTool.runLinter(
            executablePath: path,
            arguments: { tempFile in
                ["--format", "json", "--no-eslintrc", "--ext", ".\(ext)", tempFile]
            },
            content: content,
            fileExtension: ext,
            parse: Self.parseESLintJSON
        )
    }

    private static func parseESLintJSON(_ data: Data) -> [LintIssue] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let file = json.first,
              let messages = file["messages"] as? [[String: Any]] else {
            return []
        }

        return messages.compactMap { msg in
            guard let line = msg["line"] as? Int,
                  let message = msg["message"] as? String else { return nil }

            let severity: LintIssue.Severity = (msg["severity"] as? Int) == 2 ? .error : .warning
            let rule = msg["ruleId"] as? String

            return LintIssue(
                line: line,
                column: msg["column"] as? Int,
                severity: severity,
                message: message,
                source: "ESLint",
                rule: rule
            )
        }
    }

    // MARK: - Built-in fallback

    private func builtinLint(content: String, fileExtension: String) -> [LintIssue] {
        var issues: [LintIssue] = []
        let lines = content.components(separatedBy: .newlines)
        let isTS = ["ts", "tsx", "mts", "cts"].contains(fileExtension)

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // console.log
            if trimmed.contains("console.log") {
                issues.append(LintIssue(
                    line: lineNumber,
                    column: line.range(of: "console.log").map { line.distance(from: line.startIndex, to: $0.lowerBound) + 1 },
                    severity: .warning,
                    message: "Unexpected console.log statement",
                    source: isTS ? "TS" : "JS",
                    rule: "no-console"
                ))
            }

            // var usage
            if trimmed.hasPrefix("var ") || trimmed.contains(" var ") {
                issues.append(LintIssue(
                    line: lineNumber,
                    severity: .warning,
                    message: "Use 'let' or 'const' instead of 'var'",
                    source: isTS ? "TS" : "JS",
                    rule: "no-var"
                ))
            }

            // debugger
            if trimmed == "debugger" || trimmed == "debugger;" {
                issues.append(LintIssue(
                    line: lineNumber,
                    severity: .error,
                    message: "Unexpected 'debugger' statement",
                    source: isTS ? "TS" : "JS",
                    rule: "no-debugger"
                ))
            }

            // alert()
            if trimmed.contains("alert(") {
                issues.append(LintIssue(
                    line: lineNumber,
                    severity: .warning,
                    message: "Unexpected use of alert()",
                    source: isTS ? "TS" : "JS",
                    rule: "no-alert"
                ))
            }

            // eval()
            if trimmed.contains("eval(") {
                issues.append(LintIssue(
                    line: lineNumber,
                    severity: .error,
                    message: "eval() is dangerous and should be avoided",
                    source: isTS ? "TS" : "JS",
                    rule: "no-eval"
                ))
            }

            // == instead of ===
            if let eqRange = trimmed.range(of: #"[^=!]==[^=]"#, options: .regularExpression) {
                issues.append(LintIssue(
                    line: lineNumber,
                    column: trimmed.distance(from: trimmed.startIndex, to: eqRange.lowerBound) + 2,
                    severity: .warning,
                    message: "Use '===' instead of '=='",
                    source: isTS ? "TS" : "JS",
                    rule: "eqeqeq"
                ))
            }

            // TS-specific: any type
            if isTS && (trimmed.contains(": any") || trimmed.contains("<any>") || trimmed.contains("as any")) {
                issues.append(LintIssue(
                    line: lineNumber,
                    severity: .warning,
                    message: "Avoid using 'any' type — use a more specific type",
                    source: "TS",
                    rule: "no-explicit-any"
                ))
            }
        }

        return issues
    }
}

