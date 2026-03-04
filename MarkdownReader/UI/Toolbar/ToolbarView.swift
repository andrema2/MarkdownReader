import SwiftUI

struct ToolbarView: View {
    @ObservedObject var document: DocumentModel
    @ObservedObject var lintEngine: LintEngine
    @Binding var showLintPanel: Bool
    @Binding var showPreview: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Primary bar — file info + global actions
            HStack(spacing: 0) {
                fileInfoSection
                Spacer()
                globalActionsSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()

            // Contextual bar — format-specific controls
            HStack(spacing: 0) {
                contextualControls
                Spacer()
                convertSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
        .background(.bar)
    }

    // MARK: - File Info (left side, primary bar)

    private var fileInfoSection: some View {
        HStack(spacing: 8) {
            // File type badge
            HStack(spacing: 5) {
                Image(systemName: document.fileType.icon)
                    .font(.system(size: 12, weight: .medium))
                Text(document.fileType.displayName)
                    .font(.system(size: 11, weight: .semibold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.accentColor.opacity(0.12))
            )
            .foregroundColor(.accentColor)

            // File name
            Text(document.fileName)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)

            if document.isDirty {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 7, height: 7)
                    .help("Unsaved changes")
            }
        }
    }

    // MARK: - Global Actions (right side, primary bar)

    private var globalActionsSection: some View {
        HStack(spacing: 2) {
            toolbarButton("Open", icon: "folder", active: false) {
                NotificationCenter.default.post(name: .openDocument, object: nil)
            }

            toolbarButton("Save", icon: "square.and.arrow.down", active: false) {
                NotificationCenter.default.post(name: .saveDocument, object: nil)
            }

            toolbarButton("Save As", icon: "square.and.arrow.down.on.square", active: false) {
                NotificationCenter.default.post(name: .saveDocumentAs, object: nil)
            }

            Divider()
                .frame(height: 18)
                .padding(.horizontal, 4)

            toolbarButton("Preview", icon: showPreview ? "eye.fill" : "eye.slash", active: showPreview) {
                showPreview.toggle()
            }

            toolbarButton("Issues", icon: lintIcon, active: showLintPanel, badge: lintEngine.issues.count) {
                showLintPanel.toggle()
            }
        }
    }

    private var lintIcon: String {
        if lintEngine.isRunning { return "arrow.triangle.2.circlepath" }
        if lintEngine.issues.isEmpty { return "checkmark.circle" }
        let hasErrors = lintEngine.issues.contains { $0.severity == .error }
        return hasErrors ? "xmark.circle" : "exclamationmark.triangle"
    }

    // MARK: - Contextual Controls (left side, secondary bar)

    @ViewBuilder
    private var contextualControls: some View {
        switch document.fileType {
        case .markdown:
            MarkdownControls(document: document)
        case .html:
            PlainTextControls(document: document)
        case .json:
            JSONControls(document: document)
        case .yaml:
            YAMLControls(document: document)
        case .javascript, .typescript:
            JSControls(document: document)
        case .css:
            CSSControls(document: document)
        case .plain:
            PlainTextControls(document: document)
        }
    }

    // MARK: - Convert Section (right side, secondary bar)

    @ViewBuilder
    private var convertSection: some View {
        let targets = document.fileType.convertibleTargets
        if !targets.isEmpty {
            Menu {
                ForEach(targets) { target in
                    Button {
                        convertDocument(to: target)
                    } label: {
                        Label(target.displayName, systemImage: target.icon)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 11))
                    Text("Convert")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.secondary.opacity(0.1))
                )
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Convert to another format")
        }
    }

    private func convertDocument(to target: DocumentModel.FileType) {
        let source = document.fileType
        if let converted = FormatConverter.convert(document.content, from: source, to: target) {
            document.updateContent(converted)
        }
        document.fileType = target

        // Update file URL extension if we have one
        if let url = document.fileURL {
            let newURL = url.deletingPathExtension().appendingPathExtension(target.primaryExtension)
            document.fileURL = newURL
        }
    }

    // MARK: - Toolbar Button

    private func toolbarButton(_ label: String, icon: String, active: Bool, badge: Int = 0, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(active ? .accentColor : .secondary)

                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 10, weight: .bold))
                        .monospacedDigit()
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.2))
                        )
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(active ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.borderless)
        .help(label)
    }
}
