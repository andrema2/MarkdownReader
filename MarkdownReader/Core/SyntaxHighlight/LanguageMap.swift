import Foundation

enum LanguageMap {
    /// Maps a file extension to the highlight.js language identifier.
    static func language(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        // Web
        case "js", "mjs", "cjs":        return "javascript"
        case "ts", "mts", "cts":        return "typescript"
        case "json", "jsonl":            return "json"
        case "css":                      return "css"
        case "html", "htm":             return "xml"
        case "xml", "svg", "xhtml":     return "xml"

        // Markup / Config
        case "md", "markdown":          return "markdown"
        case "yaml", "yml":             return "yaml"
        case "ini", "cfg", "conf":      return "ini"
        case "toml":                    return "ini"  // closest match

        // Systems
        case "swift":                   return "swift"
        case "c", "h":                  return "c"
        case "cpp", "cc", "cxx", "hpp": return "cpp"
        case "go":                      return "go"
        case "rs":                      return "rust"
        case "java":                    return "java"
        case "kt", "kts":              return "kotlin"

        // Scripting
        case "py", "pyw":              return "python"
        case "rb":                      return "ruby"
        case "sh", "bash", "zsh":      return "bash"
        case "fish":                    return "shell"

        // Data / Ops
        case "sql":                     return "sql"
        case "dockerfile":             return "dockerfile"
        case "makefile", "mk":         return "makefile"

        default:                        return "plaintext"
        }
    }

    /// All bundled highlight.js language module filenames (without extension).
    static let bundledLanguages: Set<String> = [
        "bash", "c", "cpp", "css", "dockerfile", "go", "ini",
        "java", "javascript", "json", "kotlin", "makefile",
        "markdown", "python", "ruby", "rust", "shell", "sql",
        "swift", "typescript", "xml", "yaml",
    ]
}
