import Foundation

struct JSONLinter: Linter {
    let supportedExtensions: Set<String> = ["json"]

    func lint(content: String, fileExtension: String) async -> [LintIssue] {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        do {
            _ = try JSONSerialization.jsonObject(with: Data(content.utf8), options: .fragmentsAllowed)
            return []
        } catch {
            return parseJSONError(error, content: content)
        }
    }

    private func parseJSONError(_ error: Error, content: String) -> [LintIssue] {
        let nsError = error as NSError
        let description = nsError.localizedDescription

        // Try to extract line/column from the error description
        // Format: "... around line X, column Y."
        var line = 1
        var column: Int?

        if let lineMatch = description.range(of: #"line (\d+)"#, options: .regularExpression) {
            let numStr = description[lineMatch].filter(\.isNumber)
            line = Int(numStr) ?? 1
        }

        if let colMatch = description.range(of: #"column (\d+)"#, options: .regularExpression) {
            let numStr = description[colMatch].filter(\.isNumber)
            column = Int(numStr)
        }

        // If no line info, try to find the byte offset and convert to line number
        if line == 1, column == nil {
            if let byteOffset = nsError.userInfo["NSJSONSerializationErrorIndex"] as? Int {
                (line, column) = lineAndColumn(for: byteOffset, in: content)
            }
        }

        // Provide a cleaner message
        let cleanMessage = cleanErrorMessage(description)

        return [
            LintIssue(
                line: line,
                column: column,
                severity: .error,
                message: cleanMessage,
                source: "JSON",
                rule: errorRule(from: description)
            )
        ]
    }

    private func lineAndColumn(for byteOffset: Int, in content: String) -> (Int, Int) {
        let data = Data(content.utf8)
        let prefix = data.prefix(min(byteOffset, data.count))
        guard let prefixStr = String(data: prefix, encoding: .utf8) else {
            return (1, 1)
        }
        let lines = prefixStr.components(separatedBy: .newlines)
        let line = lines.count
        let col = (lines.last?.count ?? 0) + 1
        return (line, col)
    }

    private func cleanErrorMessage(_ raw: String) -> String {
        // Remove verbose "The data couldn't be read because it isn't in the correct format."
        var msg = raw
        if let range = msg.range(of: "The data couldn't be read because it isn't in the correct format.") {
            msg.removeSubrange(range)
        }
        msg = msg.trimmingCharacters(in: .whitespacesAndNewlines)
        if msg.isEmpty {
            return "Invalid JSON"
        }
        // Capitalize first letter
        return msg.prefix(1).uppercased() + msg.dropFirst()
    }

    private func errorRule(from description: String) -> String? {
        if description.contains("trailing comma") { return "no-trailing-comma" }
        if description.contains("single quotes") { return "double-quotes" }
        if description.contains("key") && description.contains("duplicate") { return "no-duplicate-keys" }
        return nil
    }
}
