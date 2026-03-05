import SwiftUI

/// Insert tab — adaptive per file type.
struct InsertRibbonTab: View {
    @ObservedObject var document: DocumentModel

    var body: some View {
        switch document.fileType {
        case .markdown:
            markdownInsert
        case .html:
            htmlInsert
        case .json:
            jsonInsert
        case .yaml:
            yamlInsert
        case .javascript, .typescript:
            jsInsert
        case .css:
            cssInsert
        case .plain:
            plainInsert
        }
    }

    // MARK: - Markdown

    private var markdownInsert: some View {
        HStack(spacing: 0) {
            RibbonGroup(label: "Links") {
                RibbonLargeButton("Link", icon: "link") { append("[text](url)") }
                RibbonLargeButton("Image", icon: "photo") { append("![alt](url)") }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Code") {
                RibbonLargeButton("Code Block", icon: "rectangle.split.3x3") { append("\n```\n\n```\n") }
                RibbonLargeButton("Table", icon: "tablecells") {
                    append("\n| Column 1 | Column 2 |\n|----------|----------|\n| Cell     | Cell     |\n")
                }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Elements") {
                RibbonSmallIconButton("Divider", icon: "minus") { append("\n---\n") }
                RibbonSmallIconButton("Footnote", icon: "textformat.superscript") { append("[^1]\n\n[^1]: Footnote text") }
                RibbonSmallIconButton("Definition", icon: "book") { append("\nTerm\n: Definition") }
            }
        }
    }

    // MARK: - HTML

