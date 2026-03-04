import Foundation

struct YAMLLinter: Linter {
    let supportedExtensions: Set<String> = ["yaml", "yml"]

    func lint(content: String, fileExtension: String) async -> [LintIssue] {
        var issues: [LintIssue] = []

        let lines = content.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1

            // Check for tabs (YAML uses spaces only)
            if line.contains("\t") {
                issues.append(LintIssue(
                    line: lineNumber,
                    column: nil,
                    severity: .error,
                    message: "Tabs are not allowed in YAML, use spaces",
                    source: "YAML"
                ))
            }

            // Check for trailing spaces
            if line != line.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression) {
                issues.append(LintIssue(
                    line: lineNumber,
                    column: nil,
                    severity: .warning,
                    message: "Trailing whitespace",
                    source: "YAML"
                ))
            }

            // Check for duplicate keys at root level (simple heuristic)
            if line.contains(": ") && !line.trimmingCharacters(in: .whitespaces).hasPrefix("#") && !line.hasPrefix(" ") && !line.hasPrefix("-") {
                let key = line.components(separatedBy: ":").first?.trimmingCharacters(in: .whitespaces) ?? ""
                let duplicates = lines.filter {
                    $0.hasPrefix(key + ":") && !$0.trimmingCharacters(in: .whitespaces).hasPrefix("#")
                }
                if duplicates.count > 1 && index == lines.firstIndex(of: line) {
                    issues.append(LintIssue(
                        line: lineNumber,
                        column: nil,
                        severity: .warning,
                        message: "Possible duplicate key: '\(key)'",
                        source: "YAML"
                    ))
                }
            }
        }

        return issues
    }
}
