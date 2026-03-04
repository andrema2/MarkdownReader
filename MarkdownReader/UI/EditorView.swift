import SwiftUI
import AppKit

struct EditorView: View {
    @EnvironmentObject var fileOpenRequest: FileOpenRequest
    @StateObject private var document = DocumentModel()
    @StateObject private var lintEngine = LintEngine()
    @State private var showLintPanel = true
    @State private var showPreview = true
    @State private var isDragTargeted = false
    @State private var goToLine: Int?

    var body: some View {
        HSplitView {
            // Main editor area
            VStack(spacing: 0) {
                ToolbarView(document: document, lintEngine: lintEngine, showLintPanel: $showLintPanel, showPreview: $showPreview)

                Divider()

                HSplitView {
                    CodeTextView(document: document, lintEngine: lintEngine, goToLine: goToLine)
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
                LintPanel(lintEngine: lintEngine) { issue in
                    goToLine = nil
                    DispatchQueue.main.async {
                        goToLine = issue.line
                    }
                }
                .frame(minWidth: 240, maxWidth: 350)
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
        // Menu commands
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
        .onReceive(NotificationCenter.default.publisher(for: .togglePreview)) { _ in
            showPreview.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleLintPanel)) { _ in
            showLintPanel.toggle()
        }
        // File opened from Finder (double-click or drag to dock icon)
        .onChange(of: fileOpenRequest.url) {
            if let url = fileOpenRequest.url {
                loadFile(url: url)
                fileOpenRequest.url = nil
            }
        }
        .navigationTitle(document.fileName)
        .onChange(of: document.content) {
            runLint()
        }
        .onChange(of: document.fileURL) {
            if let url = document.fileURL {
                NSApp.mainWindow?.representedURL = url
                NSApp.mainWindow?.title = url.lastPathComponent
                // Persist for restore on next launch
                UserDefaults.standard.set(url.path, forKey: "lastOpenedFile")
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
        goToLine = nil
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
            goToLine = nil
            updateWindowState()
            runLint()
            // Save bookmark for restore on next launch
            FileIO.saveBookmark(for: url)
        } catch {
            document.content = "Error loading file: \(error.localizedDescription)"
        }
    }

    private func runLint() {
        lintEngine.run(content: document.content, fileExtension: document.fileExtension)
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
        .environmentObject(FileOpenRequest())
}
