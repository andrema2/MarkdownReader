import SwiftUI
import AppKit

struct EditorView: View {
    @StateObject private var document = DocumentModel()
    @StateObject private var lintEngine = LintEngine()
    @State private var showLintPanel = true
    @State private var showPreview = true
    @State private var isDragTargeted = false

    var body: some View {
        HSplitView {
            // Main editor area
            VStack(spacing: 0) {
                ToolbarView(document: document, lintEngine: lintEngine, showLintPanel: $showLintPanel, showPreview: $showPreview)

                Divider()

                HSplitView {
                    CodeTextView(document: document)
                        .frame(minWidth: 300)

                    if showPreview {
                        HighlightEngine(
                            code: document.content,
                            language: LanguageMap.language(for: document.fileExtension)
                        )
                        .frame(minWidth: 300)
                    }
                }

                Divider()

                StatusBarView(document: document, lintEngine: lintEngine)
            }

            // Lint sidebar
            if showLintPanel {
                LintPanel(lintEngine: lintEngine)
                    .frame(minWidth: 220, maxWidth: 320)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isDragTargeted ? Color.accentColor : Color.clear, lineWidth: 3)
                .padding(4)
        )
        .onDrop(of: [.fileURL], isTargeted: $isDragTargeted) { providers in
            handleDrop(providers: providers)
        }
        .onReceive(NotificationCenter.default.publisher(for: .newDocument)) { _ in
            newDocument()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openDocument)) { _ in
            openDocument()
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveDocument)) { _ in
            saveDocument()
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveDocumentAs)) { _ in
            saveDocumentAs()
        }
        .navigationTitle(document.fileName)
        .onChange(of: document.content) {
            runLint()
        }
        .onChange(of: document.fileURL) {
            if let url = document.fileURL {
                NSApp.mainWindow?.representedURL = url
                NSApp.mainWindow?.title = url.lastPathComponent
            } else {
                NSApp.mainWindow?.representedURL = nil
                NSApp.mainWindow?.title = "Untitled"
            }
        }
    }

    // MARK: - File Operations

    private func newDocument() {
        document.content = ""
        document.fileURL = nil
        document.isDirty = false
        document.fileType = .markdown
        lintEngine.clear()
        updateWindowState()
    }

    private func openDocument() {
        FileIO.open { url in
            guard let url else { return }
            loadFile(url: url)
        }
    }

    private func saveDocument() {
        if let url = document.fileURL {
            do {
                try FileIO.write(document.content, to: url, encoding: document.encoding)
                document.markClean()
                updateWindowState()
            } catch {
                // TODO: show alert
            }
        } else {
            saveDocumentAs()
        }
    }

    private func saveDocumentAs() {
        FileIO.save(suggestedName: document.fileName) { url in
            guard let url else { return }
            do {
                try FileIO.write(document.content, to: url, encoding: document.encoding)
                document.fileURL = url
                document.fileType = .from(extension: url.pathExtension)
                document.markClean()
                updateWindowState()
            } catch {
                // TODO: show alert
            }
        }
    }

    private func loadFile(url: URL) {
        do {
            let (content, encoding) = try FileIO.read(from: url)
            document.content = content
            document.fileURL = url
            document.encoding = encoding
            document.fileType = .from(extension: url.pathExtension)
            document.isDirty = false
            updateWindowState()
            runLint()
        } catch {
            document.content = "Error loading file: \(error.localizedDescription)"
        }
    }

    private func runLint() {
        Task {
            await lintEngine.run(content: document.content, fileExtension: document.fileExtension)
        }
    }

    private func updateWindowState() {
        NSApp.mainWindow?.isDocumentEdited = document.isDirty
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            if let data = item as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                DispatchQueue.main.async {
                    loadFile(url: url)
                }
            }
        }
        return true
    }
}

#Preview {
    EditorView()
}