    private var htmlInsert: some View {
        HStack(spacing: 0) {
            RibbonGroup(label: "Links") {
                RibbonLargeButton("Link", icon: "link") { append("\n<a href=\"\"></a>") }
                RibbonLargeButton("Image", icon: "photo") { append("\n<img src=\"\" alt=\"\">") }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Semantic") {
                RibbonMenuButton(label: "Semantic", icon: "rectangle.3.group") {
                    Button("div")     { append("\n<div>\n  \n</div>") }
                    Button("section") { append("\n<section>\n  \n</section>") }
                    Button("article") { append("\n<article>\n  \n</article>") }
                    Button("header")  { append("\n<header>\n  \n</header>") }
                    Button("footer")  { append("\n<footer>\n  \n</footer>") }
                    Button("nav")     { append("\n<nav>\n  \n</nav>") }
                    Button("main")    { append("\n<main>\n  \n</main>") }
                }
                RibbonMenuButton(label: "Structural", icon: "tablecells") {
                    Button("Table")          { append("\n<table>\n  <thead>\n    <tr><th>Header</th></tr>\n  </thead>\n  <tbody>\n    <tr><td>Cell</td></tr>\n  </tbody>\n</table>") }
                    Button("Form")           { append("\n<form action=\"\" method=\"POST\">\n  <label for=\"field\">Label</label>\n  <input type=\"text\" id=\"field\" name=\"field\">\n  <button type=\"submit\">Submit</button>\n</form>") }
                    Button("Unordered List") { append("\n<ul>\n  <li></li>\n</ul>") }
                    Button("Ordered List")   { append("\n<ol>\n  <li></li>\n</ol>") }
                    Button("Details")        { append("\n<details>\n  <summary>Title</summary>\n  <p>Content</p>\n</details>") }
                }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Inline") {
                RibbonSmallIconButton("Input", icon: "rectangle.and.pencil.and.ellipsis") {
                    append("\n<input type=\"text\" name=\"\" placeholder=\"\">")
                }
                RibbonSmallIconButton("Button", icon: "hand.tap") {
                    append("\n<button type=\"button\"></button>")
                }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Head") {
                RibbonSmallIconButton("Meta charset", icon: "character") { append("\n<meta charset=\"UTF-8\">") }
                RibbonSmallIconButton("Viewport", icon: "iphone") { append("\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">") }
                RibbonSmallIconButton("Stylesheet", icon: "paintbrush") { append("\n<link rel=\"stylesheet\" href=\"style.css\">") }
                RibbonSmallIconButton("Script", icon: "chevron.left.forwardslash.chevron.right") { append("\n<script src=\"\"></script>") }
            }
        }
    }

    // MARK: - JSON

    private var jsonInsert: some View {
        HStack(spacing: 0) {
            RibbonGroup(label: "Structure") {
                RibbonLargeButton("Object", icon: "curlybraces") { append("{\n  \n}") }
                RibbonLargeButton("Array", icon: "square.stack") { append("[\n  \n]") }
                VStack(spacing: 4) {
                    RibbonSmallButton("Key-Value", icon: "key") { append("\"key\": \"value\"") }
                }
            }
            RibbonGroupSeparator()
            jsonContextSnippets
            RibbonGroupSeparator()
            RibbonGroup(label: "Validate") {
                RibbonLargeButton("Validate", icon: "checkmark.seal") {
                    validateJSON()
                }
            }
        }
    }

    @ViewBuilder
    private var jsonContextSnippets: some View {
        switch document.jsonSubtype {
        case .packageJSON:
            RibbonGroup(label: "package.json") {
                RibbonMenuButton(label: "Snippets", icon: "shippingbox") {
                    Button("scripts")         { append("\n  \"scripts\": {\n    \"start\": \"node index.js\",\n    \"build\": \"tsc\",\n    \"test\": \"jest\"\n  }") }
                    Button("dependencies")    { append("\n  \"dependencies\": {\n    \"package\": \"^1.0.0\"\n  }") }
                    Button("devDependencies") { append("\n  \"devDependencies\": {\n    \"typescript\": \"^5.0.0\"\n  }") }
                    Button("engines")         { append("\n  \"engines\": {\n    \"node\": \">=18.0.0\"\n  }") }
                }
            }
        case .tsconfig:
            RibbonGroup(label: "tsconfig") {
                RibbonMenuButton(label: "Snippets", icon: "gearshape") {
                    Button("compilerOptions") { append("\n  \"compilerOptions\": {\n    \"target\": \"ES2022\",\n    \"module\": \"NodeNext\",\n    \"strict\": true\n  }") }
                    Button("include/exclude") { append("\n  \"include\": [\"src/**/*\"],\n  \"exclude\": [\"node_modules\", \"dist\"]") }
                    Button("paths")           { append("\n    \"paths\": {\n      \"@/*\": [\"./src/*\"]\n    }") }
                }
            }
        case .eslint:
            RibbonGroup(label: "ESLint") {
                RibbonMenuButton(label: "Snippets", icon: "checkmark.shield") {
                    Button("rules")   { append("\n  \"rules\": {\n    \"no-console\": \"warn\"\n  }") }
                    Button("extends") { append("\n  \"extends\": [\"eslint:recommended\"]") }
                    Button("env")     { append("\n  \"env\": {\n    \"browser\": true,\n    \"node\": true\n  }") }
                }
            }
        case .generic:
            RibbonGroup(label: "Snippets") {
                RibbonSmallIconButton("String", icon: "textformat") { append("\"key\": \"value\"") }
                RibbonSmallIconButton("Number", icon: "number") { append("\"key\": 0") }
                RibbonSmallIconButton("Boolean", icon: "switch.2") { append("\"key\": true") }
                RibbonSmallIconButton("Null", icon: "circle.slash") { append("\"key\": null") }
            }
        }
    }

    // MARK: - YAML

    private var yamlInsert: some View {
        HStack(spacing: 0) {
            yamlContextInserts
            RibbonGroupSeparator()
            RibbonGroup(label: "Format") {
                RibbonSmallIconButton("Sort Keys", icon: "arrow.up.arrow.down") { sortYAMLKeys() }
                RibbonSmallIconButton("Trim", icon: "scissors") { trimTrailing() }
            }
        }
    }

    @ViewBuilder
    private var yamlContextInserts: some View {
        switch document.yamlSubtype {
        case .dockerCompose:
            RibbonGroup(label: "Docker Compose") {
                RibbonMenuButton(label: "Service", icon: "plus.rectangle.on.rectangle") {
                    Button("Basic")   { append("\n  service:\n    image: image:latest\n    ports:\n      - \"8080:80\"") }
                    Button("Build")   { append("\n  service:\n    build: .\n    ports:\n      - \"8080:80\"") }
                    Button("Volumes") { append("\n  service:\n    image: image:latest\n    volumes:\n      - ./data:/app/data") }
                }
                RibbonSmallIconButton("Env", icon: "terminal") { append("\n      - MY_VAR=value") }
                RibbonSmallIconButton("Port", icon: "arrow.left.arrow.right") { append("\n      - \"HOST:CONTAINER\"") }
                RibbonSmallIconButton("Volume", icon: "externaldrive") { append("\n    volumes:\n      - ./data:/app/data") }
                RibbonSmallIconButton("Network", icon: "network") { append("\n\nnetworks:\n  net:\n    driver: bridge") }
            }
        case .kubernetes:
            RibbonGroup(label: "Kubernetes") {
                RibbonMenuButton(label: "Resources", icon: "square.stack.3d.up") {
                    Button("Deployment") { append("\n---\napiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: app\nspec:\n  replicas: 1\n  selector:\n    matchLabels:\n      app: app\n  template:\n    metadata:\n      labels:\n        app: app\n    spec:\n      containers:\n        - name: app\n          image: image:latest\n          ports:\n            - containerPort: 80") }
                    Button("Service")    { append("\n---\napiVersion: v1\nkind: Service\nmetadata:\n  name: svc\nspec:\n  selector:\n    app: app\n  ports:\n    - port: 80\n      targetPort: 80") }
                    Button("ConfigMap")  { append("\n---\napiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: config\ndata:\n  KEY: value") }
                    Button("Secret")     { append("\n---\napiVersion: v1\nkind: Secret\nmetadata:\n  name: secret\ntype: Opaque\ndata:\n  KEY: base64") }
                    Button("Ingress")    { append("\n---\napiVersion: networking.k8s.io/v1\nkind: Ingress\nmetadata:\n  name: ingress\nspec:\n  rules:\n    - host: example.com\n      http:\n        paths:\n          - path: /\n            pathType: Prefix\n            backend:\n              service:\n                name: svc\n                port:\n                  number: 80") }
                }
                RibbonSmallIconButton("Container", icon: "shippingbox") { append("\n        - name: container\n          image: image:tag\n          ports:\n            - containerPort: 80") }
                RibbonSmallIconButton("Env (CM)", icon: "key") { append("\n          env:\n            - name: VAR\n              valueFrom:\n                configMapKeyRef:\n                  name: config\n                  key: KEY") }
                RibbonSmallIconButton("---", icon: "minus") { append("\n---\n") }
            }
        case .githubActions:
            RibbonGroup(label: "GitHub Actions") {
                RibbonMenuButton(label: "Job/Step", icon: "play.rectangle") {
                    Button("Job")        { append("\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - name: Run\n        run: echo \"Hello\"") }
                    Button("Step (run)")  { append("\n      - name: Step\n        run: |\n          echo \"cmd\"") }
                    Button("Step (uses)") { append("\n      - uses: actions/setup-node@v4\n        with:\n          node-version: '20'") }
                }
                RibbonSmallIconButton("Checkout", icon: "arrow.down.circle") { append("\n      - uses: actions/checkout@v4") }
                RibbonSmallIconButton("Secret", icon: "terminal") { append("\n        env:\n          SECRET: ${{ secrets.SECRET }}") }
                RibbonSmallIconButton("Matrix", icon: "tablecells") { append("\n    strategy:\n      matrix:\n        node: [18, 20, 22]") }
                RibbonMenuButton(label: "Triggers", icon: "bolt") {
                    Button("push")              { append("\n  push:\n    branches: [main]") }
                    Button("pull_request")       { append("\n  pull_request:\n    branches: [main]") }
                    Button("schedule")           { append("\n  schedule:\n    - cron: '0 0 * * *'") }
                    Button("workflow_dispatch")  { append("\n  workflow_dispatch:") }
                }
            }
        case .gitlabCI:
            RibbonGroup(label: "GitLab CI") {
                RibbonMenuButton(label: "Job/Stage", icon: "chevron.left.forwardslash.chevron.right") {
                    Button("Job")            { append("\njob:\n  stage: build\n  script:\n    - echo \"build\"") }
                    Button("Job + artifacts") { append("\njob:\n  stage: build\n  script:\n    - make build\n  artifacts:\n    paths:\n      - build/") }
                }
                RibbonSmallIconButton("Script", icon: "terminal") { append("\n    - echo \"cmd\"") }
                RibbonSmallIconButton("Variable", icon: "key") { append("\nvariables:\n  MY_VAR: \"value\"") }
                RibbonSmallIconButton("Rules", icon: "line.3.horizontal.decrease") { append("\n  rules:\n    - if: '$CI_COMMIT_BRANCH == \"main\"'") }
                RibbonSmallIconButton("Cache", icon: "archivebox") { append("\n  cache:\n    paths:\n      - node_modules/") }
            }
        case .generic:
            RibbonGroup(label: "YAML") {
                RibbonSmallIconButton("Key-Value", icon: "key") { append("\nkey: value") }
                RibbonSmallIconButton("List", icon: "list.bullet") { append("\n  - item") }
                RibbonSmallIconButton("Nested", icon: "list.bullet.indent") { append("\nparent:\n  child: value") }
                RibbonSmallIconButton("Comment", icon: "number") { append("\n# comment") }
                RibbonSmallIconButton("Anchor", icon: "link") { append("\ndefaults: &defaults\n  key: value\n\nother:\n  <<: *defaults") }
                RibbonSmallIconButton("Multiline", icon: "text.alignleft") { append("\nkey: |\n  Line one\n  Line two") }
            }
        }
    }

    // MARK: - JS/TS

    private var jsInsert: some View {
        HStack(spacing: 0) {
            RibbonGroup(label: "Functions") {
                RibbonLargeButton("Function", icon: "function") { append("\nfunction name() {\n  \n}\n") }
                RibbonLargeButton("Arrow", icon: "arrow.right") { append("\nconst name = () => {\n  \n};\n") }
                VStack(spacing: 4) {
                    RibbonSmallButton("Console", icon: "text.bubble") { append("\nconsole.log();") }
                }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Modern") {
                RibbonSmallIconButton("Async", icon: "clock.arrow.circlepath") { append("\nasync function name() {\n  \n}\n") }
                RibbonSmallIconButton("Import", icon: "arrow.down.circle") { append("\nimport { name } from 'module';") }
                RibbonSmallIconButton("Class", icon: "square.on.square") { append("\nclass MyClass {\n  constructor() {\n    \n  }\n}\n") }
                RibbonMenuButton(label: "Fetch", icon: "network") {
                    Button("async/await") { append("\nconst res = await fetch('url');\nconst data = await res.json();\n") }
                    Button(".then()")     { append("\nfetch('url')\n  .then(r => r.json())\n  .then(d => console.log(d))\n  .catch(e => console.error(e));\n") }
                }
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

    private var cssInsert: some View {
        HStack(spacing: 0) {
            RibbonGroup(label: "Insert") {
                RibbonLargeButton("Rule", icon: "paintbrush") { append("\n.class {\n  \n}\n") }
                RibbonLargeButton("Media", icon: "display") { append("\n@media (max-width: 768px) {\n  \n}\n") }
                VStack(spacing: 4) {
                    RibbonSmallButton("Variable", icon: "textformat") { append("\n  --var: value;") }
                    RibbonSmallButton("Keyframes", icon: "play") { append("\n@keyframes name {\n  from { }\n  to { }\n}\n") }
                }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Layout") {
                RibbonMenuButton(label: "Layout", icon: "rectangle.split.2x2") {
                    Button("Flexbox")     { append("\n  display: flex;\n  flex-direction: row;\n  align-items: center;\n  gap: 1rem;") }
                    Button("Flex Column") { append("\n  display: flex;\n  flex-direction: column;\n  gap: 1rem;") }
                    Button("Grid")        { append("\n  display: grid;\n  grid-template-columns: repeat(3, 1fr);\n  gap: 1rem;") }
                    Button("Center")      { append("\n  display: flex;\n  align-items: center;\n  justify-content: center;") }
                }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Comment") {
                RibbonSmallIconButton("/* */", icon: "text.justify.left") { append("\n/* */") }
            }
        }
    }

    // MARK: - Plain Text

    private var plainInsert: some View {
        HStack(spacing: 0) {
            RibbonGroup(label: "Transform") {
                RibbonLargeButton("Sort", icon: "arrow.up.arrow.down") { sortLines() }
                VStack(spacing: 4) {
                    RibbonSmallButton("Remove Empty", icon: "line.3.horizontal.decrease") { removeEmptyLines() }
                    RibbonSmallButton("Trim", icon: "scissors") { trimLines() }
                }
                VStack(spacing: 4) {
                    RibbonSmallButton("Dedup", icon: "minus.circle") { removeDuplicates() }
                }
            }
            RibbonGroupSeparator()
            RibbonGroup(label: "Case") {
                RibbonLargeButton("UPPER", icon: "textformat.abc") {
                    document.updateContent(document.content.uppercased())
                }
                RibbonLargeButton("lower", icon: "textformat.abc.dottedunderline") {
                    document.updateContent(document.content.lowercased())
                }
            }
        }
    }

    // MARK: - Helpers

    private func append(_ text: String) {
        document.updateContent(document.content + text)
    }

    private func validateJSON() {
        guard let data = document.content.data(using: .utf8) else { return }
        _ = try? JSONSerialization.jsonObject(with: data)
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

    private func sortLines() {
        let sorted = document.content.components(separatedBy: .newlines).sorted()
        document.updateContent(sorted.joined(separator: "\n"))
    }

    private func removeEmptyLines() {
        let filtered = document.content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        document.updateContent(filtered.joined(separator: "\n"))
    }

    private func trimLines() {
        let trimmed = document.content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        document.updateContent(trimmed.joined(separator: "\n"))
    }

    private func removeDuplicates() {
        var seen = Set<String>()
        let unique = document.content.components(separatedBy: .newlines)
            .filter { seen.insert($0).inserted }
        document.updateContent(unique.joined(separator: "\n"))
    }
}
