import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let markdown: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let html = generateHTML(from: markdown)
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func generateHTML(from markdown: String) -> String {
        let escapedMarkdown = markdown
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
            <style>
                :root {
                    color-scheme: light dark;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
                    line-height: 1.6;
                    padding: 16px 24px;
                    max-width: 100%;
                    margin: 0;
                    color: #1d1d1f;
                    background: transparent;
                }
                @media (prefers-color-scheme: dark) {
                    body { color: #f5f5f7; }
                    a { color: #6cb4ff; }
                    code { background: rgba(255,255,255,0.1); }
                    pre { background: rgba(255,255,255,0.06) !important; }
                    blockquote { border-left-color: #555; color: #aaa; }
                    table th { background: rgba(255,255,255,0.08); }
                    table td, table th { border-color: #444; }
                }
                h1, h2, h3, h4, h5, h6 {
                    margin-top: 1.2em;
                    margin-bottom: 0.4em;
                    font-weight: 600;
                }
                h1 { font-size: 1.8em; border-bottom: 1px solid #d1d1d6; padding-bottom: 0.3em; }
                h2 { font-size: 1.4em; border-bottom: 1px solid #d1d1d6; padding-bottom: 0.2em; }
                code {
                    font-family: "SF Mono", Menlo, monospace;
                    font-size: 0.9em;
                    background: rgba(0,0,0,0.06);
                    padding: 2px 6px;
                    border-radius: 4px;
                }
                pre {
                    background: rgba(0,0,0,0.04) !important;
                    padding: 12px 16px;
                    border-radius: 8px;
                    overflow-x: auto;
                }
                pre code {
                    background: none;
                    padding: 0;
                }
                blockquote {
                    border-left: 3px solid #d1d1d6;
                    margin-left: 0;
                    padding-left: 16px;
                    color: #666;
                }
                img { max-width: 100%; border-radius: 8px; }
                table {
                    border-collapse: collapse;
                    width: 100%;
                    margin: 1em 0;
                }
                table th, table td {
                    border: 1px solid #d1d1d6;
                    padding: 8px 12px;
                    text-align: left;
                }
                table th {
                    background: rgba(0,0,0,0.04);
                    font-weight: 600;
                }
                a { color: #0066cc; text-decoration: none; }
                a:hover { text-decoration: underline; }
                hr { border: none; border-top: 1px solid #d1d1d6; margin: 1.5em 0; }
            </style>
        </head>
        <body>
            <div id="content"></div>
            <script>
                document.getElementById('content').innerHTML = marked.parse(`\(escapedMarkdown)`);
            </script>
        </body>
        </html>
        """
    }
}
