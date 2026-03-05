import SwiftUI

/// FileType tab — reorganizes the existing FormatControls into ribbon groups.
/// Shows the same controls as FormatControls.swift but with ribbon layout.
struct FileTypeRibbonTab: View {
    @ObservedObject var document: DocumentModel

    var body: some View {
        switch document.fileType {
        case .markdown:
            markdownFileType
        case .html:
            htmlFileType
        case .json:
            jsonFileType
        case .yaml:
            yamlFileType
        case .javascript, .typescript:
            jsFileType
        case .css:
            cssFileType
        case .plain:
            plainFileType
        }
    }

    // MARK: - Markdown

    private var markdownFileType: some View {
        HStack(spacing: 0) {
            RibbonGroup(label: "Text") {
                RibbonSmallIconButton("Bold", icon: "bold") { wrap("**") }
                RibbonSmallIconButton("Italic", icon: "italic") { wrap("_") }
                RibbonSmallIconButton("Strike", icon: "strikethrough") { wrap("~~") }
                RibbonSmallIconButton("Code", icon: "chevron.left.forwardslash.chevron.right") { wrap("`") }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Structure") {
                RibbonMenuButton(label: "Headers", icon: "textformat.size") {
                    Button("H1") { prepend("# ") }
                    Button("H2") { prepend("## ") }
                    Button("H3") { prepend("### ") }
                    Button("H4") { prepend("#### ") }
                    Button("H5") { prepend("##### ") }
                    Button("H6") { prepend("###### ") }
                }
                RibbonSmallIconButton("Quote", icon: "text.quote") { prepend("> ") }
                RibbonSmallIconButton("Divider", icon: "minus") { append("\n---\n") }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Insert") {
                RibbonSmallIconButton("Link", icon: "link") { append("[text](url)") }
                RibbonSmallIconButton("Image", icon: "photo") { append("![alt](url)") }
                RibbonSmallIconButton("Bullets", icon: "list.bullet") { prepend("- ") }
                RibbonSmallIconButton("Numbers", icon: "list.number") { prepend("1. ") }
                RibbonSmallIconButton("Check", icon: "checklist") { prepend("- [ ] ") }
                RibbonMenuButton(label: "Code Block", icon: "rectangle.split.3x3") {
                    Button("Generic")    { append("\n```\n\n```\n") }
                    Divider()
                    Button("Swift")      { append("\n```swift\n\n```\n") }
                    Button("Python")     { append("\n```python\n\n```\n") }
                    Button("JavaScript") { append("\n```javascript\n\n```\n") }
                    Button("TypeScript") { append("\n```typescript\n\n```\n") }
                    Button("Bash")       { append("\n```bash\n\n```\n") }
                    Button("JSON")       { append("\n```json\n\n```\n") }
                    Button("HTML")       { append("\n```html\n\n```\n") }
                    Button("CSS")        { append("\n```css\n\n```\n") }
                }
                RibbonSmallIconButton("Table", icon: "tablecells") {
                    append("\n| Col 1 | Col 2 |\n|-------|-------|\n| Cell  | Cell  |\n")
                }
                RibbonSmallIconButton("Footnote", icon: "textformat.superscript") { append("[^1]\n\n[^1]: Footnote") }
                RibbonSmallIconButton("Definition", icon: "book") { append("\nTerm\n: Definition") }
            }
        }
    }

    // MARK: - HTML

