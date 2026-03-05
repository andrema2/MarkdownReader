import SwiftUI
import AppKit

struct EditorView: View {
    @ObservedObject var tab: TabItem
    @State private var isDragTargeted = false

    private var document: DocumentModel { tab.document }
    private var lintEngine: LintEngine { tab.lintEngine }

    var body: some View {
        HSplitView {
            // Main editor area
            VStack(spacing: 0) {
                ToolbarView(document: document, lintEngine: lintEngine, showLintPanel: $tab.showLintPanel, showPreview: $tab.showPreview)

                Divider()

                if tab.showFindPanel {
                    FindReplacePanel(engine: tab.findEngine, showReplace: tab.findReplaceMode) {
                        tab.showFindPanel = false
                        tab.findEngine.matches = []
                        tab.findEngine.currentMatchIndex = -1
                    }
                    Divider()
                }

                HSplitView {
                    CodeTextView(document: document, lintEngine: lintEngine, goToLine: tab.goToLine, findEngine: tab.findEngine, foldingEngine: tab.foldingEngine, diffEngine: tab.diffEngine, bookmarkEngine: tab.bookmarkEngine)
                        .frame(minWidth: 300)

                    if tab.showPreview {
                        if document.fileType == .markdown {
                            MarkdownRenderer(markdown: document.content)
                                .frame(minWidth: 300)
                        } else if document.fileType == .html {
                            HTMLPreview(html: document.content, baseURL: document.fileURL?.deletingLastPathComponent())
                                .frame(minWidth: 300)
                        } else {
                            HighlightEngine(
                                code: document.content,
                                language: LanguageMap.language(for: document.fileExtension)
                            )
                            .frame(minWidth: 300)
                        }
                    }
                }

                Divider()

                StatusBarView(document: document, lintEngine: lintEngine)
            }

            // Lint sidebar
            if tab.showLintPanel {
                LintPanel(lintEngine: lintEngine) { issue in
                    tab.goToLine = nil
                    DispatchQueue.main.async {
                        tab.goToLine = issue.line
                    }
                }
                .frame(minWidth: 240, maxWidth: 350)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isDragTargeted ? Color.accentColor : Color.clear, lineWidth: 3)
                .padding(4)
        )
        .onDrop(of: [.fileURL], isTargeted: $isDragTargeted) { providers in
            handleDrop(providers: providers)
        }
        .onChange(of: document.content) {
            lintEngine.run(content: document.content, fileExtension: document.fileExtension)
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleBookmark)) { _ in
            tab.bookmarkEngine.toggleBookmark(at: document.cursorLine)
        }
        .onReceive(NotificationCenter.default.publisher(for: .nextBookmark)) { _ in
            if let line = tab.bookmarkEngine.nextBookmark(after: document.cursorLine) {
                tab.goToLine = nil
                DispatchQueue.main.async { tab.goToLine = line }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .previousBookmark)) { _ in
            if let line = tab.bookmarkEngine.previousBookmark(before: document.cursorLine) {
                tab.goToLine = nil
                DispatchQueue.main.async { tab.goToLine = line }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showDiff)) { _ in
            tab.diffEngine.computeDiff(currentContent: document.content, fileURL: document.fileURL)
        }
    }

    // MARK: - Drag & Drop

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            if let data = item as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                DispatchQueue.main.async {
                    // Post notification so TabContainerView handles it as a new tab
                    NotificationCenter.default.post(name: .openFileFromFinder, object: url)
                }
            }
        }
        return true
    }
}
