import SwiftUI

@main
struct MarkEditApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openURL) private var openURL

    var body: some Scene {
        WindowGroup {
            TabContainerView()
                .environmentObject(appDelegate.fileOpenRequest)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New") {
                    NotificationCenter.default.post(name: .newDocument, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("New Tab") {
                    NotificationCenter.default.post(name: .newTab, object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)

                Button("Open...") {
                    NotificationCenter.default.post(name: .openDocument, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Open Remote...") {
                    NotificationCenter.default.post(name: .openRemoteDocument, object: nil)
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])

                Divider()

                Button("Close Tab") {
                    NotificationCenter.default.post(name: .closeTab, object: nil)
                }
                .keyboardShortcut("w", modifiers: .command)

                Divider()

                Button("Save") {
                    NotificationCenter.default.post(name: .saveDocument, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)

                Button("Save As...") {
                    NotificationCenter.default.post(name: .saveDocumentAs, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }

            CommandGroup(replacing: .textEditing) {
                Button("Find...") {
                    NotificationCenter.default.post(name: .toggleFind, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Find and Replace...") {
                    NotificationCenter.default.post(name: .toggleFindReplace, object: nil)
                }
                .keyboardShortcut("h", modifiers: .command)
            }

            CommandGroup(after: .toolbar) {
                Button("Toggle Preview") {
                    NotificationCenter.default.post(name: .togglePreview, object: nil)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])

                Button("Toggle Lint Panel") {
                    NotificationCenter.default.post(name: .toggleLintPanel, object: nil)
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])

                Divider()

                Button("Next Tab") {
                    NotificationCenter.default.post(name: .nextTab, object: nil)
                }
                .keyboardShortcut(KeyEquivalent("\t"), modifiers: .control)

                Button("Previous Tab") {
                    NotificationCenter.default.post(name: .previousTab, object: nil)
                }
                .keyboardShortcut(KeyEquivalent("\t"), modifiers: [.control, .shift])
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let newDocument = Notification.Name("newDocument")
    static let openDocument = Notification.Name("openDocument")
    static let saveDocument = Notification.Name("saveDocument")
    static let saveDocumentAs = Notification.Name("saveDocumentAs")
    static let togglePreview = Notification.Name("togglePreview")
    static let toggleLintPanel = Notification.Name("toggleLintPanel")
    static let openFileFromFinder = Notification.Name("openFileFromFinder")
    static let newTab = Notification.Name("newTab")
    static let closeTab = Notification.Name("closeTab")
    static let nextTab = Notification.Name("nextTab")
    static let previousTab = Notification.Name("previousTab")
    static let toggleFind = Notification.Name("toggleFind")
    static let toggleFindReplace = Notification.Name("toggleFindReplace")
    static let findReplaceCurrent = Notification.Name("findReplaceCurrent")
    static let findReplaceAll = Notification.Name("findReplaceAll")
    static let closeFindPanel = Notification.Name("closeFindPanel")
    static let restoreTabState = Notification.Name("restoreTabState")
    static let restoreActiveTabIndex = Notification.Name("restoreActiveTabIndex")
    static let toggleBookmark = Notification.Name("toggleBookmark")
    static let nextBookmark = Notification.Name("nextBookmark")
    static let previousBookmark = Notification.Name("previousBookmark")
    static let showDiff = Notification.Name("showDiff")
    static let openRemoteDocument = Notification.Name("openRemoteDocument")
    static let openRemoteFile = Notification.Name("openRemoteFile")
}
