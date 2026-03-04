import SwiftUI

// MARK: - Shared Components

/// A grouped section of toolbar buttons with an optional label.
struct ToolbarGroup<Content: View>: View {
    let label: String?
    @ViewBuilder let content: () -> Content

    init(_ label: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.content = content
    }

    var body: some View {
        HStack(spacing: 1) {
            if let label {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .padding(.trailing, 4)
            }
            content()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.06))
        )
    }
}

/// A single icon button used inside toolbar groups.
struct ToolbarIconButton: View {
    let label: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .frame(width: 24, height: 22)
        }
        .buttonStyle(.borderless)
        .help(label)
    }
}

/// Separator between toolbar groups.
struct ToolbarSep: View {
    var body: some View {
        Divider()
            .frame(height: 18)
            .padding(.horizontal, 6)
    }
}

// MARK: - Markdown Controls

struct MarkdownControls: View {
    @ObservedObject var document: DocumentModel

    var body: some View {
        HStack(spacing: 0) {
            ToolbarGroup("Text") {
                ToolbarIconButton(label: "Bold", icon: "bold") { wrap("**") }
                ToolbarIconButton(label: "Italic", icon: "italic") { wrap("_") }
                ToolbarIconButton(label: "Strikethrough", icon: "strikethrough") { wrap("~~") }
                ToolbarIconButton(label: "Code", icon: "chevron.left.forwardslash.chevron.right") { wrap("`") }
            }

            ToolbarSep()

            ToolbarGroup("Structure") {
                headerMenu
                ToolbarIconButton(label: "Quote", icon: "text.quote") { prepend("> ") }
                ToolbarIconButton(label: "Divider", icon: "minus") { append("\n---\n") }
            }

            ToolbarSep()

            ToolbarGroup("Insert") {
                ToolbarIconButton(label: "Link", icon: "link") { append("[text](url)") }
                ToolbarIconButton(label: "Image", icon: "photo") { append("![alt](url)") }
                ToolbarIconButton(label: "Bullet List", icon: "list.bullet") { prepend("- ") }
                ToolbarIconButton(label: "Numbered List", icon: "list.number") { prepend("1. ") }
                ToolbarIconButton(label: "Checklist", icon: "checklist") { prepend("- [ ] ") }
                ToolbarIconButton(label: "Code Block", icon: "rectangle.split.3x3") { append("\n```\n\n```\n") }
                ToolbarIconButton(label: "Table", icon: "tablecells") {
                    append("\n| Column 1 | Column 2 |\n|----------|----------|\n| Cell     | Cell     |\n")
                }
            }
        }
    }

    private var headerMenu: some View {
        Menu {
            Button("Heading 1") { prepend("# ") }
            Button("Heading 2") { prepend("## ") }
            Button("Heading 3") { prepend("### ") }
            Button("Heading 4") { prepend("#### ") }
            Button("Heading 5") { prepend("##### ") }
            Button("Heading 6") { prepend("###### ") }
        } label: {
            Image(systemName: "textformat.size")
                .font(.system(size: 12))
                .frame(width: 24, height: 22)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Headers")
    }

    private func wrap(_ marker: String) {
        document.updateContent(document.content + marker + "text" + marker)
    }

    private func prepend(_ prefix: String) {
        document.updateContent(document.content + "\n" + prefix)
    }

    private func append(_ text: String) {
        document.updateContent(document.content + text)
    }
}

// MARK: - JSON Controls

struct JSONControls: View {
    @ObservedObject var document: DocumentModel

    var body: some View {
        HStack(spacing: 0) {
            ToolbarGroup("Format") {
                ToolbarIconButton(label: "Pretty Print", icon: "text.alignleft") {
                    prettyPrint()
                }
                ToolbarIconButton(label: "Compact", icon: "arrow.right.arrow.left") {
                    compact()
                }
            }

            ToolbarSep()

            ToolbarGroup("Insert") {
                ToolbarIconButton(label: "Object {}", icon: "curlybraces") {
                    append("{\n  \n}")
                }
                ToolbarIconButton(label: "Array []", icon: "square.stack") {
                    append("[\n  \n]")
                }
                ToolbarIconButton(label: "Key-Value", icon: "key") {
                    append("\"key\": \"value\"")
                }
            }

            ToolbarSep()

            ToolbarGroup("Validate") {
                ToolbarIconButton(label: "Validate JSON", icon: "checkmark.seal") {
                    validateJSON()
                }
            }
        }
    }

    private func prettyPrint() {
        guard let data = document.content.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: pretty, encoding: .utf8) else { return }
        document.updateContent(str)
    }

    private func compact() {
        guard let data = document.content.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let compact = try? JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys]),
              let str = String(data: compact, encoding: .utf8) else { return }
        document.updateContent(str)
    }

    private func validateJSON() {
        guard let data = document.content.data(using: .utf8) else { return }
        do {
            _ = try JSONSerialization.jsonObject(with: data)
            // Valid — could flash green in future
        } catch {
            // Invalid — lint panel shows the error
        }
    }

    private func append(_ text: String) {
        document.updateContent(document.content + text)
    }
}

// MARK: - YAML Controls

struct YAMLControls: View {
    @ObservedObject var document: DocumentModel

