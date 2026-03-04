import SwiftUI

@main
struct MarkEditApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            EditorView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New") {
                    NotificationCenter.default.post(name: .newDocument, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Open...") {
                    NotificationCenter.default.post(name: .openDocument, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Save") {
                    NotificationCenter.default.post(name: .saveDocument, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)

                Button("Save As...") {
                    NotificationCenter.default.post(name: .saveDocumentAs, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }
}

extension Notification.Name {
    static let newDocument = Notification.Name("newDocument")
    static let openDocument = Notification.Name("openDocument")
    static let saveDocument = Notification.Name("saveDocument")
    static let saveDocumentAs = Notification.Name("saveDocumentAs")
}
