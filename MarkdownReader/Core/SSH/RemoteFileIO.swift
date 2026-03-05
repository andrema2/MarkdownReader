import Foundation
import Citadel
import NIO

struct RemoteDirectoryEntry: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let isDirectory: Bool
    let size: UInt64
    let modificationDate: Date?
}

struct RemoteFileIO {
    /// Reads a remote file and returns its content with detected encoding.
    static func read(ref: RemoteFileReference) async throws -> (String, String.Encoding) {
        let sftp = try await SSHConnectionManager.shared.reconnectIfNeeded(profileID: ref.profileID)

        let buffer = try await sftp.withFile(filePath: ref.remotePath, flags: .read) { file in
            try await file.readAll()
        }

        let data = Data(buffer: buffer)

        // Try UTF-8, fall back to ISO Latin 1
        if let content = String(data: data, encoding: .utf8) {
            return (content, .utf8)
        } else if let content = String(data: data, encoding: .isoLatin1) {
            return (content, .isoLatin1)
        } else {
            return (String(decoding: data, as: UTF8.self), .utf8)
        }
    }

    /// Writes content to a remote file.
    static func write(_ content: String, to ref: RemoteFileReference, encoding: String.Encoding = .utf8) async throws {
        let sftp = try await SSHConnectionManager.shared.reconnectIfNeeded(profileID: ref.profileID)
        guard let data = content.data(using: encoding) else {
            throw SSHError.connectionFailed("Failed to encode content.")
        }

        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.writeBytes(data)

        try await sftp.withFile(filePath: ref.remotePath, flags: [.write, .create, .truncate]) { file in
            try await file.write(buffer)
        }
    }

    /// Lists a remote directory's contents.
    static func listDirectory(path: String, profileID: UUID) async throws -> [RemoteDirectoryEntry] {
        let sftp = try await SSHConnectionManager.shared.reconnectIfNeeded(profileID: profileID)
        let nameMessages = try await sftp.listDirectory(atPath: path)

        var entries: [RemoteDirectoryEntry] = []
        for nameMessage in nameMessages {
            for component in nameMessage.components {
                let name = component.filename
                guard name != "." && name != ".." else { continue }

                let fullPath = path.hasSuffix("/") ? "\(path)\(name)" : "\(path)/\(name)"

                // Check if directory via permissions (bit 14 = directory in POSIX)
                let isDir: Bool
                if let perms = component.attributes.permissions {
                    isDir = (perms & 0o40000) != 0
                } else {
                    // Fallback: check longname which is ls -l format
                    isDir = component.longname.hasPrefix("d")
                }

                let size = component.attributes.size ?? 0
                let mtime = component.attributes.accessModificationTime?.modificationTime

                entries.append(RemoteDirectoryEntry(
                    name: name,
                    path: fullPath,
                    isDirectory: isDir,
                    size: size,
                    modificationDate: mtime
                ))
            }
        }
        return entries
    }
}