    var body: some View {
        HStack(spacing: 0) {
            ToolbarGroup("Insert") {
                ToolbarIconButton(label: "Key-Value", icon: "key") {
                    append("\nkey: value")
                }
                ToolbarIconButton(label: "List Item", icon: "list.bullet") {
                    append("\n  - item")
                }
                ToolbarIconButton(label: "Nested Object", icon: "list.bullet.indent") {
                    append("\nparent:\n  child: value")
                }
                ToolbarIconButton(label: "Comment", icon: "number") {
                    append("\n# comment")
                }
            }

            ToolbarSep()

            ToolbarGroup("Format") {
                ToolbarIconButton(label: "Sort Keys", icon: "arrow.up.arrow.down") {
                    sortRootKeys()
                }
                ToolbarIconButton(label: "Trim Trailing Spaces", icon: "scissors") {
                    trimTrailing()
                }
            }
        }
    }

    private func sortRootKeys() {
        let lines = document.content.components(separatedBy: .newlines)
        var sections: [(key: String, lines: [String])] = []
        var current: (key: String, lines: [String])?

        for line in lines {
            if !line.isEmpty && !line.hasPrefix(" ") && !line.hasPrefix("\t") && !line.hasPrefix("#") && line.contains(":") {
                if let c = current { sections.append(c) }
                let key = String(line.split(separator: ":").first ?? "")
                current = (key: key, lines: [line])
            } else {
                current?.lines.append(line)
            }
        }
        if let c = current { sections.append(c) }

        let sorted = sections.sorted { $0.key.lowercased() < $1.key.lowercased() }
        document.updateContent(sorted.flatMap(\.lines).joined(separator: "\n"))
    }

    private func trimTrailing() {
        let trimmed = document.content
            .components(separatedBy: .newlines)
            .map { $0.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression) }
            .joined(separator: "\n")
        document.updateContent(trimmed)
    }

    private func append(_ text: String) {
        document.updateContent(document.content + text)
    }
}

// MARK: - JavaScript Controls

struct JSControls: View {
    @ObservedObject var document: DocumentModel

    var body: some View {
        HStack(spacing: 0) {
            ToolbarGroup("Insert") {
                ToolbarIconButton(label: "Function", icon: "function") {
                    append("\nfunction name() {\n  \n}\n")
                }
                ToolbarIconButton(label: "Arrow Function", icon: "arrow.right") {
                    append("\nconst name = () => {\n  \n};\n")
                }
                ToolbarIconButton(label: "Console Log", icon: "text.bubble") {
                    append("\nconsole.log();")
                }
                ToolbarIconButton(label: "If Block", icon: "questionmark.diamond") {
                    append("\nif (condition) {\n  \n}\n")
                }
                ToolbarIconButton(label: "Try-Catch", icon: "exclamationmark.shield") {
                    append("\ntry {\n  \n} catch (error) {\n  console.error(error);\n}\n")
                }
            }

            ToolbarSep()

            ToolbarGroup("Comment") {
                ToolbarIconButton(label: "Line Comment", icon: "text.line.first.and.arrowtriangle.forward") {
                    append("\n// ")
                }
                ToolbarIconButton(label: "Block Comment", icon: "text.justify.left") {
                    append("\n/* */")
                }
                ToolbarIconButton(label: "JSDoc", icon: "doc.text") {
                    append("\n/**\n * \n * @param {type} name\n * @returns {type}\n */")
                }
            }
        }
    }

    private func append(_ text: String) {
        document.updateContent(document.content + text)
    }
}

// MARK: - Plain Text Controls

struct PlainTextControls: View {
    @ObservedObject var document: DocumentModel

    var body: some View {
        HStack(spacing: 0) {
            ToolbarGroup("Edit") {
                ToolbarIconButton(label: "Sort Lines", icon: "arrow.up.arrow.down") {
                    sortLines()
                }
                ToolbarIconButton(label: "Remove Empty Lines", icon: "line.3.horizontal.decrease") {
                    removeEmptyLines()
                }
                ToolbarIconButton(label: "Trim Lines", icon: "scissors") {
                    trimLines()
                }
                ToolbarIconButton(label: "Remove Duplicates", icon: "minus.circle") {
                    removeDuplicates()
                }
            }

            ToolbarSep()

            ToolbarGroup("Case") {
                ToolbarIconButton(label: "UPPERCASE", icon: "textformat.abc") {
                    document.updateContent(document.content.uppercased())
                }
                ToolbarIconButton(label: "lowercase", icon: "textformat.abc.dottedunderline") {
                    document.updateContent(document.content.lowercased())
                }
            }
        }
    }

    private func sortLines() {
        let sorted = document.content.components(separatedBy: .newlines).sorted()
        document.updateContent(sorted.joined(separator: "\n"))
    }

    private func removeEmptyLines() {
        let filtered = document.content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        document.updateContent(filtered.joined(separator: "\n"))
    }

    private func trimLines() {
        let trimmed = document.content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        document.updateContent(trimmed.joined(separator: "\n"))
    }

    private func removeDuplicates() {
        var seen = Set<String>()
        let unique = document.content.components(separatedBy: .newlines)
            .filter { seen.insert($0).inserted }
        document.updateContent(unique.joined(separator: "\n"))
    }
}
