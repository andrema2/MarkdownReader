import SwiftUI

struct StatusBarView: View {
    @ObservedObject var document: DocumentModel
    @ObservedObject var lintEngine: LintEngine

    var body: some View {
        HStack(spacing: 16) {
            // Line/character count
            HStack(spacing: 4) {
                Image(systemName: "text.alignleft")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(lineCount) lines, \(document.content.count) chars")
                    .font(.caption)
                    .monospacedDigit()
            }

            Divider()
                .frame(height: 12)

            // File type
            Text(document.fileType.displayName)
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()
                .frame(height: 12)

            // Encoding
            Text(encodingName)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            // Lint summary
            if !lintEngine.issues.isEmpty {
                HStack(spacing: 8) {
                    let errors = lintEngine.issues.filter { $0.severity == .error }.count
                    let warnings = lintEngine.issues.filter { $0.severity == .warning }.count

                    if errors > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("\(errors)")
                        }
                        .font(.caption)
                    }

                    if warnings > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("\(warnings)")
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(.bar)
    }

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
