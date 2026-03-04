import SwiftUI

struct LintPanel: View {
    @ObservedObject var lintEngine: LintEngine
    var onIssueTapped: ((LintIssue) -> Void)?

    @State private var filterSeverity: LintIssue.Severity?

    private var filteredIssues: [LintIssue] {
        guard let filter = filterSeverity else { return lintEngine.issues }
        return lintEngine.issues.filter { $0.severity == filter }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerView

            Divider()

            // Filter chips
            if !lintEngine.issues.isEmpty {
                filterBar
                Divider()
            }

            // Issue list
            if filteredIssues.isEmpty {
                emptyState
            } else {
                issueList
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("Issues")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
            if lintEngine.isRunning {
                ProgressView()
                    .controlSize(.small)
            }
            badge(count: lintEngine.issues.count, color: lintEngine.issues.isEmpty ? .green : .orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 6) {
            filterChip("All", count: lintEngine.issues.count, severity: nil)

            if lintEngine.errorCount > 0 {
                filterChip("Errors", count: lintEngine.errorCount, severity: .error)
            }
            if lintEngine.warningCount > 0 {
                filterChip("Warnings", count: lintEngine.warningCount, severity: .warning)
            }
            if lintEngine.infoCount > 0 {
                filterChip("Info", count: lintEngine.infoCount, severity: .info)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func filterChip(_ label: String, count: Int, severity: LintIssue.Severity?) -> some View {
        let isActive = filterSeverity == severity
        return Button(action: { filterSeverity = severity }) {
            HStack(spacing: 3) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                Text("\(count)")
                    .font(.system(size: 9, weight: .bold))
                    .monospacedDigit()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isActive ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
            )
            .foregroundColor(isActive ? .accentColor : .secondary)
        }
        .buttonStyle(.borderless)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 32))
                .foregroundColor(.green)
            Text("No issues found")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Issue List

    private var issueList: some View {
        ScrollViewReader { proxy in
            List(filteredIssues) { issue in
                LintIssueRow(issue: issue, isSelected: lintEngine.selectedIssue == issue)
                    .id(issue.id)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        lintEngine.selectedIssue = issue
                        onIssueTapped?(issue)
                    }
            }
            .listStyle(.sidebar)
            .onChange(of: lintEngine.selectedIssue) {
                if let selected = lintEngine.selectedIssue {
                    withAnimation {
                        proxy.scrollTo(selected.id, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Badge

    private func badge(count: Int, color: Color) -> some View {
        Text("\(count)")
            .font(.system(size: 10, weight: .bold))
            .monospacedDigit()
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color.opacity(0.2))
            )
            .foregroundColor(color)
    }
}

// MARK: - Issue Row

struct LintIssueRow: View {
    let issue: LintIssue
    var isSelected: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Severity icon
            Image(systemName: severityIcon)
                .font(.system(size: 12))
                .foregroundColor(severityColor)
                .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: 3) {
                // Message
                Text(issue.message)
                    .font(.system(size: 11))
                    .lineLimit(3)
                    .foregroundColor(.primary)

                // Metadata row
                HStack(spacing: 6) {
                    // Location — clickable appearance
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.right.circle")
                            .font(.system(size: 8))
                        Text(locationText)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.accentColor)

                    // Source badge
                    Text(issue.source)
                        .font(.system(size: 9, weight: .semibold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.secondary.opacity(0.12))
                        )
                        .foregroundColor(.secondary)

                    // Rule badge
                    if let rule = issue.rule {
                        Text(rule)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }

    private var locationText: String {
        if let col = issue.column {
            return "L\(issue.line):\(col)"
        }
        return "L\(issue.line)"
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
