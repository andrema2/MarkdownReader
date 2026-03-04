import SwiftUI

struct LintPanel: View {
    @ObservedObject var lintEngine: LintEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Issues")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                if lintEngine.isRunning {
                    ProgressView()
                        .controlSize(.small)
                }
                Text("\(lintEngine.issues.count)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(lintEngine.issues.isEmpty ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if lintEngine.issues.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("No issues found")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(lintEngine.issues) { issue in
                    LintIssueRow(issue: issue)
                }
                .listStyle(.sidebar)
            }
        }
    }
}

struct LintIssueRow: View {
    let issue: LintIssue

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: severityIcon)
                .foregroundColor(severityColor)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(issue.message)
                    .font(.caption)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text("Line \(issue.line)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(issue.source)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.secondary.opacity(0.15))
                        )
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var severityIcon: String {
        switch issue.severity {
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private var severityColor: Color {
        switch issue.severity {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}
