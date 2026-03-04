import SwiftUI
import WebKit

/// Renders syntax-highlighted code using a bundled copy of Highlight.js inside a WKWebView.
/// All assets are loaded from the app bundle — no network required.
struct HighlightEngine: NSViewRepresentable {
    let code: String
    let language: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Allow file:// access to load bundled JS/CSS
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.webView = webView
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Debounce: avoid re-rendering identical content
        let contentHash = "\(language):\(code.hashValue)"
        guard contentHash != context.coordinator.lastContentHash else { return }
        context.coordinator.lastContentHash = contentHash

        let html = buildHTML(code: code, language: language)
        let baseURL = BundledHighlight.baseURL
        webView.loadHTMLString(html, baseURL: baseURL)
    }

    private func buildHTML(code: String, language: String) -> String {
        let escaped = code
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        let langScripts = BundledHighlight.languageScriptTags(for: language)

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <link rel="stylesheet" href="styles/github.min.css"
                  media="(prefers-color-scheme: light)">
            <link rel="stylesheet" href="styles/github-dark.min.css"
                  media="(prefers-color-scheme: dark)">
            <script src="highlight.min.js"></script>
            \(langScripts)
            <style>
                :root { color-scheme: light dark; }
                body {
                    margin: 0;
                    padding: 0;
                    background: transparent;
                    font-family: "SF Mono", Menlo, monospace;
                    font-size: 13px;
                    line-height: 1.5;
                    -webkit-font-smoothing: antialiased;
                }
                pre {
                    margin: 0;
                    padding: 12px 16px;
                    white-space: pre-wrap;
                    word-wrap: break-word;
                    tab-size: 4;
                }
                code {
                    font-family: inherit;
                }
                .hljs {
                    background: transparent !important;
                    padding: 0 !important;
                }
                .line-numbers {
                    counter-reset: line;
                }
                .line-numbers .line::before {
                    counter-increment: line;
                    content: counter(line);
                    display: inline-block;
                    width: 3em;
                    margin-right: 1em;
                    text-align: right;
                    color: rgba(128,128,128,0.5);
                    font-size: 0.9em;
                    -webkit-user-select: none;
                    user-select: none;
                }
            </style>
        </head>
        <body>
            <pre class="line-numbers"><code id="code" class="language-\(language)">\(escaped)</code></pre>
            <script>
                hljs.highlightElement(document.getElementById('code'));
                // Wrap lines for line numbers
                const codeEl = document.getElementById('code');
                const lines = codeEl.innerHTML.split('\\n');
                codeEl.innerHTML = lines.map(l => '<span class="line">' + l + '</span>').join('\\n');
            </script>
        </body>
        </html>
        """
    }

    class Coordinator {
        weak var webView: WKWebView?
        var lastContentHash: String = ""
    }
}

// MARK: - Bundled Asset Helpers

enum BundledHighlight {
    /// Base URL pointing to the bundled highlight/ directory.
    static var baseURL: URL? {
        Bundle.main.resourceURL?.appendingPathComponent("highlight", isDirectory: true)
    }

    /// Generates `<script>` tags for the given language and its dependencies.
    static func languageScriptTags(for language: String) -> String {
        guard language != "plaintext" else { return "" }

        var langs = [language]

        // Some languages depend on others
        switch language {
        case "cpp": langs = ["c", "cpp"]
        case "typescript": langs = ["javascript", "typescript"]
        case "kotlin": langs = ["java", "kotlin"]
        default: break
        }

        return langs
            .filter { LanguageMap.bundledLanguages.contains($0) }
            .map { "<script src=\"languages/\($0).min.js\"></script>" }
            .joined(separator: "\n            ")
    }
}
