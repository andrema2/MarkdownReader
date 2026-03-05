import Foundation

/// Shared utilities for finding and running external linting tools.
enum ExternalTool {
    static func find(_ name: String) -> String? {
        let searchPaths = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/usr/bin/\(name)",
        ]
        // Also check npx-installed (node_modules/.bin)
        let npxPaths = [
            "./node_modules/.bin/\(name)",
        ]
        return (searchPaths + npxPaths).first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    static func runLinter(
        executablePath: String,
        arguments: @escaping (String) -> [String],
        content: String,
        fileExtension: String,
        parse: @escaping (Data) -> [LintIssue]
    ) async -> [LintIssue] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let tempFile = NSTemporaryDirectory() + "markedit_\(UUID().uuidString).\(fileExtension)"
                do {
                    try content.write(toFile: tempFile, atomically: true, encoding: .utf8)
                    defer { try? FileManager.default.removeItem(atPath: tempFile) }

                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: executablePath)
                    process.arguments = arguments(tempFile)

                    let stdout = Pipe()
                    process.standardOutput = stdout
                    process.standardError = Pipe()

                    try process.run()
                    process.waitUntilExit()

                    let data = stdout.fileHandleForReading.readDataToEndOfFile()
                    let issues = parse(data)
                    continuation.resume(returning: issues)
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }
}
