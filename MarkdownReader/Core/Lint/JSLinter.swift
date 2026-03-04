import Foundation

struct JSLinter: Linter {
    let supportedExtensions: Set<String> = ["js"]

    func lint(content: String, fileExtension: String) async -> [LintIssue] {
        // Try to use eslint if available
        if let eslintPath = findExecutable("eslint") {
            return await runExternalLinter(eslintPath, content: content)
        }

        // Fallback to basic heuristic checks
        return basicLint(content: content)
    }

    private func findExecutable(_ name: String) -> String? {
        let paths = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/usr/bin/\(name)",
        ]
        return paths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private func runExternalLinter(_ path: String, content: String) async -> [LintIssue] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let tempFile = NSTemporaryDirectory() + "markedit_lint_\(UUID().uuidString).js"
                do {
                    try content.write(toFile: tempFile, atomically: true, encoding: .utf8)
                    defer { try? FileManager.default.removeItem(atPath: tempFile) }

                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: path)
                    process.arguments = ["--format", "json", "--no-eslintrc", tempFile]

                    let pipe = Pipe()
                    process.standardOutput = pipe
                    process.standardError = Pipe()

                    try process.run()
                    process.waitUntilExit()

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let issues = Self.parseESLintOutput(data)
                    continuation.resume(returning: issues)
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    private static func parseESLintOutput(_ data: Data) -> [LintIssue] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let file = json.first,
              let messages = file["messages"] as? [[String: Any]] else {
            return []
        }

        return messages.compactMap { msg in
            guard let line = msg["line"] as? Int,
                  let message = msg["message"] as? String else { return nil }

            let severity: LintIssue.Severity = (msg["severity"] as? Int) == 2 ? .error : .warning

            return LintIssue(
                line: line,
                column: msg["column"] as? Int,
                severity: severity,
                message: message,
                source: "ESLint"
            )
        }
    }

    private func basicLint(content: String) -> [LintIssue] {
        var issues: [LintIssue] = []
        let lines = content.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1

            if line.contains("console.log") {
                issues.append(LintIssue(
                    line: lineNumber,
                    column: nil,
                    severity: .warning,
                    message: "Unexpected console.log statement",
                    source: "JS"
                ))
            }

            if line.contains("var ") {
                issues.append(LintIssue(
                    line: lineNumber,
                    column: nil,
                    severity: .info,
                    message: "Consider using 'let' or 'const' instead of 'var'",
                    source: "JS"
                ))
            }
        }

        return issues
    }
}
