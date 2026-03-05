import Foundation

struct RemoteFileReference: Codable, Hashable {
    let profileID: UUID
    let remotePath: String

    var fileName: String {
        (remotePath as NSString).lastPathComponent
    }

    var fileExtension: String {
        (remotePath as NSString).pathExtension.lowercased()
    }

    func displayString(with profileName: String) -> String {
        "\(fileName) — \(profileName)"
    }

    /// Stable key for deduplication.
    var uniqueKey: String {
        "\(profileID.uuidString):\(remotePath)"
    }
}
