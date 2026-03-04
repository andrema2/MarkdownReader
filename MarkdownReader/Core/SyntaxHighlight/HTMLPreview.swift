import SwiftUI
import WebKit

/// Renders raw HTML content in a WKWebView with full WebKit rendering support.
/// Uses the file's directory as base URL so relative resources (images, CSS, JS) load correctly.
struct HTMLPreview: NSViewRepresentable {
    let html: String
    var baseURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.preferences.isElementFullscreenEnabled = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.webView = webView
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let hash = html.hashValue
        guard hash != context.coordinator.lastHash else { return }
        context.coordinator.lastHash = hash

        // Inject viewport meta if missing, for proper responsive rendering
        let content: String
        if html.lowercased().contains("<html") || html.lowercased().contains("<!doctype") {
            // Full HTML document — inject viewport if missing
            if !html.lowercased().contains("viewport") {
                content = html.replacingOccurrences(
                    of: "<head>",
                    with: "<head>\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
                    options: .caseInsensitive
                )
            } else {
                content = html
            }
        } else {
            // HTML fragment — wrap in a proper document
            content = """
            <!DOCTYPE html>
            <html>
            <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                :root { color-scheme: light dark; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif;
                    font-size: 14px;
                    line-height: 1.6;
                    margin: 0;
                    padding: 16px;
                    background: transparent;
                }
            </style>
            </head>
            <body>\(html)</body>
            </html>
            """
        }

        webView.loadHTMLString(content, baseURL: baseURL)
    }

    class Coordinator {
        weak var webView: WKWebView?
        var lastHash: Int = 0
    }
}
