import SwiftUI

/// Home tab: Clipboard, Font, Paragraph, Editing groups.
struct HomeRibbonTab: View {
    @ObservedObject var document: DocumentModel

    private var isRichText: Bool {
        [.markdown, .html].contains(document.fileType)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Clipboard
            RibbonGroup(label: "Clipboard") {
                RibbonLargeButton("Paste", icon: "doc.on.clipboard") {
                    NSApp.sendAction(Selector(("paste:")), to: nil, from: nil)
                }
                VStack(spacing: 4) {
                    RibbonSmallButton("Cut", icon: "scissors") {
                        NSApp.sendAction(Selector(("cut:")), to: nil, from: nil)
                    }
                    RibbonSmallButton("Copy", icon: "doc.on.doc") {
                        NSApp.sendAction(Selector(("copy:")), to: nil, from: nil)
                    }
                }
            }

            RibbonGroupSeparator()

            // Font — only for rich text formats
            if isRichText {
                RibbonGroup(label: "Font") {
                    RibbonSmallIconButton("Bold", icon: "bold") { wrapSelection("**") }
                    RibbonSmallIconButton("Italic", icon: "italic") { wrapSelection("_") }
                    RibbonSmallIconButton("Strikethrough", icon: "strikethrough") { wrapSelection("~~") }
                    RibbonSmallIconButton("Code", icon: "chevron.left.forwardslash.chevron.right") { wrapSelection("`") }
                    RibbonMenuButton(label: "Headers", icon: "textformat.size") {
                        Button("Heading 1") { prepend("# ") }
                        Button("Heading 2") { prepend("## ") }
                        Button("Heading 3") { prepend("### ") }
                        Button("Heading 4") { prepend("#### ") }
                        Button("Heading 5") { prepend("##### ") }
                        Button("Heading 6") { prepend("###### ") }
                    }
                }

                RibbonGroupSeparator()
            }

            // Paragraph — only for rich text formats
            if isRichText {
                RibbonGroup(label: "Paragraph") {
                    RibbonSmallIconButton("Bullets", icon: "list.bullet") { prepend("- ") }
                    RibbonSmallIconButton("Numbered", icon: "list.number") { prepend("1. ") }
                    RibbonSmallIconButton("Quote", icon: "text.quote") { prepend("> ") }
                    RibbonSmallIconButton("Checklist", icon: "checklist") { prepend("- [ ] ") }
                }

                RibbonGroupSeparator()
            }

            // Editing
            RibbonGroup(label: "Editing") {
                RibbonLargeButton("Find", icon: "magnifyingglass") {
                    NotificationCenter.default.post(name: .toggleFind, object: nil)
                }
                VStack(spacing: 4) {
                    RibbonSmallButton("Replace", icon: "arrow.left.arrow.right") {
                        NotificationCenter.default.post(name: .toggleFindReplace, object: nil)
                    }
                }
            }
        }
    }

    // MARK: - Text Helpers

    private func wrapSelection(_ marker: String) {
        document.updateContent(document.content + marker + "text" + marker)
    }

    private func prepend(_ prefix: String) {
        document.updateContent(document.content + "\n" + prefix)
    }
}
