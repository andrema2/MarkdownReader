import Foundation

struct YAMLLinter: Linter {
    let supportedExtensions: Set<String> = ["yaml", "yml"]

    func lint(content: String, fileExtension: String) async -> [LintIssue] {
        // Try yamllint first (external tool)
        if let yamllintPath = findExecutable("yamllint") {
            let external = await runYamllint(yamllintPath, content: content)
            if !external.isEmpty { return external }
        }

        // Fallback to built-in structural checks
        return builtinLint(content: content)
    }

    // MARK: - External yamllint

    private func findExecutable(_ name: String) -> String? {
        let paths = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/usr/bin/\(name)",
        ]
        return paths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private func runYamllint(_ path: String, content: String) async -> [LintIssue] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let tempFile = NSTemporaryDirectory() + "markedit_yaml_\(UUID().uuidString).yaml"
                do {
                    try content.write(toFile: tempFile, atomically: true, encoding: .utf8)
                    defer { try? FileManager.default.removeItem(atPath: tempFile) }

                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: path)
                    process.arguments = ["-f", "parsable", tempFile]

                    let stdout = Pipe()
                    let stderr = Pipe()
                    process.standardOutput = stdout
                    process.standardError = stderr

                    try process.run()
                    process.waitUntilExit()

                    // yamllint outputs to stdout in parsable format
                    let data = stdout.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    let issues = Self.parseYamllintOutput(output)
                    continuation.resume(returning: issues)
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    /// Parsable format: `file:line:col: [level] message (rule)`
    private static func parseYamllintOutput(_ output: String) -> [LintIssue] {
        let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
        return lines.compactMap { line in
            // Split: filename:line:col: [error] message (rule)
            let pattern = #":(\d+):(\d+): \[(error|warning)\] (.+?)(?:\s*\((.+?)\))?$"#
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
                return nil
            }

            func group(_ i: Int) -> String? {
                guard let range = Range(match.range(at: i), in: line) else { return nil }
                return String(line[range])
            }

            guard let lineNum = group(1).flatMap(Int.init),
                  let colNum = group(2).flatMap(Int.init),
                  let level = group(3),
                  let message = group(4) else { return nil }

            let rule = group(5)

            return LintIssue(
                line: lineNum,
                column: colNum,
                severity: level == "error" ? .error : .warning,
                message: message,
                source: "yamllint",
                rule: rule
            )
        }
    }

    // MARK: - Built-in fallback

    private func builtinLint(content: String) -> [LintIssue] {
        var issues: [LintIssue] = []
        let lines = content.components(separatedBy: .newlines)
        var rootKeys: [(key: String, line: Int)] = []

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines and comments
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            // Tabs
            if line.contains("\t") {
                issues.append(LintIssue(
                    line: lineNumber,
                    column: (line.firstIndex(of: "\t").map { line.distance(from: line.startIndex, to: $0) + 1 }),
                    severity: .error,
                    message: "Tab character found — YAML requires spaces for indentation",
                    source: "YAML",
                    rule: "no-tabs"
                ))
            }

            // Trailing whitespace
            if line != line.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression) {
                issues.append(LintIssue(
                    line: lineNumber,
                    severity: .warning,
                    message: "Trailing whitespace",
                    source: "YAML",
                    rule: "trailing-spaces"
                ))
            }

            // Inconsistent indentation (odd number of spaces)
            let leadingSpaces = line.prefix(while: { $0 == " " }).count
            if leadingSpaces > 0 && leadingSpaces % 2 != 0 {
                issues.append(LintIssue(
                    line: lineNumber,
                    column: leadingSpaces,
                    severity: .warning,
                    message: "Odd indentation level (\(leadingSpaces) spaces) — consider using 2-space increments",
                    source: "YAML",
                    rule: "indentation"
                ))
            }

            // Collect root-level keys for duplicate detection
            if !line.hasPrefix(" ") && !line.hasPrefix("-") && line.contains(":") {
                let key = line.components(separatedBy: ":").first?.trimmingCharacters(in: .whitespaces) ?? ""
                if !key.isEmpty {
                    rootKeys.append((key: key, line: lineNumber))
                }
            }

            // Document start marker check (first non-comment line)
            if index == 0 && trimmed != "---" && !trimmed.hasPrefix("#") {
                issues.append(LintIssue(
                    line: 1,
                    severity: .info,
                    message: "Missing document start marker '---'",
                    source: "YAML",
                    rule: "document-start"
                ))
            }
        }

        // Duplicate root keys
        var seen: [String: Int] = [:]
        for entry in rootKeys {
            if let firstLine = seen[entry.key] {
                issues.append(LintIssue(
                    line: entry.line,
                    severity: .error,
                    message: "Duplicate key '\(entry.key)' (first defined on line \(firstLine))",
                    source: "YAML",
                    rule: "no-duplicate-keys"
                ))
            } else {
                seen[entry.key] = entry.line
            }
        }

        return issues
    }
}
