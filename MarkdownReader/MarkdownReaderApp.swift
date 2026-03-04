import SwiftUI

@main
struct MarkdownReaderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    NSApp.sendAction(#selector(ContentView.openDocument(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}
