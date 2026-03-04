import Foundation

/// Converts document content between supported formats.
enum FormatConverter {

    /// Attempts to convert content from one format to another.
    /// Returns the transformed string, or nil if no transformation is needed/possible.
    static func convert(_ content: String, from source: DocumentModel.FileType, to target: DocumentModel.FileType) -> String? {
        if source == target { return nil }

        switch (source, target) {
        case (.json, .yaml):
            return jsonToYAML(content)
        case (.yaml, .json):
            return yamlToJSON(content)
        case (.markdown, .plain):
            return stripMarkdown(content)
        case (.plain, .markdown):
            return content // plain text is valid markdown
        default:
            return content // pass-through for unsupported conversions
        }
    }

    /// All format pairs that support content transformation (not just extension rename).
    static func canTransform(from source: DocumentModel.FileType, to target: DocumentModel.FileType) -> Bool {
        let transformable: Set<String> = [
            "json→yaml", "yaml→json",
            "md→txt", "txt→md",
        ]
        return transformable.contains("\(source.rawValue)→\(target.rawValue)")
    }

    // MARK: - JSON ↔ YAML

    private static func jsonToYAML(_ json: String) -> String? {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }
        return yamlString(from: object, indent: 0)
    }

    private static func yamlToJSON(_ yaml: String) -> String? {
        // Simple YAML key: value parser (flat and single-level nested)
        var result: [String: Any] = [:]
        var currentKey: String?
        var currentList: [String]?

        for line in yaml.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            if line.hasPrefix("  - ") || line.hasPrefix("- ") {
                let value = trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces)
                if let key = currentKey {
                    if currentList == nil { currentList = [] }
                    currentList?.append(value)
                    result[key] = currentList
                }
            } else if trimmed.contains(": ") {
                // Save previous list
                if let key = currentKey, let list = currentList {
                    result[key] = list
                }
                currentList = nil

                let parts = trimmed.split(separator: ":", maxSplits: 1)
                let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                let value = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : ""
                currentKey = key

                if value.isEmpty {
                    currentList = []
                } else {
                    result[key] = parseYAMLValue(value)
                }
            } else if trimmed.hasSuffix(":") {
                if let key = currentKey, let list = currentList {
                    result[key] = list
                }
                currentKey = String(trimmed.dropLast())
                currentList = []
            }
        }

        if let key = currentKey, let list = currentList {
            result[key] = list
        }

        guard let data = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private static func parseYAMLValue(_ value: String) -> Any {
        if value == "true" { return true }
        if value == "false" { return false }
        if value == "null" || value == "~" { return NSNull() }
        if let intVal = Int(value) { return intVal }
        if let doubleVal = Double(value) { return doubleVal }
        // Strip quotes
        if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
           (value.hasPrefix("'") && value.hasSuffix("'")) {
            return String(value.dropFirst().dropLast())
        }
        return value
    }

    // MARK: - YAML serializer (simple)

    private static func yamlString(from object: Any, indent: Int) -> String {
        let prefix = String(repeating: "  ", count: indent)

        if let dict = object as? [String: Any] {
            if dict.isEmpty { return "{}" }
            return dict.sorted(by: { $0.key < $1.key }).map { key, value in
                if let arr = value as? [Any] {
                    let items = arr.map { "\(prefix)  - \(yamlScalar($0))" }.joined(separator: "\n")
                    return "\(prefix)\(key):\n\(items)"
                } else if let nested = value as? [String: Any] {
                    return "\(prefix)\(key):\n\(yamlString(from: nested, indent: indent + 1))"
                } else {
                    return "\(prefix)\(key): \(yamlScalar(value))"
                }
            }.joined(separator: "\n")
        }

        if let arr = object as? [Any] {
            return arr.map { "\(prefix)- \(yamlScalar($0))" }.joined(separator: "\n")
        }

        return yamlScalar(object)
    }

    private static func yamlScalar(_ value: Any) -> String {
        switch value {
        case is NSNull: return "null"
        case let b as Bool: return b ? "true" : "false"
        case let i as Int: return "\(i)"
        case let d as Double: return "\(d)"
        case let s as String:
            if s.contains(":") || s.contains("#") || s.contains("\"") || s.isEmpty {
                return "\"\(s.replacingOccurrences(of: "\"", with: "\\\""))\""
            }
            return s
        default: return "\(value)"
        }
    }

    // MARK: - Markdown → Plain

    private static func stripMarkdown(_ md: String) -> String {
        var text = md
        // Headers
        text = text.replacingOccurrences(of: "#{1,6}\\s+", with: "", options: .regularExpression)
        // Bold/italic
        text = text.replacingOccurrences(of: "\\*{1,3}(.+?)\\*{1,3}", with: "$1", options: .regularExpression)
        text = text.replacingOccurrences(of: "_{1,3}(.+?)_{1,3}", with: "$1", options: .regularExpression)
        // Strikethrough
        text = text.replacingOccurrences(of: "~~(.+?)~~", with: "$1", options: .regularExpression)
        // Inline code
        text = text.replacingOccurrences(of: "`(.+?)`", with: "$1", options: .regularExpression)
        // Links [text](url)
        text = text.replacingOccurrences(of: "\\[(.+?)\\]\\(.+?\\)", with: "$1", options: .regularExpression)
        // Images
        text = text.replacingOccurrences(of: "!\\[.*?\\]\\(.+?\\)", with: "", options: .regularExpression)
        // Multiline patterns (blockquotes, rules, list markers)
        text = regexReplace(text, pattern: "^>\\s?", with: "")
        text = regexReplace(text, pattern: "^---+$", with: "")
        text = regexReplace(text, pattern: "^\\s*[-*+]\\s+", with: "")
        text = regexReplace(text, pattern: "^\\s*\\d+\\.\\s+", with: "")
        // Checklist
        text = text.replacingOccurrences(of: "\\[[ x]\\]\\s*", with: "", options: .regularExpression)
        return text
    }

    /// Regex replace with anchorsMatchLines support.
    private static func regexReplace(_ input: String, pattern: String, with template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) else {
            return input
        }
        let range = NSRange(input.startIndex..., in: input)
        return regex.stringByReplacingMatches(in: input, range: range, withTemplate: template)
    }
}
