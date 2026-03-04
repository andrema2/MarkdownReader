import SwiftUI
import WebKit

/// Renders Markdown content as formatted HTML in a WKWebView.
/// Converts headings, bold, italic, links, images, code blocks, tables, lists, etc.
/// into proper visual HTML — no raw Markdown syntax visible.
struct MarkdownRenderer: NSViewRepresentable {
    let markdown: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.webView = webView
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let hash = markdown.hashValue
        guard hash != context.coordinator.lastHash else { return }
        context.coordinator.lastHash = hash

        let html = buildHTML(from: markdown)
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func buildHTML(from md: String) -> String {
        let body = markdownToHTML(md)
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
            :root { color-scheme: light dark; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif;
                font-size: 14px;
                line-height: 1.7;
                color: #1d1d1f;
                margin: 0;
                padding: 20px 24px;
                background: transparent;
                -webkit-font-smoothing: antialiased;
            }
            @media (prefers-color-scheme: dark) {
                body { color: #f5f5f7; }
                a { color: #6eb5ff; }
                code, pre code { background: rgba(255,255,255,0.08); }
                blockquote { border-color: #555; color: #aaa; }
                table th { background: rgba(255,255,255,0.08); }
                table td, table th { border-color: #444; }
                hr { border-color: #444; }
            }
            h1 { font-size: 28px; font-weight: 700; margin: 24px 0 12px; border-bottom: 1px solid #ddd; padding-bottom: 8px; }
            h2 { font-size: 22px; font-weight: 600; margin: 20px 0 10px; border-bottom: 1px solid #eee; padding-bottom: 6px; }
            h3 { font-size: 18px; font-weight: 600; margin: 18px 0 8px; }
            h4 { font-size: 16px; font-weight: 600; margin: 16px 0 6px; }
            h5 { font-size: 14px; font-weight: 600; margin: 14px 0 4px; }
            h6 { font-size: 13px; font-weight: 600; margin: 12px 0 4px; color: #888; }
            p { margin: 8px 0; }
            a { color: #0066cc; text-decoration: none; }
            a:hover { text-decoration: underline; }
            strong { font-weight: 600; }
            em { font-style: italic; }
            del { text-decoration: line-through; color: #999; }
            code {
                font-family: "SF Mono", Menlo, monospace;
                font-size: 12px;
                background: rgba(0,0,0,0.05);
                padding: 2px 6px;
                border-radius: 4px;
            }
            pre {
                margin: 12px 0;
                padding: 14px 16px;
                background: rgba(0,0,0,0.04);
                border-radius: 8px;
                overflow-x: auto;
            }
            pre code {
                background: none;
                padding: 0;
                font-size: 12px;
                line-height: 1.5;
            }
            blockquote {
                margin: 10px 0;
                padding: 4px 16px;
                border-left: 4px solid #ddd;
                color: #666;
            }
            blockquote p { margin: 4px 0; }
            ul, ol { padding-left: 24px; margin: 8px 0; }
            li { margin: 4px 0; }
            li input[type="checkbox"] { margin-right: 6px; }
            hr { border: none; border-top: 1px solid #ddd; margin: 20px 0; }
            img { max-width: 100%; border-radius: 6px; margin: 8px 0; }
            table {
                border-collapse: collapse;
                width: 100%;
                margin: 12px 0;
                font-size: 13px;
            }
            table th, table td {
                border: 1px solid #ddd;
                padding: 8px 12px;
                text-align: left;
            }
            table th {
                font-weight: 600;
                background: rgba(0,0,0,0.03);
            }
            table tr:nth-child(even) td {
                background: rgba(0,0,0,0.015);
            }
        </style>
        </head>
        <body>\(body)</body>
        </html>
        """
    }

    // MARK: - Markdown → HTML Converter

    private func markdownToHTML(_ md: String) -> String {
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
                    html += parseTable(lines: lines, from: &i)
                    continue
                }
            }

            // Heading
            if let heading = parseHeading(trimmed) {
                html += heading
                i += 1
                continue
            }

            // Horizontal rule
            if trimmed.count >= 3 && trimmed.allSatisfy({ $0 == "-" || $0 == "*" || $0 == "_" || $0 == " " }) &&
               (trimmed.filter({ $0 == "-" }).count >= 3 || trimmed.filter({ $0 == "*" }).count >= 3 || trimmed.filter({ $0 == "_" }).count >= 3) {
                html += "<hr>\n"
                i += 1
                continue
            }

            // Blockquote
            if trimmed.hasPrefix(">") {
                var quoteLines: [String] = []
                while i < lines.count {
                    let ql = lines[i].trimmingCharacters(in: .whitespaces)
                    if ql.hasPrefix(">") {
                        let content = String(ql.dropFirst()).trimmingCharacters(in: .whitespaces)
                        quoteLines.append(content)
                    } else if ql.isEmpty && !quoteLines.isEmpty {
                        break
                    } else {
                        break
                    }
                    i += 1
                }
                let inner = quoteLines.map { "<p>\(inlineMarkdown($0))</p>" }.joined()
                html += "<blockquote>\(inner)</blockquote>\n"
                continue
            }

            // Unordered list
            if let _ = trimmed.range(of: #"^[-*+]\s+"#, options: .regularExpression) {
                html += parseList(lines: lines, from: &i, ordered: false)
                continue
            }

            // Ordered list
            if let _ = trimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                html += parseList(lines: lines, from: &i, ordered: true)
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
            html += "<p>\(paraLines.map { inlineMarkdown($0) }.joined(separator: "<br>"))</p>\n"
        }

        return html
    }

    private func parseHeading(_ line: String) -> String? {
        guard line.hasPrefix("#") else { return nil }
        var level = 0
        for ch in line {
            if ch == "#" { level += 1 } else { break }
        }
        guard level >= 1, level <= 6, line.count > level else { return nil }
        let text = String(line.dropFirst(level)).trimmingCharacters(in: .whitespaces)
        return "<h\(level)>\(inlineMarkdown(text))</h\(level)>\n"
    }

    private func parseTable(lines: [String], from i: inout Int) -> String {
        let headerLine = lines[i]
        let headers = splitTableRow(headerLine)
        i += 2 // skip header + separator

        var rows: [[String]] = []
        while i < lines.count {
            let rowLine = lines[i].trimmingCharacters(in: .whitespaces)
            guard rowLine.contains("|") else { break }
            rows.append(splitTableRow(rowLine))
            i += 1
        }

        var html = "<table><thead><tr>"
        for h in headers {
            html += "<th>\(inlineMarkdown(h))</th>"
        }
        html += "</tr></thead><tbody>"
        for row in rows {
            html += "<tr>"
            for (idx, cell) in row.enumerated() {
                let _ = idx // just use cell
                html += "<td>\(inlineMarkdown(cell))</td>"
            }
            html += "</tr>"
        }
        html += "</tbody></table>\n"
        return html
    }

    private func splitTableRow(_ line: String) -> [String] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let stripped = trimmed.hasPrefix("|") ? String(trimmed.dropFirst()) : trimmed
        let final = stripped.hasSuffix("|") ? String(stripped.dropLast()) : stripped
        return final.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private func parseList(lines: [String], from i: inout Int, ordered: Bool) -> String {
        let tag = ordered ? "ol" : "ul"
        var html = "<\(tag)>\n"
        let pattern = ordered ? #"^\d+\.\s+"# : #"^[-*+]\s+"#

        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            guard let range = line.range(of: pattern, options: .regularExpression) else { break }
            var content = String(line[range.upperBound...])

            // Checklist
            if content.hasPrefix("[ ] ") {
                content = "<input type=\"checkbox\" disabled>" + String(content.dropFirst(4))
            } else if content.hasPrefix("[x] ") || content.hasPrefix("[X] ") {
                content = "<input type=\"checkbox\" checked disabled>" + String(content.dropFirst(4))
            }

            html += "<li>\(inlineMarkdown(content))</li>\n"
            i += 1
        }
        html += "</\(tag)>\n"
        return html
    }

    // MARK: - Inline Markdown

    private func inlineMarkdown(_ text: String) -> String {
        var result = escapeHTML(text)

        // Images ![alt](url)
        result = regexReplace(result, pattern: #"!\[([^\]]*)\]\(([^)]+)\)"#, template: "<img src=\"$2\" alt=\"$1\">")
        // Links [text](url)
        result = regexReplace(result, pattern: #"\[([^\]]+)\]\(([^)]+)\)"#, template: "<a href=\"$2\">$1</a>")
        // Bold+Italic ***text*** or ___text___
        result = regexReplace(result, pattern: #"\*{3}(.+?)\*{3}"#, template: "<strong><em>$1</em></strong>")
        result = regexReplace(result, pattern: #"_{3}(.+?)_{3}"#, template: "<strong><em>$1</em></strong>")
        // Bold **text** or __text__
        result = regexReplace(result, pattern: #"\*{2}(.+?)\*{2}"#, template: "<strong>$1</strong>")
        result = regexReplace(result, pattern: #"_{2}(.+?)_{2}"#, template: "<strong>$1</strong>")
        // Italic *text* or _text_
        result = regexReplace(result, pattern: #"\*(.+?)\*"#, template: "<em>$1</em>")
        result = regexReplace(result, pattern: #"\b_(.+?)_\b"#, template: "<em>$1</em>")
        // Strikethrough ~~text~~
        result = regexReplace(result, pattern: #"~~(.+?)~~"#, template: "<del>$1</del>")
        // Inline code `text`
        result = regexReplace(result, pattern: #"`([^`]+)`"#, template: "<code>$1</code>")

        return result
    }

    private func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private func regexReplace(_ input: String, pattern: String, template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return input }
        let range = NSRange(input.startIndex..., in: input)
        return regex.stringByReplacingMatches(in: input, range: range, withTemplate: template)
    }

    class Coordinator {
        weak var webView: WKWebView?
        var lastHash: Int = 0
    }
}
