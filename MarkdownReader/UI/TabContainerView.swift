import SwiftUI
import AppKit

struct TabContainerView: View {
    @StateObject private var tabStore = TabStore()
    @EnvironmentObject var fileOpenRequest: FileOpenRequest
    @State private var showRemoteConnectionSheet = false

    var body: some View {
        mainContent
            .modifier(TabNotificationHandler(tabStore: tabStore, loadFile: loadFile, saveActiveTab: saveActiveTab, saveActiveTabAs: saveActiveTabAs, updateWindow: updateWindowForActiveTab))
            .modifier(TabStateHandler(tabStore: tabStore, fileOpenRequest: fileOpenRequest, loadFile: loadFile, updateWindow: updateWindowForActiveTab, persist: persistOpenTabs))
            .onReceive(NotificationCenter.default.publisher(for: .openRemoteDocument)) { _ in
                showRemoteConnectionSheet = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .openRemoteFile)) { notification in
                if let ref = notification.object as? RemoteFileReference {
                    let tab = tabStore.openRemoteFile(ref: ref)
                    loadRemoteFile(ref: ref, into: tab)
                }
            }
            .sheet(isPresented: $showRemoteConnectionSheet) {
                SSHConnectionSheet { ref in
                    let tab = tabStore.openRemoteFile(ref: ref)
                    loadRemoteFile(ref: ref, into: tab)
                }
            }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            EditorView(tab: tabStore.activeTab)
                .id(tabStore.selectedTabID)
        }
        .frame(minWidth: 700, minHeight: 500)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(tabStore.tabs) { tab in
                    TabButtonView(tab: tab, isSelected: tab.id == tabStore.selectedTabID, onSelect: {
                        tabStore.selectedTabID = tab.id
                    }, onClose: {
                        tabStore.closeTab(id: tab.id)
                        updateWindowForActiveTab()
                    })
                }

                Button(action: { tabStore.newTab() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 11))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 36)
        .background(.bar)
    }

    // MARK: - File Operations

    private func loadFile(url: URL, into tab: TabItem) {
        do {
            let (content, encoding) = try FileIO.read(from: url)
            tab.document.content = content
            tab.document.fileURL = url
            tab.document.encoding = encoding
            tab.document.fileType = .from(extension: url.pathExtension)
            tab.document.isDirty = false
            tab.goToLine = nil
            tab.lintEngine.run(content: content, fileExtension: tab.document.fileExtension)
            FileIO.saveBookmark(for: url)
            updateWindowForActiveTab()
            persistOpenTabs()
        } catch {
            tab.document.content = "Error loading file: \(error.localizedDescription)"
        }
    }

    private func saveActiveTab() {
        let tab = tabStore.activeTab
        if tab.document.isRemote {
            saveRemoteTab()
            return
        }
        if let url = tab.document.fileURL {
            do {
                try FileIO.write(tab.document.content, to: url, encoding: tab.document.encoding)
                tab.document.markClean()
                updateWindowForActiveTab()
            } catch {
                // TODO: show alert
            }
        } else {
            saveActiveTabAs()
        }
    }

    private func saveRemoteTab() {
        let tab = tabStore.activeTab
        guard let ref = tab.document.remoteFileRef else { return }
        Task {
            do {
                try await RemoteFileIO.write(tab.document.content, to: ref, encoding: tab.document.encoding)
                await MainActor.run {
                    tab.document.markClean()
                    updateWindowForActiveTab()
                }
            } catch {
                await MainActor.run {
                    let alert = NSAlert()
                    alert.messageText = "Failed to save remote file"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "Retry")
                    alert.addButton(withTitle: "Save Locally")
                    alert.addButton(withTitle: "Cancel")
                    let response = alert.runModal()
                    if response == .alertFirstButtonReturn {
                        saveRemoteTab()
                    } else if response == .alertSecondButtonReturn {
                        saveActiveTabAs()
                    }
                }
            }
        }
    }

    private func loadRemoteFile(ref: RemoteFileReference, into tab: TabItem) {
        Task {
            do {
                let (content, encoding) = try await RemoteFileIO.read(ref: ref)
                await MainActor.run {
                    tab.document.content = content
                    tab.document.remoteFileRef = ref
                    tab.document.fileURL = nil
                    tab.document.encoding = encoding
                    tab.document.fileType = .from(extension: ref.fileExtension)
                    tab.document.isDirty = false
                    tab.lintEngine.run(content: content, fileExtension: ref.fileExtension)
                    updateWindowForActiveTab()
                    persistOpenTabs()
                }
            } catch {
                await MainActor.run {
                    tab.document.content = "Error loading remote file: \(error.localizedDescription)"
                }
            }
        }
    }

    private func saveActiveTabAs() {
        let tab = tabStore.activeTab
        FileIO.save(suggestedName: tab.document.fileName) { url in
            guard let url else { return }
            do {
                try FileIO.write(tab.document.content, to: url, encoding: tab.document.encoding)
                tab.document.fileURL = url
                tab.document.fileType = .from(extension: url.pathExtension)
                tab.document.markClean()
                updateWindowForActiveTab()
                persistOpenTabs()
            } catch {
                // TODO: show alert
            }
        }
    }

    private func updateWindowForActiveTab() {
        let tab = tabStore.activeTab
        if let ref = tab.document.remoteFileRef {
            NSApp.mainWindow?.representedURL = nil
            let profiles = SSHConnectionProfile.loadAll()
            let profileName = profiles.first(where: { $0.id == ref.profileID })?.name ?? "Remote"
            NSApp.mainWindow?.title = "\(ref.fileName) — \(profileName)"
        } else if let url = tab.document.fileURL {
            NSApp.mainWindow?.representedURL = url
            NSApp.mainWindow?.title = url.lastPathComponent
        } else {
            NSApp.mainWindow?.representedURL = nil
            NSApp.mainWindow?.title = "Untitled"
        }
        NSApp.mainWindow?.isDocumentEdited = tabStore.hasAnyDirtyTab
    }

    private func persistOpenTabs() {
        UserDefaults.standard.set(tabStore.openTabPaths, forKey: "openTabs")
        UserDefaults.standard.set(tabStore.activeTabIndex, forKey: "activeTabIndex")
        if let url = tabStore.activeTab.document.fileURL {
            UserDefaults.standard.set(url.path, forKey: "lastOpenedFile")
        }

        // Persist full tab session state (preview, lint panel, word wrap per tab)
        let tabStates = tabStore.tabs.map { $0.sessionState }
        UserDefaults.standard.set(tabStates, forKey: "tabSessionStates")
    }
}

