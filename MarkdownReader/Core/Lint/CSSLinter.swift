import Foundation

/// Lints CSS, SCSS, and LESS files.
/// Uses Stylelint via Process if available, otherwise falls back to heuristic checks.
struct CSSLinter: Linter {
    let supportedExtensions: Set<String> = ["css", "scss", "less"]

    func lint(content: String, fileExtension: String) async -> [LintIssue] {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        // Try stylelint
        if let stylelintPath = ExternalTool.find("stylelint") {
            let external = await runStylelint(stylelintPath, content: content, ext: fileExtension)
            if !external.isEmpty { return external }
        }

        // Fallback
        return builtinLint(content: content)
    }

    private func runStylelint(_ path: String, content: String, ext: String) async -> [LintIssue] {
        await ExternalTool.runLinter(
            executablePath: path,
            arguments: { tempFile in
                ["--formatter", "json", tempFile]
            },
            content: content,
            fileExtension: ext,
            parse: Self.parseStylelintJSON
        )
    }

    private static func parseStylelintJSON(_ data: Data) -> [LintIssue] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let file = json.first,
              let warnings = file["warnings"] as? [[String: Any]] else {
            return []
        }

        return warnings.compactMap { warn in
            guard let line = warn["line"] as? Int,
                  let text = warn["text"] as? String else { return nil }

            let severity: LintIssue.Severity = (warn["severity"] as? String) == "error" ? .error : .warning

            return LintIssue(
                line: line,
                column: warn["column"] as? Int,
                severity: severity,
                message: text,
                source: "Stylelint",
                rule: warn["rule"] as? String
            )
        }
    }

    private func builtinLint(content: String) -> [LintIssue] {
        var issues: [LintIssue] = []
        let lines = content.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // !important
            if trimmed.contains("!important") {
                issues.append(LintIssue(
                    line: lineNumber,
                    column: line.range(of: "!important").map { line.distance(from: line.startIndex, to: $0.lowerBound) + 1 },
                    severity: .warning,
                    message: "Avoid using !important",
                    source: "CSS",
                    rule: "no-important"
                ))
            }

            // Inline style attribute (if HTML-like)
            if trimmed.contains("style=\"") {
                issues.append(LintIssue(
                    line: lineNumber,
                    severity: .info,
                    message: "Inline styles detected — consider using classes",
                    source: "CSS",
                    rule: "no-inline-styles"
                ))
            }

            // Empty rule
            if trimmed.hasSuffix("{ }") || trimmed.hasSuffix("{}") {
                issues.append(LintIssue(
                    line: lineNumber,
                    severity: .warning,
                    message: "Empty rule",
                    source: "CSS",
                    rule: "no-empty-rules"
                ))
            }
        }

        return issues
    }
}
