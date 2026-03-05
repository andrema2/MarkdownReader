import SwiftUI

struct StatusBarView: View {
    @ObservedObject var document: DocumentModel
    @ObservedObject var lintEngine: LintEngine

    // HIG: Status bar uses consistent 11pt system font, 8pt grid padding
    private let statusFont: Font = .system(size: 11)
    private let statusMonoFont: Font = .system(size: 11, design: .monospaced)
    private let iconFont: Font = .system(size: 10)

    var body: some View {
        VStack(spacing: 0) {
            // Issue bar (shown when cursor is on a line with an issue)
            if let issue = document.currentLineIssue {
                issueBar(issue)
            }

            Divider()

            // Main status bar — HIG: 24pt minimum height, 8pt vertical padding
            HStack(spacing: 16) {
                // Cursor position
                HStack(spacing: 4) {
                    Image(systemName: "character.cursor.ibeam")
                        .font(iconFont)
                        .foregroundStyle(.tertiary)
                    if let colSel = document.columnSelectionInfo {
                        Text("Sel: Ln \(colSel.lineRange.lowerBound)-\(colSel.lineRange.upperBound), Col \(colSel.columnRange.lowerBound)-\(colSel.columnRange.upperBound)")
                            .font(statusMonoFont)
                            .monospacedDigit()
                    } else {
                        Text("Ln \(document.cursorLine), Col \(document.cursorColumn)")
                            .font(statusMonoFont)
                            .monospacedDigit()
                    }
                }

                StatusBarSeparator()

                // Line/character count
                HStack(spacing: 4) {
                    Image(systemName: "text.alignleft")
                        .font(iconFont)
                        .foregroundStyle(.tertiary)
                    Text("\(lineCount) lines, \(document.content.count) chars")
                        .font(statusFont)
                        .monospacedDigit()
                }

                StatusBarSeparator()

                // File type
                Text(document.fileType.displayName)
                    .font(statusFont)
                    .foregroundStyle(.secondary)

                if document.isRemote {
                    StatusBarSeparator()

                    HStack(spacing: 3) {
                        Image(systemName: "network")
                            .font(iconFont)
                        Text("Remote")
                            .font(statusFont)
                    }
                    .foregroundStyle(.blue)
                }

                StatusBarSeparator()

                // Word wrap toggle — HIG: Use standard button with clear SF Symbol
                Button {
                    document.wordWrapEnabled.toggle()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: document.wordWrapEnabled ? "text.wrap" : "arrow.forward.to.line")
                            .font(iconFont)
                        Text(document.wordWrapEnabled ? "Wrap" : "No Wrap")
                            .font(statusFont)
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(document.wordWrapEnabled ? "Disable word wrap" : "Enable word wrap")

                StatusBarSeparator()

                // Encoding picker — HIG: Menu with checkmark for current selection
                Menu {
                    ForEach(supportedEncodings, id: \.enc) { item in
                        Button {
                            document.encoding = item.enc
                        } label: {
                            if document.encoding == item.enc {
                                Label(item.name, systemImage: "checkmark")
                            } else {
                                Text(item.name)
                            }
                        }
                    }
                } label: {
                    Text(encodingName)
                        .font(statusFont)
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("File encoding")

                Spacer()

                // Lint summary
                lintSummary
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)  // HIG: 8pt grid — 6pt gives 24pt total bar height
            .background(.bar)
        }
    }

    // MARK: - Issue Bar

    private func issueBar(_ issue: LintIssue) -> some View {
        HStack(spacing: 8) {
            Image(systemName: issueIcon(issue.severity))
                .font(statusFont)
                .foregroundColor(issueColor(issue.severity))

            Text(issue.message)
                .font(statusFont)
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
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
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
            HStack(spacing: 8) {
                if lintEngine.errorCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("\(lintEngine.errorCount)")
                    }
                    .font(statusFont)
                }

                if lintEngine.warningCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("\(lintEngine.warningCount)")
                    }
                    .font(statusFont)
                }
            }
        } else {
            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("No issues")
            }
            .font(statusFont)
            .foregroundStyle(.secondary)
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
        case .utf16BigEndian: return "UTF-16 BE"
        case .utf16LittleEndian: return "UTF-16 LE"
        case .ascii: return "ASCII"
        case .isoLatin1: return "ISO-8859-1"
        case .windowsCP1252: return "Windows-1252"
        default: return "UTF-8"
        }
    }

    private var supportedEncodings: [(name: String, enc: String.Encoding)] {
        [
            ("UTF-8", .utf8),
            ("UTF-16", .utf16),
            ("UTF-16 BE", .utf16BigEndian),
            ("UTF-16 LE", .utf16LittleEndian),
            ("ASCII", .ascii),
            ("ISO-8859-1", .isoLatin1),
            ("Windows-1252", .windowsCP1252),
        ]
    }
}

// HIG: 12pt separator height consistent with standard macOS status bars
private struct StatusBarSeparator: View {
    var body: some View {
        Divider()
            .frame(height: 12)
    }
}
