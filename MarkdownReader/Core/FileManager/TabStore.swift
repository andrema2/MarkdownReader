import Foundation
import Combine

class TabItem: ObservableObject, Identifiable {
    let id = UUID()
    @Published var document = DocumentModel()
    @Published var lintEngine = LintEngine()
    @Published var showPreview = true
    @Published var showLintPanel = true
    @Published var goToLine: Int?
    @Published var showFindPanel = false
    @Published var findReplaceMode = false  // false=find only, true=find+replace
    @Published var findEngine = FindReplaceEngine()
    @Published var foldingEngine = FoldingEngine()
    @Published var diffEngine = DiffEngine()
    @Published var bookmarkEngine = BookmarkEngine()

    /// Persisted state keys for session restore
    var sessionState: [String: Any] {
        var state: [String: Any] = [:]
        if let url = document.fileURL {
            state["filePath"] = url.path
        }
        if let ref = document.remoteFileRef,
           let data = try? JSONEncoder().encode(ref) {
            state["remoteFileRef"] = data
        }
        state["showPreview"] = showPreview
        state["showLintPanel"] = showLintPanel
        state["wordWrap"] = document.wordWrapEnabled
        return state
    }

    func restore(from state: [String: Any]) {
        if let showPreview = state["showPreview"] as? Bool {
            self.showPreview = showPreview
        }
        if let showLintPanel = state["showLintPanel"] as? Bool {
            self.showLintPanel = showLintPanel
        }
        if let wordWrap = state["wordWrap"] as? Bool {
            self.document.wordWrapEnabled = wordWrap
        }
        if let data = state["remoteFileRef"] as? Data,
           let ref = try? JSONDecoder().decode(RemoteFileReference.self, from: data) {
            self.document.remoteFileRef = ref
        }
    }
}

class TabStore: ObservableObject {
    @Published var tabs: [TabItem] = []
    @Published var selectedTabID: UUID

    private var cancellables = Set<AnyCancellable>()

    init() {
        let initial = TabItem()
        tabs = [initial]
        selectedTabID = initial.id
    }

    var activeTab: TabItem {
        tabs.first { $0.id == selectedTabID } ?? tabs[0]
    }

    @discardableResult
    func newTab() -> TabItem {
        let tab = TabItem()
        tabs.append(tab)
        selectedTabID = tab.id
        return tab
    }

    func closeTab(id: UUID) {
        guard tabs.count > 1 else {
            // Last tab: just reset it
            let tab = tabs[0]
            tab.document.content = ""
            tab.document.fileURL = nil
            tab.document.isDirty = false
            tab.document.fileType = .markdown
            tab.lintEngine.clear()
            tab.goToLine = nil
            return
        }

        if let index = tabs.firstIndex(where: { $0.id == id }) {
            let wasSelected = id == selectedTabID
            tabs.remove(at: index)
            if wasSelected {
                let newIndex = min(index, tabs.count - 1)
                selectedTabID = tabs[newIndex].id
            }
        }
    }

    /// Opens a file URL. If already open in a tab, switches to it; otherwise opens in a new tab.
    func openFile(url: URL) -> TabItem {
        // Check if already open
        if let existing = tabs.first(where: { $0.document.fileURL == url }) {
            selectedTabID = existing.id
            return existing
        }

        // If the active tab is empty (untitled, no content, not dirty), reuse it
        let active = activeTab
        if active.document.fileURL == nil && active.document.content.isEmpty && !active.document.isDirty {
            selectedTabID = active.id
            return active
        }

        // Otherwise create new tab
        let tab = TabItem()
        tabs.append(tab)
        selectedTabID = tab.id
        return tab
    }

    func selectNextTab() {
        guard tabs.count > 1,
              let index = tabs.firstIndex(where: { $0.id == selectedTabID }) else { return }
        let next = (index + 1) % tabs.count
        selectedTabID = tabs[next].id
    }

    func selectPreviousTab() {
        guard tabs.count > 1,
              let index = tabs.firstIndex(where: { $0.id == selectedTabID }) else { return }
        let prev = (index - 1 + tabs.count) % tabs.count
        selectedTabID = tabs[prev].id
    }

    func moveTab(from source: IndexSet, to destination: Int) {
        tabs.move(fromOffsets: source, toOffset: destination)
    }

    /// Opens a remote file. Reuses an empty tab or creates a new one.
    func openRemoteFile(ref: RemoteFileReference) -> TabItem {
        // Check if already open
        if let existing = tabs.first(where: { $0.document.remoteFileRef?.uniqueKey == ref.uniqueKey }) {
            selectedTabID = existing.id
            return existing
        }

        let active = activeTab
        if active.document.fileURL == nil && active.document.remoteFileRef == nil
            && active.document.content.isEmpty && !active.document.isDirty {
            selectedTabID = active.id
            return active
        }

        let tab = TabItem()
        tabs.append(tab)
        selectedTabID = tab.id
        return tab
    }

    /// Returns true if any tab has unsaved changes.
    var hasAnyDirtyTab: Bool {
        tabs.contains { $0.document.isDirty }
    }

    /// Paths of all open tabs for persistence. Remote tabs use a placeholder path.
    var openTabPaths: [String] {
        tabs.map { tab in
            if tab.document.remoteFileRef != nil {
                return "remote://\(tab.document.remoteFileRef!.uniqueKey)"
            }
            return tab.document.fileURL?.path ?? ""
        }.filter { !$0.isEmpty }
    }

    /// Index of the active tab for persistence.
    var activeTabIndex: Int {
        tabs.firstIndex(where: { $0.id == selectedTabID }) ?? 0
    }
}
