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
        case (.markdown, .html):
            return markdownToHTML(content)
        case (.html, .markdown):
            return htmlToMarkdown(content)
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
            "md→html", "html→md",
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

    // MARK: - Markdown → HTML

    private static func markdownToHTML(_ md: String) -> String {
        var lines = md.components(separatedBy: "\n")
        var html = ""
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Fenced code block
            if trimmed.hasPrefix("```") {
                let lang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var codeLines: [String] = []
                i += 1
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(escapeHTML(lines[i]))
                    i += 1
                }
                let langAttr = lang.isEmpty ? "" : " class=\"language-\(lang)\""
                html += "<pre><code\(langAttr)>\(codeLines.joined(separator: "\n"))</code></pre>\n"
                i += 1
                continue
            }

            // Table
            if trimmed.contains("|") && i + 1 < lines.count {
                let nextTrimmed = lines[i + 1].trimmingCharacters(in: .whitespaces)
                if nextTrimmed.contains("|") && nextTrimmed.contains("-") {
                    html += convertTable(lines: lines, from: &i)
                    continue
                }
            }

            // Heading
            if trimmed.hasPrefix("#") {
                var level = 0
                for ch in trimmed { if ch == "#" { level += 1 } else { break } }
                if level >= 1, level <= 6, trimmed.count > level {
                    let text = String(trimmed.dropFirst(level)).trimmingCharacters(in: .whitespaces)
                    html += "<h\(level)>\(inlineToHTML(text))</h\(level)>\n"
                    i += 1
                    continue
                }
            }

            // Horizontal rule
            if trimmed.count >= 3 {
                let dashes = trimmed.filter { $0 == "-" }.count
                let stars = trimmed.filter { $0 == "*" }.count
                let underscores = trimmed.filter { $0 == "_" }.count
                let isRule = trimmed.allSatisfy({ $0 == "-" || $0 == "*" || $0 == "_" || $0 == " " }) &&
                    (dashes >= 3 || stars >= 3 || underscores >= 3)
                if isRule {
                    html += "<hr>\n"
                    i += 1
                    continue
                }
            }

            // Blockquote
            if trimmed.hasPrefix(">") {
                var quoteLines: [String] = []
                while i < lines.count {
                    let ql = lines[i].trimmingCharacters(in: .whitespaces)
                    guard ql.hasPrefix(">") else { break }
                    quoteLines.append(String(ql.dropFirst()).trimmingCharacters(in: .whitespaces))
                    i += 1
                }
                let inner = quoteLines.map { "<p>\(inlineToHTML($0))</p>" }.joined(separator: "\n")
                html += "<blockquote>\n\(inner)\n</blockquote>\n"
                continue
            }

            // Unordered list
            if trimmed.range(of: #"^[-*+]\s+"#, options: .regularExpression) != nil {
                html += convertList(lines: lines, from: &i, ordered: false)
                continue
            }

            // Ordered list
            if trimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) != nil {
                html += convertList(lines: lines, from: &i, ordered: true)
                continue
            }

            // Empty line
            if trimmed.isEmpty {
                i += 1
                continue
            }

            // Paragraph
            var paraLines: [String] = []
            while i < lines.count {
                let pl = lines[i].trimmingCharacters(in: .whitespaces)
                if pl.isEmpty || pl.hasPrefix("#") || pl.hasPrefix("```") || pl.hasPrefix(">") ||
                   pl.range(of: #"^[-*+]\s+"#, options: .regularExpression) != nil ||
                   pl.range(of: #"^\d+\.\s+"#, options: .regularExpression) != nil {
                    break
                }
                paraLines.append(pl)
                i += 1
            }
            html += "<p>\(paraLines.map { inlineToHTML($0) }.joined(separator: "\n"))</p>\n"
        }

        return html
    }

    private static func convertTable(lines: [String], from i: inout Int) -> String {
        let headers = splitTableCells(lines[i])
        i += 2 // skip header + separator
        var rows: [[String]] = []
        while i < lines.count {
            let row = lines[i].trimmingCharacters(in: .whitespaces)
            guard row.contains("|") else { break }
            rows.append(splitTableCells(row))
            i += 1
        }
        var html = "<table>\n<thead>\n<tr>\n"
        for h in headers { html += "<th>\(inlineToHTML(h))</th>\n" }
        html += "</tr>\n</thead>\n<tbody>\n"
        for row in rows {
            html += "<tr>\n"
            for cell in row { html += "<td>\(inlineToHTML(cell))</td>\n" }
            html += "</tr>\n"
        }
        html += "</tbody>\n</table>\n"
        return html
    }

    private static func splitTableCells(_ line: String) -> [String] {
        var s = line.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("|") { s = String(s.dropFirst()) }
        if s.hasSuffix("|") { s = String(s.dropLast()) }
        return s.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private static func convertList(lines: [String], from i: inout Int, ordered: Bool) -> String {
        let tag = ordered ? "ol" : "ul"
        let pattern = ordered ? #"^\d+\.\s+"# : #"^[-*+]\s+"#
        var html = "<\(tag)>\n"
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            guard let range = line.range(of: pattern, options: .regularExpression) else { break }
            var content = String(line[range.upperBound...])
            // Checklist
            if content.hasPrefix("[ ] ") {
                content = String(content.dropFirst(4))
                html += "<li><input type=\"checkbox\" disabled> \(inlineToHTML(content))</li>\n"
            } else if content.hasPrefix("[x] ") || content.hasPrefix("[X] ") {
                content = String(content.dropFirst(4))
                html += "<li><input type=\"checkbox\" checked disabled> \(inlineToHTML(content))</li>\n"
            } else {
                html += "<li>\(inlineToHTML(content))</li>\n"
            }
            i += 1
        }
        html += "</\(tag)>\n"
        return html
    }

    private static func inlineToHTML(_ text: String) -> String {
        var r = escapeHTML(text)
        // Images
        r = regexReplace(r, pattern: #"!\[([^\]]*)\]\(([^)]+)\)"#, with: "<img src=\"$2\" alt=\"$1\">")
        // Links
        r = regexReplace(r, pattern: #"\[([^\]]+)\]\(([^)]+)\)"#, with: "<a href=\"$2\">$1</a>")
        // Bold+Italic
        r = regexReplace(r, pattern: #"\*{3}(.+?)\*{3}"#, with: "<strong><em>$1</em></strong>")
        r = regexReplace(r, pattern: #"_{3}(.+?)_{3}"#, with: "<strong><em>$1</em></strong>")
        // Bold
        r = regexReplace(r, pattern: #"\*{2}(.+?)\*{2}"#, with: "<strong>$1</strong>")
        r = regexReplace(r, pattern: #"_{2}(.+?)_{2}"#, with: "<strong>$1</strong>")
        // Italic
        r = regexReplace(r, pattern: #"\*(.+?)\*"#, with: "<em>$1</em>")
        r = regexReplace(r, pattern: #"\b_(.+?)_\b"#, with: "<em>$1</em>")
        // Strikethrough
        r = regexReplace(r, pattern: #"~~(.+?)~~"#, with: "<del>$1</del>")
        // Inline code
        r = regexReplace(r, pattern: #"`([^`]+)`"#, with: "<code>$1</code>")
        return r
    }

    private static func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    // MARK: - HTML → Markdown

    private static func htmlToMarkdown(_ html: String) -> String {
        var text = html

        // Headings
        for level in 1...6 {
            let prefix = String(repeating: "#", count: level)
            text = regexReplace(text, pattern: "<h\(level)[^>]*>(.*?)</h\(level)>", with: "\(prefix) $1")
        }

        // Bold
        text = regexReplace(text, pattern: "<strong>(.*?)</strong>", with: "**$1**")
        text = regexReplace(text, pattern: "<b>(.*?)</b>", with: "**$1**")
        // Italic
        text = regexReplace(text, pattern: "<em>(.*?)</em>", with: "*$1*")
        text = regexReplace(text, pattern: "<i>(.*?)</i>", with: "*$1*")
        // Strikethrough
        text = regexReplace(text, pattern: "<del>(.*?)</del>", with: "~~$1~~")
        text = regexReplace(text, pattern: "<s>(.*?)</s>", with: "~~$1~~")
        // Inline code
        text = regexReplace(text, pattern: "<code>([^<]*?)</code>", with: "`$1`")

        // Links
        text = regexReplace(text, pattern: #"<a[^>]+href="([^"]+)"[^>]*>(.*?)</a>"#, with: "[$2]($1)")
        // Images
        text = regexReplace(text, pattern: #"<img[^>]+src="([^"]+)"[^>]*alt="([^"]*)"[^>]*/?\s*>"#, with: "![$2]($1)")
        text = regexReplace(text, pattern: #"<img[^>]+alt="([^"]*)"[^>]*src="([^"]+)"[^>]*/?\s*>"#, with: "![$1]($2)")

        // Code blocks
        text = regexReplace(text, pattern: #"<pre><code[^>]*>([\s\S]*?)</code></pre>"#, with: "```\n$1\n```")

        // Blockquote
        text = regexReplace(text, pattern: "<blockquote>([\\s\\S]*?)</blockquote>", with: "> $1")

        // Horizontal rule
        text = regexReplace(text, pattern: "<hr\\s*/?>", with: "---")

        // List items
        text = regexReplace(text, pattern: #"<li>\s*<input type="checkbox" checked[^>]*>\s*(.*?)</li>"#, with: "- [x] $1")
        text = regexReplace(text, pattern: #"<li>\s*<input type="checkbox"[^>]*>\s*(.*?)</li>"#, with: "- [ ] $1")
        text = regexReplace(text, pattern: "<li>(.*?)</li>", with: "- $1")

        // Paragraphs → double newline
        text = regexReplace(text, pattern: "<p>(.*?)</p>", with: "$1\n")

        // Line breaks
        text = regexReplace(text, pattern: "<br\\s*/?>", with: "\n")

        // Strip remaining HTML tags
        text = regexReplace(text, pattern: "<[^>]+>", with: "")

        // Unescape HTML entities
        text = text.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")

        // Clean up excessive blank lines
        while text.contains("\n\n\n") {
            text = text.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
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
