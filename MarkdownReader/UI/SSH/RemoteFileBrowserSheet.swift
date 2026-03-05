import SwiftUI

struct RemoteFileBrowserSheet: View {
    let profileID: UUID
    let initialPath: String
    let onFileSelected: (RemoteFileReference) -> Void

    @State private var currentPath: String
    @State private var entries: [RemoteDirectoryEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var filterText: String = ""
    @Environment(\.dismiss) private var dismiss

    init(profileID: UUID, initialPath: String, onFileSelected: @escaping (RemoteFileReference) -> Void) {
        self.profileID = profileID
        self.initialPath = initialPath
        self.onFileSelected = onFileSelected
        _currentPath = State(initialValue: initialPath)
    }

    private var filteredEntries: [RemoteDirectoryEntry] {
        let sorted = entries.sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        if filterText.isEmpty { return sorted }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(filterText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Breadcrumb path bar
            breadcrumbBar

            Divider()

            // Filter
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                TextField("Filter", text: $filterText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.bar)

            Divider()

            // File list
            if isLoading {
                Spacer()
                ProgressView("Loading...")
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.secondary)
                    Button("Retry") { loadDirectory() }
                }
                Spacer()
            } else {
                List(filteredEntries) { entry in
                    HStack(spacing: 8) {
                        Image(systemName: entry.isDirectory ? "folder.fill" : fileIcon(for: entry.name))
                            .foregroundColor(entry.isDirectory ? .accentColor : .secondary)
                            .frame(width: 16)

                        Text(entry.name)
                            .lineLimit(1)

                        Spacer()

                        if !entry.isDirectory {
                            Text(formatSize(entry.size))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        handleDoubleClick(entry)
                    }
                }
                .listStyle(.plain)
            }

            Divider()

            // Bottom bar
            HStack {
                Text(currentPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(10)
        }
        .frame(width: 500, height: 450)
        .onAppear { loadDirectory() }
    }

    // MARK: - Breadcrumb

    private var breadcrumbBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                let components = pathComponents
                ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                    Button(component.name) {
                        navigateTo(component.path)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(index == components.count - 1 ? .primary : .accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    private var pathComponents: [(name: String, path: String)] {
        let parts = currentPath.split(separator: "/", omittingEmptySubsequences: true)
        var result: [(name: String, path: String)] = [("/", "/")]
        var accumulated = ""
        for part in parts {
            accumulated += "/\(part)"
            result.append((String(part), accumulated))
        }
        return result
    }

    // MARK: - Actions

    private func loadDirectory() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                entries = try await RemoteFileIO.listDirectory(path: currentPath, profileID: profileID)
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func navigateTo(_ path: String) {
        currentPath = path
        filterText = ""
        loadDirectory()
    }

    private func handleDoubleClick(_ entry: RemoteDirectoryEntry) {
        if entry.isDirectory {
            navigateTo(entry.path)
        } else {
            let ref = RemoteFileReference(profileID: profileID, remotePath: entry.path)
            onFileSelected(ref)
        }
    }

    private func fileIcon(for name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "md", "markdown": return "doc.richtext"
        case "json": return "curlybraces"
        case "yaml", "yml": return "doc.text"
        case "js", "ts", "jsx", "tsx": return "chevron.left.forwardslash.chevron.right"
        case "css", "scss": return "paintbrush"
        case "html", "htm": return "globe"
        case "log": return "text.alignleft"
        default: return "doc"
        }
    }

    private func formatSize(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
