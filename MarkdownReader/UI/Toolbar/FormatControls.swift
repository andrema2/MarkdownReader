import SwiftUI

struct FormatControls: View {
    @ObservedObject var document: DocumentModel

    var body: some View {
        HStack(spacing: 4) {
            formatButton("Bold", icon: "bold", shortcut: "**", wrapper: true)
            formatButton("Italic", icon: "italic", shortcut: "_", wrapper: true)
            formatButton("Strikethrough", icon: "strikethrough", shortcut: "~~", wrapper: true)
            formatButton("Code", icon: "chevron.left.forwardslash.chevron.right", shortcut: "`", wrapper: true)

            Divider()
                .frame(height: 20)

            headerMenu

            Divider()
                .frame(height: 20)

            formatButton("Link", icon: "link", shortcut: "[text](url)", wrapper: false)
            formatButton("Image", icon: "photo", shortcut: "![alt](url)", wrapper: false)
            formatButton("List", icon: "list.bullet", shortcut: "- ", wrapper: false)
            formatButton("Checklist", icon: "checklist", shortcut: "- [ ] ", wrapper: false)
            formatButton("Quote", icon: "text.quote", shortcut: "> ", wrapper: false)
            formatButton("Divider", icon: "minus", shortcut: "\n---\n", wrapper: false)
        }
    }

    private func formatButton(_ label: String, icon: String, shortcut: String, wrapper: Bool) -> some View {
        Button(action: {
            if wrapper {
                document.updateContent(document.content + shortcut + "text" + shortcut)
            } else {
                document.updateContent(document.content + shortcut)
            }
        }) {
            Image(systemName: icon)
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.borderless)
        .help(label)
    }

    private var headerMenu: some View {
        Menu {
            Button("Heading 1") { insertPrefix("# ") }
            Button("Heading 2") { insertPrefix("## ") }
            Button("Heading 3") { insertPrefix("### ") }
            Button("Heading 4") { insertPrefix("#### ") }
        } label: {
            Image(systemName: "textformat.size")
                .frame(width: 20, height: 20)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Headers")
    }

    private func insertPrefix(_ prefix: String) {
        document.updateContent(document.content + "\n" + prefix)
    }
}
