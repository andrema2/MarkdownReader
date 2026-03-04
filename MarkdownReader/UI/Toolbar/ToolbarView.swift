import SwiftUI

struct ToolbarView: View {
    @ObservedObject var document: DocumentModel
    @ObservedObject var lintEngine: LintEngine
    @Binding var showLintPanel: Bool
    @Binding var showPreview: Bool

    var body: some View {
        HStack(spacing: 12) {
            // File info
            HStack(spacing: 6) {
                Image(systemName: iconForFileType)
                    .foregroundColor(.secondary)
                Text(document.fileName)
                    .font(.headline)
                    .lineLimit(1)
                if document.isDirty {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                }
            }

            Divider()
                .frame(height: 20)

            // Format controls (only for Markdown)
            if document.fileType == .markdown {
                FormatControls(document: document)
            }

            Spacer()

            // Preview toggle
            Button(action: { showPreview.toggle() }) {
                Image(systemName: showPreview ? "eye.fill" : "eye.slash")
            }
            .buttonStyle(.borderless)
            .help("Toggle syntax highlight preview")

            // Lint toggle
            Button(action: { showLintPanel.toggle() }) {
                HStack(spacing: 4) {
                    Image(systemName: lintEngine.issues.isEmpty ? "checkmark.circle" : "exclamationmark.triangle")
                        .foregroundColor(lintEngine.issues.isEmpty ? .green : .orange)
                    Text("\(lintEngine.issues.count)")
                        .font(.caption)
                        .monospacedDigit()
                }
            }
            .buttonStyle(.borderless)
            .help("Toggle lint panel")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }

    private var iconForFileType: String {
        switch document.fileType {
        case .markdown: return "doc.richtext"
        case .json: return "curlybraces"
        case .yaml: return "doc.text"
        case .javascript: return "chevron.left.forwardslash.chevron.right"
        case .plain: return "doc"
        }
    }
}
