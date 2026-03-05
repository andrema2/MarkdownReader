import SwiftUI

struct SSHConnectionListView: View {
    @ObservedObject var connectionManager = SSHConnectionManager.shared
    @State private var profiles: [SSHConnectionProfile] = SSHConnectionProfile.loadAll()

    let onConnect: (SSHConnectionProfile) -> Void
    let onEdit: (SSHConnectionProfile) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(profiles) { profile in
                HStack(spacing: 8) {
                    statusIndicator(for: profile.id)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name)
                            .font(.system(size: 12, weight: .medium))
                        Text("\(profile.username)@\(profile.host):\(profile.port)")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        onConnect(profile)
                    } label: {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.borderless)
                    .help("Quick connect")

                    Button {
                        onEdit(profile)
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.borderless)
                    .help("Edit")

                    Button {
                        deleteProfile(profile)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.borderless)
                    .help("Delete")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)

                Divider()
            }
        }
    }

    @ViewBuilder
    private func statusIndicator(for profileID: UUID) -> some View {
        let state = connectionManager.connectionStates[profileID] ?? .disconnected
        Circle()
            .fill(stateColor(state))
            .frame(width: 8, height: 8)
    }

    private func stateColor(_ state: ConnectionState) -> Color {
        switch state {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        }
    }

    private func deleteProfile(_ profile: SSHConnectionProfile) {
        profiles.removeAll { $0.id == profile.id }
        SSHKeychainManager.deletePassword(for: profile.id)
        SSHConnectionProfile.saveAll(profiles)
        Task {
            await connectionManager.disconnect(profileID: profile.id)
        }
    }

    // MARK: - Reusable Row

    struct ProfileRow: View {
        let profile: SSHConnectionProfile
        let state: ConnectionState

        var body: some View {
            HStack(spacing: 6) {
                Circle()
                    .fill(rowColor)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 1) {
                    Text(profile.name)
                        .font(.system(size: 12))
                    Text("\(profile.username)@\(profile.host)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }

        private var rowColor: Color {
            switch state {
            case .connected: return .green
            case .connecting: return .yellow
            case .disconnected: return .gray
            case .error: return .red
            }
        }
    }
}
