import SwiftUI
import AppKit

struct ContentView: View {
    @State private var markdownContent: String = ""
    @State private var currentFileURL: URL?
    @State private var isDragTargeted = false

    var body: some View {
        HSplitView {
            // Source panel
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Source")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    if let url = currentFileURL {
                        Text(url.lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                ScrollView {
                    Text(markdownContent.isEmpty ? "Open or drop a .md file to get started" : markdownContent)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(markdownContent.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .textSelection(.enabled)
                }
            }
            .frame(minWidth: 300)

            // Preview panel
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Preview")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                MarkdownWebView(markdown: markdownContent)
            }
            .frame(minWidth: 300)
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
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: openFile) {
                    Label("Open", systemImage: "doc.text")
                }
            }
        }
    }

    @objc func openDocument(_ sender: Any?) {
        openFile()
    }

    func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "md")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            loadFile(url: url)
        }
    }

    func loadFile(url: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            markdownContent = content
            currentFileURL = url
        } catch {
            markdownContent = "Error loading file: \(error.localizedDescription)"
        }
    }

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            if let data = item as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil),
               url.pathExtension.lowercased() == "md" {
                DispatchQueue.main.async {
                    loadFile(url: url)
                }
            }
        }
        return true
    }
}

#Preview {
    ContentView()
}
