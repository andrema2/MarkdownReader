import Foundation

struct JSONLinter: Linter {
    let supportedExtensions: Set<String> = ["json"]

    func lint(content: String, fileExtension: String) async -> [LintIssue] {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        do {
            _ = try JSONSerialization.jsonObject(with: Data(content.utf8))
            return []
        } catch let error as NSError {
            let line = extractLine(from: error.localizedDescription) ?? 1
            return [
                LintIssue(
                    line: line,
                    column: nil,
                    severity: .error,
                    message: error.localizedDescription,
                    source: "JSON"
                )
            ]
        }
    }

    private func extractLine(from message: String) -> Int? {
        let pattern = #"line (\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: message, range: NSRange(message.startIndex..., in: message)),
              let range = Range(match.range(at: 1), in: message) else {
            return nil
        }
        return Int(message[range])
    }
}