// MARK: - Tab Button

struct TabButtonView: View {
    @ObservedObject var tab: TabItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            if tab.document.isRemote {
                Image(systemName: "network")
                    .font(.system(size: 10))
                    .foregroundStyle(.blue)
            } else {
                Image(systemName: tab.document.fileType.icon)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Text(tab.document.fileName)
                .font(.system(size: 12))
                .lineLimit(1)

            if tab.document.isDirty {
                Circle()
                    .fill(Color.primary.opacity(0.5))
                    .frame(width: 6, height: 6)
            }

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
            .opacity(isSelected ? 1 : 0.5)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}

// MARK: - Notification Handler Modifier

struct TabNotificationHandler: ViewModifier {
    @ObservedObject var tabStore: TabStore
    let loadFile: (URL, TabItem) -> Void
    let saveActiveTab: () -> Void
    let saveActiveTabAs: () -> Void
    let updateWindow: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .newDocument)) { _ in
                tabStore.newTab()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openDocument)) { _ in
                FileIO.open { url in
                    guard let url else { return }
                    let tab = tabStore.openFile(url: url)
                    loadFile(url, tab)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .saveDocument)) { _ in
                saveActiveTab()
            }
            .onReceive(NotificationCenter.default.publisher(for: .saveDocumentAs)) { _ in
                saveActiveTabAs()
            }
            .onReceive(NotificationCenter.default.publisher(for: .togglePreview)) { _ in
                tabStore.activeTab.showPreview.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleLintPanel)) { _ in
                tabStore.activeTab.showLintPanel.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleFind)) { _ in
                let tab = tabStore.activeTab
                if tab.showFindPanel && !tab.findReplaceMode {
                    tab.showFindPanel = false
                    tab.findEngine.matches = []
                    tab.findEngine.currentMatchIndex = -1
                } else {
                    tab.showFindPanel = true
                    tab.findReplaceMode = false
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleFindReplace)) { _ in
                let tab = tabStore.activeTab
                if tab.showFindPanel && tab.findReplaceMode {
                    tab.showFindPanel = false
                    tab.findEngine.matches = []
                    tab.findEngine.currentMatchIndex = -1
                } else {
                    tab.showFindPanel = true
                    tab.findReplaceMode = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .closeFindPanel)) { _ in
                let tab = tabStore.activeTab
                tab.showFindPanel = false
                tab.findEngine.matches = []
                tab.findEngine.currentMatchIndex = -1
            }
            .onReceive(NotificationCenter.default.publisher(for: .findReplaceCurrent)) { _ in
                let tab = tabStore.activeTab
                tab.findEngine.replaceCurrent(in: &tab.document.content)
                tab.document.isDirty = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .findReplaceAll)) { _ in
                let tab = tabStore.activeTab
                tab.findEngine.replaceAll(in: &tab.document.content)
                tab.document.isDirty = true
            }
    }
}

// MARK: - Tab State Handler Modifier

struct TabStateHandler: ViewModifier {
    @ObservedObject var tabStore: TabStore
    @ObservedObject var fileOpenRequest: FileOpenRequest
    let loadFile: (URL, TabItem) -> Void
    let updateWindow: () -> Void
    let persist: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .newTab)) { _ in
                tabStore.newTab()
            }
            .onReceive(NotificationCenter.default.publisher(for: .closeTab)) { _ in
                tabStore.closeTab(id: tabStore.selectedTabID)
                updateWindow()
            }
            .onReceive(NotificationCenter.default.publisher(for: .nextTab)) { _ in
                tabStore.selectNextTab()
                updateWindow()
            }
            .onReceive(NotificationCenter.default.publisher(for: .previousTab)) { _ in
                tabStore.selectPreviousTab()
                updateWindow()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openFileFromFinder)) { notification in
                if let url = notification.object as? URL {
                    let tab = tabStore.openFile(url: url)
                    loadFile(url, tab)
                }
            }
            .onChange(of: fileOpenRequest.url) {
                if let url = fileOpenRequest.url {
                    let tab = tabStore.openFile(url: url)
                    loadFile(url, tab)
                    fileOpenRequest.url = nil
                }
            }
            .onChange(of: tabStore.selectedTabID) {
                updateWindow()
            }
            .onChange(of: tabStore.tabs.count) {
                persist()
            }
            .onReceive(NotificationCenter.default.publisher(for: .restoreTabState)) { notification in
                if let state = notification.object as? [String: Any] {
                    // Apply state to the most recently opened tab
                    tabStore.activeTab.restore(from: state)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .restoreActiveTabIndex)) { notification in
                if let index = notification.object as? Int,
                   index >= 0 && index < tabStore.tabs.count {
                    tabStore.selectedTabID = tabStore.tabs[index].id
                }
            }
    }
}
