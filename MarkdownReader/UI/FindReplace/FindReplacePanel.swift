import SwiftUI

struct FindReplacePanel: View {
    @ObservedObject var engine: FindReplaceEngine
    let showReplace: Bool
    let onClose: () -> Void

    @FocusState private var searchFieldFocused: Bool

    var body: some View {
        VStack(spacing: 4) {
            // Find row
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))

                TextField("Find", text: $engine.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .focused($searchFieldFocused)
                    .onSubmit { engine.nextMatch() }

                // Option toggles
                OptionToggle("Aa", isOn: $engine.caseSensitive, help: "Case Sensitive")
                OptionToggle(".*", isOn: $engine.useRegex, help: "Regular Expression")
                OptionToggle("W", isOn: $engine.wholeWord, help: "Whole Word")

                Divider()
                    .frame(height: 16)

                // Navigation
                Button(action: { engine.previousMatch() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .disabled(engine.matches.isEmpty)
                .help("Previous Match")

                Button(action: { engine.nextMatch() }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .disabled(engine.matches.isEmpty)
                .help("Next Match")

                // Match counter
                Text(matchCountText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 50)

                Spacer()

                // Close button
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close (Esc)")
            }

            // Replace row
            if showReplace {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))

                    TextField("Replace", text: $engine.replaceText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .onSubmit {
                            NotificationCenter.default.post(name: .findReplaceCurrent, object: nil)
                        }

                    Spacer()

                    Button("Replace") {
                        NotificationCenter.default.post(name: .findReplaceCurrent, object: nil)
                    }
                    .controlSize(.small)
                    .disabled(engine.matches.isEmpty)

                    Button("Replace All") {
                        NotificationCenter.default.post(name: .findReplaceAll, object: nil)
                    }
                    .controlSize(.small)
                    .disabled(engine.matches.isEmpty)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.bar)
        .onAppear {
            searchFieldFocused = true
        }
    }

    private var matchCountText: String {
        if engine.searchText.isEmpty {
            return ""
        }
        if engine.matches.isEmpty {
            return "No results"
        }
        return "\(engine.currentMatchIndex + 1) of \(engine.matches.count)"
    }
}

// MARK: - Option Toggle Button

private struct OptionToggle: View {
    let label: String
    @Binding var isOn: Bool
    let help: String

    init(_ label: String, isOn: Binding<Bool>, help: String) {
        self.label = label
        self._isOn = isOn
        self.help = help
    }

    var body: some View {
        Button(action: { isOn.toggle() }) {
            Text(label)
                .font(.system(size: 11, weight: isOn ? .bold : .regular, design: .monospaced))
                .foregroundStyle(isOn ? .primary : .secondary)
                .frame(width: 22, height: 18)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isOn ? Color.accentColor.opacity(0.2) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(isOn ? Color.accentColor.opacity(0.4) : Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