    private var htmlFileType: some View {
        HStack(spacing: 0) {
            RibbonGroup(label: "Block") {
                RibbonMenuButton(label: "Semantic", icon: "rectangle.3.group") {
                    Button("div")     { append("\n<div>\n  \n</div>") }
                    Button("section") { append("\n<section>\n  \n</section>") }
                    Button("article") { append("\n<article>\n  \n</article>") }
                    Button("header")  { append("\n<header>\n  \n</header>") }
                    Button("footer")  { append("\n<footer>\n  \n</footer>") }
                    Button("nav")     { append("\n<nav>\n  \n</nav>") }
                    Button("main")    { append("\n<main>\n  \n</main>") }
                    Button("aside")   { append("\n<aside>\n  \n</aside>") }
                    Button("p")       { append("\n<p></p>") }
                }
                RibbonMenuButton(label: "Structural", icon: "tablecells") {
                    Button("Table")    { append("\n<table>\n  <thead>\n    <tr><th>Header</th></tr>\n  </thead>\n  <tbody>\n    <tr><td>Cell</td></tr>\n  </tbody>\n</table>") }
                    Button("Form")     { append("\n<form action=\"\" method=\"POST\">\n  <label for=\"f\">Label</label>\n  <input type=\"text\" id=\"f\" name=\"f\">\n  <button type=\"submit\">Submit</button>\n</form>") }
                    Button("UL")       { append("\n<ul>\n  <li></li>\n</ul>") }
                    Button("OL")       { append("\n<ol>\n  <li></li>\n</ol>") }
                    Button("Details")  { append("\n<details>\n  <summary>Title</summary>\n  <p>Content</p>\n</details>") }
                }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Inline") {
                RibbonSmallIconButton("Image", icon: "photo") { append("\n<img src=\"\" alt=\"\">") }
                RibbonSmallIconButton("Link", icon: "link") { append("\n<a href=\"\"></a>") }
                RibbonSmallIconButton("Input", icon: "rectangle.and.pencil.and.ellipsis") { append("\n<input type=\"text\" name=\"\" placeholder=\"\">") }
                RibbonSmallIconButton("Button", icon: "hand.tap") { append("\n<button type=\"button\"></button>") }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Head") {
                RibbonSmallIconButton("charset", icon: "character") { append("\n<meta charset=\"UTF-8\">") }
                RibbonSmallIconButton("viewport", icon: "iphone") { append("\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">") }
                RibbonSmallIconButton("CSS", icon: "paintbrush") { append("\n<link rel=\"stylesheet\" href=\"style.css\">") }
                RibbonSmallIconButton("Script", icon: "chevron.left.forwardslash.chevron.right") { append("\n<script src=\"\"></script>") }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Comment") {
                RibbonSmallIconButton("<!-- -->", icon: "text.justify.left") { append("\n<!-- comment -->") }
            }
        }
    }

    // MARK: - JSON

    private var jsonFileType: some View {
        HStack(spacing: 0) {
            RibbonGroup(label: "Format") {
                RibbonLargeButton("Pretty", icon: "text.alignleft") { prettyPrintJSON() }
                RibbonLargeButton("Compact", icon: "arrow.right.arrow.left") { compactJSON() }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Insert") {
                RibbonSmallIconButton("Object", icon: "curlybraces") { append("{\n  \n}") }
                RibbonSmallIconButton("Array", icon: "square.stack") { append("[\n  \n]") }
                RibbonSmallIconButton("Key-Value", icon: "key") { append("\"key\": \"value\"") }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Validate") {
                RibbonLargeButton("Validate", icon: "checkmark.seal") {
                    guard let data = document.content.data(using: .utf8) else { return }
                    _ = try? JSONSerialization.jsonObject(with: data)
                }
            }
        }
    }

    // MARK: - YAML

    private var yamlFileType: some View {
        HStack(spacing: 0) {
            yamlSubtypeBadge
            RibbonGroupSeparator()
            yamlSubtypeInserts
            RibbonGroupSeparator()
            RibbonGroup(label: "Format") {
                RibbonSmallIconButton("Sort", icon: "arrow.up.arrow.down") { sortYAMLKeys() }
                RibbonSmallIconButton("Trim", icon: "scissors") { trimTrailing() }
            }
        }
    }

    private var yamlSubtypeBadge: some View {
        let (label, icon): (String, String) = {
            switch document.yamlSubtype {
            case .dockerCompose:  return ("Compose", "shippingbox")
            case .kubernetes:     return ("K8s", "server.rack")
            case .githubActions:  return ("Actions", "play.rectangle")
            case .gitlabCI:       return ("GitLab CI", "chevron.left.forwardslash.chevron.right")
            case .generic:        return ("YAML", "doc.text")
            }
        }()
        return RibbonGroup(label: "Type") {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 11))
                Text(label).font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.1)))
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var yamlSubtypeInserts: some View {
        switch document.yamlSubtype {
        case .dockerCompose:
            RibbonGroup(label: "Docker Compose") {
                RibbonMenuButton(label: "Service", icon: "plus.rectangle.on.rectangle") {
                    Button("Basic")   { append("\n  svc:\n    image: img:latest\n    ports:\n      - \"8080:80\"") }
                    Button("Build")   { append("\n  svc:\n    build: .\n    ports:\n      - \"8080:80\"") }
                }
                RibbonSmallIconButton("Env", icon: "terminal") { append("\n      - VAR=value") }
                RibbonSmallIconButton("Port", icon: "arrow.left.arrow.right") { append("\n      - \"H:C\"") }
                RibbonSmallIconButton("Volume", icon: "externaldrive") { append("\n    volumes:\n      - ./data:/data") }
                RibbonSmallIconButton("depends_on", icon: "arrow.down.circle") { append("\n    depends_on:\n      - svc") }
                RibbonSmallIconButton("Network", icon: "network") { append("\n\nnetworks:\n  net:\n    driver: bridge") }
            }
        case .kubernetes:
            RibbonGroup(label: "Kubernetes") {
                RibbonMenuButton(label: "Resources", icon: "square.stack.3d.up") {
                    Button("Deployment") { append("\n---\napiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: app") }
                    Button("Service")    { append("\n---\napiVersion: v1\nkind: Service\nmetadata:\n  name: svc") }
                    Button("ConfigMap")  { append("\n---\napiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: cm\ndata:\n  K: v") }
                }
                RibbonSmallIconButton("Container", icon: "shippingbox") { append("\n        - name: c\n          image: img:tag") }
                RibbonSmallIconButton("---", icon: "minus") { append("\n---\n") }
            }
        case .githubActions:
            RibbonGroup(label: "GitHub Actions") {
                RibbonMenuButton(label: "Job/Step", icon: "play.rectangle") {
                    Button("Job")  { append("\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4") }
                    Button("Step") { append("\n      - name: Step\n        run: echo \"hi\"") }
                }
                RibbonSmallIconButton("Checkout", icon: "arrow.down.circle") { append("\n      - uses: actions/checkout@v4") }
                RibbonSmallIconButton("Matrix", icon: "tablecells") { append("\n    strategy:\n      matrix:\n        node: [18,20]") }
            }
        case .gitlabCI:
            RibbonGroup(label: "GitLab CI") {
                RibbonMenuButton(label: "Job", icon: "chevron.left.forwardslash.chevron.right") {
                    Button("Job") { append("\njob:\n  stage: build\n  script:\n    - echo build") }
                }
                RibbonSmallIconButton("Script", icon: "terminal") { append("\n    - echo cmd") }
                RibbonSmallIconButton("Variable", icon: "key") { append("\nvariables:\n  VAR: val") }
            }
        case .generic:
            RibbonGroup(label: "Insert") {
                RibbonSmallIconButton("Key", icon: "key") { append("\nkey: value") }
                RibbonSmallIconButton("List", icon: "list.bullet") { append("\n  - item") }
                RibbonSmallIconButton("Nested", icon: "list.bullet.indent") { append("\nparent:\n  child: val") }
                RibbonSmallIconButton("Comment", icon: "number") { append("\n# comment") }
            }
        }
    }

    // MARK: - JS/TS

    private var jsFileType: some View {
        HStack(spacing: 0) {
            RibbonGroup(label: "Insert") {
                RibbonSmallIconButton("Function", icon: "function") { append("\nfunction name() {\n  \n}\n") }
                RibbonSmallIconButton("Arrow", icon: "arrow.right") { append("\nconst name = () => {\n  \n};\n") }
                RibbonSmallIconButton("Console", icon: "text.bubble") { append("\nconsole.log();") }
                RibbonSmallIconButton("If", icon: "questionmark.diamond") { append("\nif (cond) {\n  \n}\n") }
                RibbonSmallIconButton("Try-Catch", icon: "exclamationmark.shield") { append("\ntry {\n  \n} catch (e) {\n  console.error(e);\n}\n") }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Modern") {
                RibbonSmallIconButton("Async", icon: "clock.arrow.circlepath") { append("\nasync function name() {\n  \n}\n") }
                RibbonSmallIconButton("Import", icon: "arrow.down.circle") { append("\nimport { x } from 'module';") }
                RibbonSmallIconButton("Class", icon: "square.on.square") { append("\nclass C {\n  constructor() {}\n}\n") }
                RibbonMenuButton(label: "Fetch", icon: "network") {
                    Button("async/await") { append("\nconst r = await fetch('url');\nconst d = await r.json();\n") }
                    Button(".then()")     { append("\nfetch('url').then(r=>r.json()).then(d=>console.log(d));\n") }
                }
                RibbonSmallIconButton("Promise", icon: "circle.dashed") { append("\nnew Promise((resolve, reject) => {\n  \n});\n") }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Comment") {
                RibbonSmallIconButton("//", icon: "text.line.first.and.arrowtriangle.forward") { append("\n// ") }
                RibbonSmallIconButton("/* */", icon: "text.justify.left") { append("\n/* */") }
                RibbonSmallIconButton("JSDoc", icon: "doc.text") { append("\n/**\n * \n * @param {type} name\n * @returns {type}\n */") }
            }
        }
    }

    // MARK: - CSS

    private var cssFileType: some View {
        HStack(spacing: 0) {
            RibbonGroup(label: "Insert") {
                RibbonSmallIconButton("Rule", icon: "paintbrush") { append("\n.cls {\n  \n}\n") }
                RibbonSmallIconButton("Media", icon: "display") { append("\n@media (max-width: 768px) {\n  \n}\n") }
                RibbonSmallIconButton("Variable", icon: "textformat") { append("\n  --var: val;") }
                RibbonSmallIconButton("Keyframes", icon: "play") { append("\n@keyframes n {\n  from {} to {}\n}\n") }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Layout") {
                RibbonMenuButton(label: "Layout", icon: "rectangle.split.2x2") {
                    Button("Flexbox") { append("\n  display: flex;\n  gap: 1rem;") }
                    Button("Grid")    { append("\n  display: grid;\n  grid-template-columns: repeat(3,1fr);\n  gap: 1rem;") }
                    Button("Center")  { append("\n  display: flex;\n  align-items: center;\n  justify-content: center;") }
                }
                RibbonSmallIconButton("Animation", icon: "waveform.path") { append("\n  animation: n 1s ease infinite;") }
                RibbonSmallIconButton("Transition", icon: "arrow.left.and.right") { append("\n  transition: all 0.2s ease;") }
                RibbonSmallIconButton(":root vars", icon: "list.bullet.indent") { append("\n:root {\n  --primary: #007aff;\n  --spacing: 1rem;\n}\n") }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Comment") {
                RibbonSmallIconButton("/* */", icon: "text.justify.left") { append("\n/* */") }
            }
        }
    }

    // MARK: - Plain Text

    private var plainFileType: some View {
        HStack(spacing: 0) {
            RibbonGroup(label: "Edit") {
                RibbonSmallIconButton("Sort", icon: "arrow.up.arrow.down") {
                    let sorted = document.content.components(separatedBy: .newlines).sorted()
                    document.updateContent(sorted.joined(separator: "\n"))
                }
                RibbonSmallIconButton("Remove Empty", icon: "line.3.horizontal.decrease") {
                    let filtered = document.content.components(separatedBy: .newlines)
                        .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    document.updateContent(filtered.joined(separator: "\n"))
                }
                RibbonSmallIconButton("Trim", icon: "scissors") {
                    let trimmed = document.content.components(separatedBy: .newlines)
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                    document.updateContent(trimmed.joined(separator: "\n"))
                }
                RibbonSmallIconButton("Dedup", icon: "minus.circle") {
                    var seen = Set<String>()
                    let unique = document.content.components(separatedBy: .newlines)
                        .filter { seen.insert($0).inserted }
                    document.updateContent(unique.joined(separator: "\n"))
                }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Case") {
                RibbonSmallIconButton("UPPER", icon: "textformat.abc") { document.updateContent(document.content.uppercased()) }
                RibbonSmallIconButton("lower", icon: "textformat.abc.dottedunderline") { document.updateContent(document.content.lowercased()) }
            }
        }
    }

    // MARK: - Helpers

    private func wrap(_ marker: String) {
        document.updateContent(document.content + marker + "text" + marker)
    }

    private func prepend(_ prefix: String) {
        document.updateContent(document.content + "\n" + prefix)
    }

    private func append(_ text: String) {
        document.updateContent(document.content + text)
    }

    private func prettyPrintJSON() {
        guard let data = document.content.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: pretty, encoding: .utf8) else { return }
        document.updateContent(str)
    }

    private func compactJSON() {
        guard let data = document.content.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let compact = try? JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys]),
              let str = String(data: compact, encoding: .utf8) else { return }
        document.updateContent(str)
    }

    private func sortYAMLKeys() {
        let lines = document.content.components(separatedBy: .newlines)
        var sections: [(key: String, lines: [String])] = []
        var current: (key: String, lines: [String])?
        for line in lines {
            if !line.isEmpty && !line.hasPrefix(" ") && !line.hasPrefix("\t") && !line.hasPrefix("#") && line.contains(":") {
                if let c = current { sections.append(c) }
                let key = String(line.split(separator: ":").first ?? "")
                current = (key: key, lines: [line])
            } else {
                current?.lines.append(line)
            }
        }
        if let c = current { sections.append(c) }
        let sorted = sections.sorted { $0.key.lowercased() < $1.key.lowercased() }
        document.updateContent(sorted.flatMap(\.lines).joined(separator: "\n"))
    }

    private func trimTrailing() {
        let trimmed = document.content
            .components(separatedBy: .newlines)
            .map { $0.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression) }
            .joined(separator: "\n")
        document.updateContent(trimmed)
    }
}
