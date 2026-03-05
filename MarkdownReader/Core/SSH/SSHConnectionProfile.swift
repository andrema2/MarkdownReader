import Foundation

struct SSHConnectionProfile: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var host: String
    var port: Int = 22
    var username: String
    var authMethod: AuthMethod = .password
    var defaultRemotePath: String = "/"

    enum AuthMethod: Codable, Hashable {
        case password
        case privateKey(bookmarkData: Data)
    }

    // MARK: - Persistence

    private static let defaultsKey = "sshConnectionProfiles"

    static func loadAll() -> [SSHConnectionProfile] {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return [] }
        return (try? JSONDecoder().decode([SSHConnectionProfile].self, from: data)) ?? []
    }

    static func saveAll(_ profiles: [SSHConnectionProfile]) {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}
