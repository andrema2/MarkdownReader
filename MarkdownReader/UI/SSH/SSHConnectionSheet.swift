import SwiftUI

struct SSHConnectionSheet: View {
    @ObservedObject var connectionManager = SSHConnectionManager.shared
    @State private var profiles: [SSHConnectionProfile] = SSHConnectionProfile.loadAll()
    @State private var selectedProfileID: UUID?
    @State private var editingProfile = SSHConnectionProfile(name: "", host: "", username: "")
    @State private var password: String = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?
    @State private var showFileBrowser = false
    @State private var connectedSFTPProfileID: UUID?
    @Environment(\.dismiss) private var dismiss

    let onFileSelected: (RemoteFileReference) -> Void

    var body: some View {
        HSplitView {
            profileList
                .frame(minWidth: 180, maxWidth: 220)

            formView
                .frame(minWidth: 320)
        }
        .frame(width: 580, height: 420)
        .sheet(isPresented: $showFileBrowser) {
            if let profileID = connectedSFTPProfileID,
               let profile = profiles.first(where: { $0.id == profileID }) {
                RemoteFileBrowserSheet(profileID: profileID, initialPath: profile.defaultRemotePath) { ref in
                    showFileBrowser = false
                    dismiss()
                    onFileSelected(ref)
                }
            }
        }
    }

    // MARK: - Profile List

    private var profileList: some View {
        VStack(spacing: 0) {
            List(selection: $selectedProfileID) {
                ForEach(profiles) { profile in
                    SSHConnectionListView.ProfileRow(
                        profile: profile,
                        state: connectionManager.connectionStates[profile.id] ?? .disconnected
                    )
                    .tag(profile.id)
                }
            }
            .listStyle(.sidebar)
            .onChange(of: selectedProfileID) {
                if let id = selectedProfileID, let profile = profiles.first(where: { $0.id == id }) {
                    editingProfile = profile
                    password = SSHKeychainManager.loadPassword(for: id) ?? ""
                }
            }

            Divider()

            HStack {
                Button(action: addProfile) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)

                Button(action: deleteSelectedProfile) {
                    Image(systemName: "minus")
                }
                .buttonStyle(.borderless)
                .disabled(selectedProfileID == nil)

                Spacer()
            }
            .padding(6)
        }
    }

    // MARK: - Form

    private var formView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Form {
                TextField("Name:", text: $editingProfile.name)
                TextField("Host:", text: $editingProfile.host)
                TextField("Port:", value: $editingProfile.port, format: .number)
                TextField("Username:", text: $editingProfile.username)

                Picker("Auth:", selection: authMethodBinding) {
                    Text("Password").tag(0)
                    Text("Private Key").tag(1)
                }
                .pickerStyle(.segmented)

                if case .privateKey = editingProfile.authMethod {
                    HStack {
                        Text(keyFileName)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Button("Select Key File...") {
                            SSHKeyBookmarkManager.selectKeyFile { data in
                                if let data {
                                    editingProfile.authMethod = .privateKey(bookmarkData: data)
                                }
                            }
                        }
                    }

                    SecureField("Passphrase (optional):", text: $password)
                } else {
                    SecureField("Password:", text: $password)
                }

                TextField("Default Path:", text: $editingProfile.defaultRemotePath)
            }
            .formStyle(.grouped)

            if let error = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .padding(.horizontal)
            }

            Spacer()

            HStack {
                Spacer()

                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("Save") { saveProfile() }

                Button(isConnecting ? "Connecting..." : "Connect") {
                    connectToProfile()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isConnecting || editingProfile.host.isEmpty || editingProfile.username.isEmpty)
            }
            .padding()
        }
    }

    // MARK: - Helpers

    private var authMethodBinding: Binding<Int> {
        Binding(
            get: {
                if case .privateKey = editingProfile.authMethod { return 1 }
                return 0
            },
            set: { newValue in
                editingProfile.authMethod = newValue == 1 ? .privateKey(bookmarkData: Data()) : .password
            }
        )
    }

    private var keyFileName: String {
        if case .privateKey(let data) = editingProfile.authMethod,
           !data.isEmpty,
           let resolved = SSHKeyBookmarkManager.resolveKeyFile(from: data) {
            return resolved.url.lastPathComponent
        }
        return "No key selected"
    }

    private func addProfile() {
        let profile = SSHConnectionProfile(name: "New Server", host: "", username: "")
        profiles.append(profile)
        selectedProfileID = profile.id
        editingProfile = profile
        password = ""
        SSHConnectionProfile.saveAll(profiles)
    }

    private func deleteSelectedProfile() {
        guard let id = selectedProfileID else { return }
        profiles.removeAll { $0.id == id }
        SSHKeychainManager.deletePassword(for: id)
        selectedProfileID = profiles.first?.id
        SSHConnectionProfile.saveAll(profiles)
    }

    private func saveProfile() {
        if let index = profiles.firstIndex(where: { $0.id == editingProfile.id }) {
            profiles[index] = editingProfile
        } else {
            profiles.append(editingProfile)
        }
        SSHConnectionProfile.saveAll(profiles)

        if !password.isEmpty {
            SSHKeychainManager.savePassword(password, for: editingProfile.id)
        }
    }

    private func connectToProfile() {
        saveProfile()
        isConnecting = true
        errorMessage = nil

        Task {
            do {
                try await connectionManager.connect(profile: editingProfile, password: password.isEmpty ? nil : password)
                connectedSFTPProfileID = editingProfile.id
                showFileBrowser = true
                isConnecting = false
            } catch {
                errorMessage = error.localizedDescription
                isConnecting = false
            }
        }
    }
}
