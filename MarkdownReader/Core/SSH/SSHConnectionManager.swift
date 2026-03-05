import Foundation
import Crypto
import Citadel
import NIOSSH
import NIO

enum SSHError: LocalizedError {
    case passwordRequired
    case keyFileNotAccessible
    case profileNotFound
    case notConnected
    case connectionFailed(String)
    case unsupportedKeyFormat

    var errorDescription: String? {
        switch self {
        case .passwordRequired: return "Password is required for this connection."
        case .keyFileNotAccessible: return "SSH key file is no longer accessible. Please re-select it."
        case .profileNotFound: return "Connection profile not found."
        case .notConnected: return "Not connected to the server."
        case .connectionFailed(let detail): return "Connection failed: \(detail)"
        case .unsupportedKeyFormat: return "Unsupported SSH key format. Only RSA and Ed25519 keys are supported."
        }
    }
}

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
}

/// Wraps an SSH client and its SFTP session for reuse.
final class SSHClientWrapper {
    let client: SSHClient
    let sftp: SFTPClient

    init(client: SSHClient, sftp: SFTPClient) {
        self.client = client
        self.sftp = sftp
    }

    func close() async {
        try? await sftp.close()
        try? await client.close()
    }
}

@MainActor
class SSHConnectionManager: ObservableObject {
    static let shared = SSHConnectionManager()

    @Published var activeConnections: [UUID: SSHClientWrapper] = [:]
    @Published var connectionStates: [UUID: ConnectionState] = [:]

    private init() {}

    /// Connects to a server and opens an SFTP session. Returns the SFTP client.
    @discardableResult
    func connect(profile: SSHConnectionProfile, password: String? = nil) async throws -> SFTPClient {
        connectionStates[profile.id] = .connecting

        do {
            let auth: SSHAuthenticationMethod

            switch profile.authMethod {
            case .password:
                guard let password, !password.isEmpty else { throw SSHError.passwordRequired }
                auth = .passwordBased(username: profile.username, password: password)

            case .privateKey(let bookmarkData):
                guard let resolved = SSHKeyBookmarkManager.resolveKeyFile(from: bookmarkData) else {
                    throw SSHError.keyFileNotAccessible
                }
                auth = try Self.authMethod(
                    fromKeyContent: resolved.keyContent,
                    username: profile.username,
                    passphrase: password
                )
            }

            let client = try await SSHClient.connect(
                host: profile.host,
                port: profile.port,
                authenticationMethod: auth,
                hostKeyValidator: .acceptAnything(),
                reconnect: .never
            )

            let sftp = try await client.openSFTP()
            let wrapper = SSHClientWrapper(client: client, sftp: sftp)

            activeConnections[profile.id] = wrapper
            connectionStates[profile.id] = .connected
            return sftp
        } catch let error as SSHError {
            connectionStates[profile.id] = .error(error.localizedDescription)
            throw error
        } catch {
            let message = error.localizedDescription
            connectionStates[profile.id] = .error(message)
            throw SSHError.connectionFailed(message)
        }
    }

    func disconnect(profileID: UUID) async {
        if let wrapper = activeConnections.removeValue(forKey: profileID) {
            await wrapper.close()
        }
        connectionStates[profileID] = .disconnected
    }

    /// Returns the existing SFTP client or reconnects using the stored profile.
    func reconnectIfNeeded(profileID: UUID) async throws -> SFTPClient {
        if let wrapper = activeConnections[profileID] {
            return wrapper.sftp
        }

        let profiles = SSHConnectionProfile.loadAll()
        guard let profile = profiles.first(where: { $0.id == profileID }) else {
            throw SSHError.profileNotFound
        }

        // Try stored password for auto-reconnect
        let password = SSHKeychainManager.loadPassword(for: profileID)
        return try await connect(profile: profile, password: password)
    }

    // MARK: - Private Key Parsing

    /// Detects key type and returns the appropriate auth method.
    private static func authMethod(fromKeyContent content: String, username: String, passphrase: String?) throws -> SSHAuthenticationMethod {
        let decryptionKey = passphrase.flatMap { $0.isEmpty ? nil : $0.data(using: .utf8) }

        // Try Ed25519 first (most common modern key type)
        if let ed25519Key = try? Curve25519.Signing.PrivateKey(sshEd25519: content, decryptionKey: decryptionKey) {
            let nioKey = NIOSSHPrivateKey(ed25519Key: ed25519Key)
            return .custom(NIOSSHPrivateKeyDelegate(privateKey: nioKey, username: username))
        }

        // Try RSA
        if let rsaKey = try? Insecure.RSA.PrivateKey(sshRsa: content, decryptionKey: decryptionKey) {
            let nioKey = NIOSSHPrivateKey(custom: rsaKey)
            return .custom(NIOSSHPrivateKeyDelegate(privateKey: nioKey, username: username))
        }

        throw SSHError.unsupportedKeyFormat
    }
}

// MARK: - Private Key Auth Delegate

private final class NIOSSHPrivateKeyDelegate: NIOSSHClientUserAuthenticationDelegate, @unchecked Sendable {
    let privateKey: NIOSSHPrivateKey
    let username: String
    private var offered = false

    init(privateKey: NIOSSHPrivateKey, username: String) {
        self.privateKey = privateKey
        self.username = username
    }

    func nextAuthenticationType(
        availableMethods: NIOSSHAvailableUserAuthenticationMethods,
        nextChallengePromise: EventLoopPromise<NIOSSHUserAuthenticationOffer?>
    ) {
        guard !offered else {
            nextChallengePromise.succeed(nil)
            return
        }
        offered = true

        if availableMethods.contains(.publicKey) {
            nextChallengePromise.succeed(.init(
                username: username,
                serviceName: "ssh-connection",
                offer: .privateKey(.init(privateKey: privateKey))
            ))
        } else {
            nextChallengePromise.succeed(nil)
        }
    }
}
