import SwiftUI

struct StatusBarView: View {
    @ObservedObject var document: DocumentModel
    @ObservedObject var lintEngine: LintEngine

    var body: some View {
        VStack(spacing: 0) {
            // Error message bar (shown when cursor is on a line with an issue)
            if let issue = document.currentLineIssue {
                issueBar(issue)
            }

            Divider()

            // Main status bar
            HStack(spacing: 12) {
                // Cursor position
                HStack(spacing: 4) {
                    Image(systemName: "cursorarrow.and.square.on.square.dashed")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("Ln \(document.cursorLine), Col \(document.cursorColumn)")
                        .font(.system(size: 11, design: .monospaced))
                        .monospacedDigit()
                }

                ToolbarSeparator()

                // Line/character count
                HStack(spacing: 4) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("\(lineCount) lines, \(document.content.count) chars")
                        .font(.system(size: 11))
                        .monospacedDigit()
                }

                ToolbarSeparator()

                // File type
                Text(document.fileType.displayName)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                ToolbarSeparator()

                // Encoding
                Text(encodingName)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                // Lint summary
                lintSummary
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(.bar)
        }
    }

    // MARK: - Issue Bar

    private func issueBar(_ issue: LintIssue) -> some View {
        HStack(spacing: 8) {
            Image(systemName: issueIcon(issue.severity))
                .font(.system(size: 11))
                .foregroundColor(issueColor(issue.severity))

            Text(issue.message)
                .font(.system(size: 11))
                .lineLimit(1)
                .foregroundColor(issueColor(issue.severity))

            if let rule = issue.rule {
                Text("(\(rule))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(issueColor(issue.severity).opacity(0.7))
            }

            Spacer()

            Text(issue.source)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(issueColor(issue.severity).opacity(0.12))
                )
                .foregroundColor(issueColor(issue.severity))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(issueColor(issue.severity).opacity(0.06))
    }

    private func issueIcon(_ severity: LintIssue.Severity) -> String {
        switch severity {
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private func issueColor(_ severity: LintIssue.Severity) -> Color {
        switch severity {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }

    // MARK: - Lint Summary

    @ViewBuilder
    private var lintSummary: some View {
        if !lintEngine.issues.isEmpty {
            HStack(spacing: 6) {
                if lintEngine.errorCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("\(lintEngine.errorCount)")
                    }
                    .font(.system(size: 11))
                }

                if lintEngine.warningCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("\(lintEngine.warningCount)")
                    }
                    .font(.system(size: 11))
                }
            }
        } else {
            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("No issues")
            }
            .font(.system(size: 11))
            .foregroundColor(.secondary)
        }
    }

    // MARK: - Helpers

    private var lineCount: Int {
        document.content.isEmpty ? 0 : document.content.components(separatedBy: .newlines).count
    }

    private var encodingName: String {
        switch document.encoding {
        case .utf8: return "UTF-8"
        case .utf16: return "UTF-16"
        case .ascii: return "ASCII"
        case .isoLatin1: return "ISO-8859-1"
        default: return "UTF-8"
        }
    }
}

private struct ToolbarSeparator: View {
    var body: some View {
        Divider()
            .frame(height: 12)
    }
}
