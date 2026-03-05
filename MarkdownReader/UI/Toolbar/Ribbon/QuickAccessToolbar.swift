import SwiftUI

/// Quick Access Toolbar — file info + New/Open/Save + Undo/Redo (28pt height).
struct QuickAccessToolbar: View {
    @ObservedObject var document: DocumentModel

    var body: some View {
        HStack(spacing: 0) {
            // File info (left)
            fileInfoSection

            Spacer()

            // File actions
            HStack(spacing: 2) {
                QATButton("New", icon: "doc.badge.plus") {
                    NotificationCenter.default.post(name: .newDocument, object: nil)
                }
                QATButton("Open", icon: "folder") {
                    NotificationCenter.default.post(name: .openDocument, object: nil)
                }
                QATButton("Save", icon: "square.and.arrow.down") {
                    NotificationCenter.default.post(name: .saveDocument, object: nil)
                }
            }

            QATDivider()

            // Undo / Redo
            HStack(spacing: 2) {
                QATButton("Undo", icon: "arrow.uturn.backward") {
                    NSApp.sendAction(Selector(("undo:")), to: nil, from: nil)
                }
                QATButton("Redo", icon: "arrow.uturn.forward") {
                    NSApp.sendAction(Selector(("redo:")), to: nil, from: nil)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 28)
    }

    // MARK: - File Info

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
}
