import SwiftUI
import WebKit

struct HighlightEngine: NSViewRepresentable {
    let code: String
    let language: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let html = buildHTML(code: code, language: language)
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func buildHTML(code: String, language: String) -> String {
        let escaped = code
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css"
                  media="(prefers-color-scheme: dark)">
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github.min.css"
                  media="(prefers-color-scheme: light)">
            <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
            <style>
                :root { color-scheme: light dark; }
                body {
                    margin: 0;
                    padding: 0;
                    background: transparent;
                    font-family: "SF Mono", Menlo, monospace;
                    font-size: 13px;
                }
                pre {
                    margin: 0;
                    padding: 12px;
                    white-space: pre-wrap;
                    word-wrap: break-word;
                }
                code { font-family: inherit; }
            </style>
        </head>
        <body>
            <pre><code class="language-\(language)">\(escaped)</code></pre>
            <script>hljs.highlightAll();</script>
        </body>
        </html>
        """
    }
}
