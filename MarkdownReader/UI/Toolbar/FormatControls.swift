import SwiftUI

// MARK: - Shared Components

/// A grouped section of toolbar buttons with an optional label.
struct ToolbarGroup<Content: View>: View {
    let label: String?
    @ViewBuilder let content: () -> Content

    init(_ label: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.content = content
    }

    var body: some View {
        HStack(spacing: 1) {
            if let label {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .padding(.trailing, 4)
            }
            content()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.06))
        )
    }
}

/// A single icon button used inside toolbar groups.
struct ToolbarIconButton: View {
    let label: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .frame(width: 24, height: 22)
        }
        .buttonStyle(.borderless)
        .help(label)
    }
}

/// Separator between toolbar groups.
struct ToolbarSep: View {
    var body: some View {
        Divider()
            .frame(height: 18)
            .padding(.horizontal, 6)
    }
}

/// Reusable menu button for toolbar groups.
private struct ToolbarMenuButton<Content: View>: View {
    let label: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        Menu {
            content()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 12))
                .frame(width: 24, height: 22)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help(label)
    }
}

// MARK: - Markdown Controls

struct MarkdownControls: View {
    @ObservedObject var document: DocumentModel

    var body: some View {
        HStack(spacing: 0) {
            ToolbarGroup("Text") {
                ToolbarIconButton(label: "Bold", icon: "bold") { wrap("**") }
                ToolbarIconButton(label: "Italic", icon: "italic") { wrap("_") }
                ToolbarIconButton(label: "Strikethrough", icon: "strikethrough") { wrap("~~") }
                ToolbarIconButton(label: "Code", icon: "chevron.left.forwardslash.chevron.right") { wrap("`") }
            }

            ToolbarSep()

            ToolbarGroup("Structure") {
                headerMenu
                ToolbarIconButton(label: "Quote", icon: "text.quote") { prepend("> ") }
                ToolbarIconButton(label: "Divider", icon: "minus") { append("\n---\n") }
            }

            ToolbarSep()

            ToolbarGroup("Insert") {
                ToolbarIconButton(label: "Link", icon: "link") { append("[text](url)") }
                ToolbarIconButton(label: "Image", icon: "photo") { append("![alt](url)") }
                ToolbarIconButton(label: "Bullet List", icon: "list.bullet") { prepend("- ") }
                ToolbarIconButton(label: "Numbered List", icon: "list.number") { prepend("1. ") }
                ToolbarIconButton(label: "Checklist", icon: "checklist") { prepend("- [ ] ") }
                codeBlockMenu
                ToolbarIconButton(label: "Table", icon: "tablecells") {
                    append("\n| Column 1 | Column 2 |\n|----------|----------|\n| Cell     | Cell     |\n")
                }
                ToolbarIconButton(label: "Footnote", icon: "textformat.superscript") {
                    append("[^1]\n\n[^1]: Footnote text")
                }
                ToolbarIconButton(label: "Definition", icon: "book") {
                    append("\nTerm\n: Definition")
                }
            }
        }
    }

    private var headerMenu: some View {
        ToolbarMenuButton(label: "Headers", icon: "textformat.size") {
            Button("Heading 1") { prepend("# ") }
            Button("Heading 2") { prepend("## ") }
            Button("Heading 3") { prepend("### ") }
            Button("Heading 4") { prepend("#### ") }
            Button("Heading 5") { prepend("##### ") }
            Button("Heading 6") { prepend("###### ") }
        }
    }

    private var codeBlockMenu: some View {
        ToolbarMenuButton(label: "Code Block", icon: "rectangle.split.3x3") {
            Button("Generic")    { append("\n```\n\n```\n") }
            Divider()
            Button("Swift")      { append("\n```swift\n\n```\n") }
            Button("Python")     { append("\n```python\n\n```\n") }
            Button("JavaScript") { append("\n```javascript\n\n```\n") }
            Button("TypeScript") { append("\n```typescript\n\n```\n") }
            Button("Bash")       { append("\n```bash\n\n```\n") }
            Button("JSON")       { append("\n```json\n\n```\n") }
            Button("YAML")       { append("\n```yaml\n\n```\n") }
            Button("HTML")       { append("\n```html\n\n```\n") }
            Button("CSS")        { append("\n```css\n\n```\n") }
            Button("SQL")        { append("\n```sql\n\n```\n") }
        }
    }

    private func wrap(_ marker: String) {
        document.updateContent(document.content + marker + "text" + marker)
    }

    private func prepend(_ prefix: String) {
        document.updateContent(document.content + "\n" + prefix)
    }

    private func append(_ text: String) {
        document.updateContent(document.content + text)
    }
}

// MARK: - HTML Controls

struct HTMLControls: View {
    @ObservedObject var document: DocumentModel

    var body: some View {
        HStack(spacing: 0) {
            ToolbarGroup("Block") {
                ToolbarMenuButton(label: "Semantic Elements", icon: "rectangle.3.group") {
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
                ToolbarMenuButton(label: "Structural Elements", icon: "tablecells") {
                    Button("Table") {
                        append("\n<table>\n  <thead>\n    <tr><th>Header</th></tr>\n  </thead>\n  <tbody>\n    <tr><td>Cell</td></tr>\n  </tbody>\n</table>")
                    }
                    Button("Form") {
                        append("\n<form action=\"\" method=\"POST\">\n  <label for=\"field\">Label</label>\n  <input type=\"text\" id=\"field\" name=\"field\">\n  <button type=\"submit\">Submit</button>\n</form>")
                    }
                    Button("Unordered List") { append("\n<ul>\n  <li></li>\n  <li></li>\n</ul>") }
                    Button("Ordered List")   { append("\n<ol>\n  <li></li>\n  <li></li>\n</ol>") }
                    Button("Details") { append("\n<details>\n  <summary>Title</summary>\n  <p>Content</p>\n</details>") }
                }
            }

            ToolbarSep()

            ToolbarGroup("Inline") {
                ToolbarIconButton(label: "Image", icon: "photo") {
                    append("\n<img src=\"\" alt=\"\" width=\"\" height=\"\">")
                }
                ToolbarIconButton(label: "Link", icon: "link") {
                    append("\n<a href=\"\"></a>")
                }
                ToolbarIconButton(label: "Input", icon: "rectangle.and.pencil.and.ellipsis") {
                    append("\n<input type=\"text\" name=\"\" id=\"\" placeholder=\"\">")
                }
                ToolbarIconButton(label: "Button", icon: "hand.tap") {
                    append("\n<button type=\"button\"></button>")
                }
            }

            ToolbarSep()

            ToolbarGroup("Head") {
                ToolbarIconButton(label: "meta charset", icon: "character") {
                    append("\n<meta charset=\"UTF-8\">")
                }
                ToolbarIconButton(label: "meta viewport", icon: "iphone") {
                    append("\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">")
                }
                ToolbarIconButton(label: "Stylesheet", icon: "paintbrush") {
                    append("\n<link rel=\"stylesheet\" href=\"style.css\">")
                }
                ToolbarIconButton(label: "Script", icon: "chevron.left.forwardslash.chevron.right") {
                    append("\n<script src=\"\"></script>")
                }
            }

            ToolbarSep()

            ToolbarGroup("Comment") {
                ToolbarIconButton(label: "Comment", icon: "text.justify.left") {
                    append("\n<!-- comment -->")
                }
            }
        }
    }

    private func append(_ text: String) {
        document.updateContent(document.content + text)
    }
}

// MARK: - JSON Controls

struct JSONControls: View {
    @ObservedObject var document: DocumentModel

    var body: some View {
        HStack(spacing: 0) {
            ToolbarGroup("Format") {
                ToolbarIconButton(label: "Pretty Print", icon: "text.alignleft") {
                    prettyPrint()
                }
                ToolbarIconButton(label: "Compact", icon: "arrow.right.arrow.left") {
                    compact()
                }
            }

            ToolbarSep()

            ToolbarGroup("Insert") {
                ToolbarIconButton(label: "Object {}", icon: "curlybraces") {
                    append("{\n  \n}")
                }
                ToolbarIconButton(label: "Array []", icon: "square.stack") {
                    append("[\n  \n]")
                }
                ToolbarIconButton(label: "Key-Value", icon: "key") {
                    append("\"key\": \"value\"")
                }
            }

            ToolbarSep()

            contextSnippets

            ToolbarSep()

            ToolbarGroup("Validate") {
                ToolbarIconButton(label: "Validate JSON", icon: "checkmark.seal") {
                    validateJSON()
                }
            }
        }
    }

    @ViewBuilder
    private var contextSnippets: some View {
        switch document.jsonSubtype {
        case .packageJSON:
            ToolbarGroup("package.json") {
                ToolbarMenuButton(label: "Snippets", icon: "shippingbox") {
                    Button("scripts") {
                        append("\n  \"scripts\": {\n    \"start\": \"node index.js\",\n    \"build\": \"tsc\",\n    \"test\": \"jest\",\n    \"dev\": \"nodemon\"\n  }")
                    }
                    Button("dependencies") {
                        append("\n  \"dependencies\": {\n    \"package-name\": \"^1.0.0\"\n  }")
                    }
                    Button("devDependencies") {
                        append("\n  \"devDependencies\": {\n    \"typescript\": \"^5.0.0\",\n    \"@types/node\": \"^20.0.0\"\n  }")
                    }
                    Button("engines") {
                        append("\n  \"engines\": {\n    \"node\": \">=18.0.0\"\n  }")
                    }
                    Button("repository") {
                        append("\n  \"repository\": {\n    \"type\": \"git\",\n    \"url\": \"https://github.com/user/repo.git\"\n  }")
                    }
                }
            }
        case .tsconfig:
            ToolbarGroup("tsconfig") {
                ToolbarMenuButton(label: "Snippets", icon: "gearshape") {
                    Button("compilerOptions (strict)") {
                        append("\n  \"compilerOptions\": {\n    \"target\": \"ES2022\",\n    \"module\": \"NodeNext\",\n    \"strict\": true,\n    \"esModuleInterop\": true,\n    \"outDir\": \"./dist\",\n    \"rootDir\": \"./src\"\n  }")
                    }
                    Button("include / exclude") {
                        append("\n  \"include\": [\"src/**/*\"],\n  \"exclude\": [\"node_modules\", \"dist\"]")
                    }
                    Button("paths (aliases)") {
                        append("\n    \"paths\": {\n      \"@/*\": [\"./src/*\"]\n    }")
                    }
                }
            }
        case .eslint:
            ToolbarGroup("ESLint") {
                ToolbarMenuButton(label: "Snippets", icon: "checkmark.shield") {
                    Button("rules") {
                        append("\n  \"rules\": {\n    \"no-console\": \"warn\",\n    \"no-unused-vars\": \"error\"\n  }")
                    }
                    Button("extends") {
                        append("\n  \"extends\": [\"eslint:recommended\"]")
                    }
                    Button("env") {
                        append("\n  \"env\": {\n    \"browser\": true,\n    \"node\": true,\n    \"es2022\": true\n  }")
                    }
                }
            }
        case .generic:
            ToolbarGroup("Snippets") {
                ToolbarIconButton(label: "String", icon: "textformat") {
                    append("\"key\": \"value\"")
                }
                ToolbarIconButton(label: "Number", icon: "number") {
                    append("\"key\": 0")
                }
                ToolbarIconButton(label: "Boolean", icon: "switch.2") {
                    append("\"key\": true")
                }
                ToolbarIconButton(label: "Null", icon: "circle.slash") {
                    append("\"key\": null")
                }
            }
        }
    }

    private func prettyPrint() {
        guard let data = document.content.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: pretty, encoding: .utf8) else { return }
        document.updateContent(str)
    }

    private func compact() {
        guard let data = document.content.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let compact = try? JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys]),
              let str = String(data: compact, encoding: .utf8) else { return }
        document.updateContent(str)
    }

    private func validateJSON() {
        guard let data = document.content.data(using: .utf8) else { return }
        do {
            _ = try JSONSerialization.jsonObject(with: data)
        } catch {
            // lint panel shows the error
        }
    }

    private func append(_ text: String) {
        document.updateContent(document.content + text)
    }
}

// MARK: - YAML Controls

struct YAMLControls: View {
    @ObservedObject var document: DocumentModel

    var body: some View {
        HStack(spacing: 0) {
            subtypeBadge

            ToolbarSep()

            switch document.yamlSubtype {
            case .dockerCompose: dockerComposeInserts
            case .kubernetes:    kubernetesInserts
            case .githubActions: githubActionsInserts
            case .gitlabCI:      gitlabCIInserts
            case .generic:       genericInserts
            }

            ToolbarSep()

            sharedFormatGroup
        }
    }

    // MARK: - Subtype Badge

    private var subtypeBadge: some View {
        let (label, icon): (String, String) = {
            switch document.yamlSubtype {
            case .dockerCompose:  return ("Compose", "shippingbox")
            case .kubernetes:     return ("K8s", "server.rack")
            case .githubActions:  return ("Actions", "play.rectangle")
            case .gitlabCI:       return ("GitLab CI", "chevron.left.forwardslash.chevron.right")
            case .generic:        return ("YAML", "doc.text")
            }
        }()
        return HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10))
            Text(label).font(.system(size: 10, weight: .medium))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.1)))
        .foregroundStyle(.secondary)
        .help("Detected: \(label)")
    }

    // MARK: - Docker Compose

    private var dockerComposeInserts: some View {
        ToolbarGroup("Insert") {
            ToolbarMenuButton(label: "Add Service", icon: "plus.rectangle.on.rectangle") {
                Button("Service (basic)") {
                    append("\n  service-name:\n    image: image:latest\n    ports:\n      - \"8080:80\"\n    environment:\n      - ENV_VAR=value")
                }
                Button("Service (build)") {
                    append("\n  service-name:\n    build: .\n    ports:\n      - \"8080:80\"\n    depends_on:\n      - db")
                }
                Button("Service (with volumes)") {
                    append("\n  service-name:\n    image: image:latest\n    volumes:\n      - ./data:/app/data\n    restart: unless-stopped")
                }
            }
            ToolbarIconButton(label: "Environment", icon: "terminal") {
                append("\n      - MY_VAR=value")
            }
            ToolbarIconButton(label: "Port", icon: "arrow.left.arrow.right") {
                append("\n      - \"HOST:CONTAINER\"")
            }
            ToolbarIconButton(label: "Volume", icon: "externaldrive") {
                append("\n    volumes:\n      - ./data:/app/data")
            }
            ToolbarIconButton(label: "depends_on", icon: "arrow.down.circle") {
                append("\n    depends_on:\n      - service-name")
            }
            ToolbarIconButton(label: "Network", icon: "network") {
                append("\n\nnetworks:\n  my-network:\n    driver: bridge")
            }
        }
    }

    // MARK: - Kubernetes

    private var kubernetesInserts: some View {
        ToolbarGroup("Insert") {
            ToolbarMenuButton(label: "Resources", icon: "square.stack.3d.up") {
                Button("Deployment") {
                    append("\n---\napiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: my-app\n  labels:\n    app: my-app\nspec:\n  replicas: 1\n  selector:\n    matchLabels:\n      app: my-app\n  template:\n    metadata:\n      labels:\n        app: my-app\n    spec:\n      containers:\n        - name: my-app\n          image: my-image:latest\n          ports:\n            - containerPort: 80")
                }
                Button("Service") {
                    append("\n---\napiVersion: v1\nkind: Service\nmetadata:\n  name: my-service\nspec:\n  selector:\n    app: my-app\n  ports:\n    - protocol: TCP\n      port: 80\n      targetPort: 80\n  type: ClusterIP")
                }
                Button("ConfigMap") {
                    append("\n---\napiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: my-config\ndata:\n  KEY: value")
                }
                Button("Secret") {
                    append("\n---\napiVersion: v1\nkind: Secret\nmetadata:\n  name: my-secret\ntype: Opaque\ndata:\n  KEY: base64-encoded-value")
                }
                Button("Ingress") {
                    append("\n---\napiVersion: networking.k8s.io/v1\nkind: Ingress\nmetadata:\n  name: my-ingress\nspec:\n  rules:\n    - host: example.com\n      http:\n        paths:\n          - path: /\n            pathType: Prefix\n            backend:\n              service:\n                name: my-service\n                port:\n                  number: 80")
                }
            }
            ToolbarIconButton(label: "Container", icon: "shippingbox") {
                append("\n        - name: container\n          image: image:tag\n          ports:\n            - containerPort: 80\n          resources:\n            requests:\n              memory: \"64Mi\"\n              cpu: \"250m\"\n            limits:\n              memory: \"128Mi\"\n              cpu: \"500m\"")
            }
            ToolbarIconButton(label: "Env (configMap)", icon: "key") {
                append("\n          env:\n            - name: MY_VAR\n              valueFrom:\n                configMapKeyRef:\n                  name: my-config\n                  key: KEY")
            }
            ToolbarIconButton(label: "Env (secret)", icon: "lock") {
                append("\n          env:\n            - name: MY_SECRET\n              valueFrom:\n                secretKeyRef:\n                  name: my-secret\n                  key: KEY")
            }
            ToolbarIconButton(label: "---", icon: "minus") {
                append("\n---\n")
            }
        }
    }

    // MARK: - GitHub Actions

    private var githubActionsInserts: some View {
        ToolbarGroup("Insert") {
            ToolbarMenuButton(label: "Job / Step", icon: "play.rectangle") {
                Button("Job") {
                    append("\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - name: Run step\n        run: echo \"Hello\"")
                }
                Button("Step (run)") {
                    append("\n      - name: Step name\n        run: |\n          echo \"command\"")
                }
                Button("Step (uses)") {
                    append("\n      - uses: actions/setup-node@v4\n        with:\n          node-version: '20'")
                }
            }
            ToolbarIconButton(label: "Checkout", icon: "arrow.down.circle") {
                append("\n      - uses: actions/checkout@v4")
            }
            ToolbarIconButton(label: "Env / Secret", icon: "terminal") {
                append("\n        env:\n          MY_SECRET: ${{ secrets.MY_SECRET }}")
            }
            ToolbarIconButton(label: "Matrix", icon: "tablecells") {
                append("\n    strategy:\n      matrix:\n        node-version: [18, 20, 22]")
            }
            ToolbarMenuButton(label: "Triggers", icon: "bolt") {
                Button("push") { append("\n  push:\n    branches: [main]") }
                Button("pull_request") { append("\n  pull_request:\n    branches: [main]") }
                Button("schedule (cron)") { append("\n  schedule:\n    - cron: '0 0 * * *'") }
                Button("workflow_dispatch") { append("\n  workflow_dispatch:") }
            }
        }
    }

    // MARK: - GitLab CI

    private var gitlabCIInserts: some View {
        ToolbarGroup("Insert") {
            ToolbarMenuButton(label: "Job / Stage", icon: "chevron.left.forwardslash.chevron.right") {
                Button("Job") {
                    append("\nbuild-job:\n  stage: build\n  script:\n    - echo \"Running build\"")
                }
                Button("Stage") {
                    append("\n  - stage-name")
                }
                Button("Job with artifacts") {
                    append("\nbuild-job:\n  stage: build\n  script:\n    - make build\n  artifacts:\n    paths:\n      - build/")
                }
            }
            ToolbarIconButton(label: "Script", icon: "terminal") {
                append("\n    - echo \"command\"")
            }
            ToolbarIconButton(label: "Variable", icon: "key") {
                append("\nvariables:\n  MY_VAR: \"value\"")
            }
            ToolbarIconButton(label: "Rules", icon: "line.3.horizontal.decrease") {
                append("\n  rules:\n    - if: '$CI_COMMIT_BRANCH == \"main\"'")
            }
            ToolbarIconButton(label: "Cache", icon: "archivebox") {
                append("\n  cache:\n    paths:\n      - node_modules/")
            }
        }
    }

    // MARK: - Generic YAML

    private var genericInserts: some View {
        ToolbarGroup("Insert") {
            ToolbarIconButton(label: "Key-Value", icon: "key") {
                append("\nkey: value")
            }
            ToolbarIconButton(label: "List Item", icon: "list.bullet") {
                append("\n  - item")
            }
            ToolbarIconButton(label: "Nested Object", icon: "list.bullet.indent") {
                append("\nparent:\n  child: value")
            }
            ToolbarIconButton(label: "Comment", icon: "number") {
                append("\n# comment")
            }
            ToolbarIconButton(label: "Anchor & Alias", icon: "link") {
                append("\ndefaults: &defaults\n  key: value\n\nother:\n  <<: *defaults")
            }
            ToolbarIconButton(label: "Multiline String", icon: "text.alignleft") {
                append("\ndescription: |\n  Line one\n  Line two")
            }
        }
    }

    // MARK: - Shared Format Group

    private var sharedFormatGroup: some View {
        ToolbarGroup("Format") {
            ToolbarIconButton(label: "Sort Keys", icon: "arrow.up.arrow.down") {
                sortRootKeys()
            }
            ToolbarIconButton(label: "Trim Trailing Spaces", icon: "scissors") {
                trimTrailing()
            }
        }
    }

    // MARK: - Helpers

    private func sortRootKeys() {
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

    private func append(_ text: String) {
        document.updateContent(document.content + text)
    }
}

// MARK: - JavaScript Controls

struct JSControls: View {
    @ObservedObject var document: DocumentModel

    var body: some View {
        HStack(spacing: 0) {
            ToolbarGroup("Insert") {
                ToolbarIconButton(label: "Function", icon: "function") {
                    append("\nfunction name() {\n  \n}\n")
                }
                ToolbarIconButton(label: "Arrow Function", icon: "arrow.right") {
                    append("\nconst name = () => {\n  \n};\n")
                }
                ToolbarIconButton(label: "Console Log", icon: "text.bubble") {
                    append("\nconsole.log();")
                }
                ToolbarIconButton(label: "If Block", icon: "questionmark.diamond") {
                    append("\nif (condition) {\n  \n}\n")
                }
                ToolbarIconButton(label: "Try-Catch", icon: "exclamationmark.shield") {
                    append("\ntry {\n  \n} catch (error) {\n  console.error(error);\n}\n")
                }
            }

            ToolbarSep()

            ToolbarGroup("Modern") {
                ToolbarIconButton(label: "Async Function", icon: "clock.arrow.circlepath") {
                    append("\nasync function name() {\n  \n}\n")
                }
                ToolbarIconButton(label: "Import", icon: "arrow.down.circle") {
                    append("\nimport { name } from 'module';")
                }
                ToolbarIconButton(label: "Class", icon: "square.on.square") {
                    append("\nclass MyClass {\n  constructor() {\n    \n  }\n\n  method() {\n    \n  }\n}\n")
                }
                ToolbarMenuButton(label: "Fetch", icon: "network") {
                    Button("async/await") {
                        append("\nconst response = await fetch('url');\nconst data = await response.json();\n")
                    }
                    Button(".then()") {
                        append("\nfetch('url')\n  .then(res => res.json())\n  .then(data => console.log(data))\n  .catch(err => console.error(err));\n")
                    }
                }
                ToolbarIconButton(label: "Promise", icon: "circle.dashed") {
                    append("\nnew Promise((resolve, reject) => {\n  \n});\n")
                }
            }

            ToolbarSep()

            ToolbarGroup("Comment") {
                ToolbarIconButton(label: "Line Comment", icon: "text.line.first.and.arrowtriangle.forward") {
                    append("\n// ")
                }
                ToolbarIconButton(label: "Block Comment", icon: "text.justify.left") {
                    append("\n/* */")
                }
                ToolbarIconButton(label: "JSDoc", icon: "doc.text") {
                    append("\n/**\n * \n * @param {type} name\n * @returns {type}\n */")
                }
            }
        }
    }

    private func append(_ text: String) {
        document.updateContent(document.content + text)
    }
}

// MARK: - CSS Controls

struct CSSControls: View {
    @ObservedObject var document: DocumentModel

    var body: some View {
        HStack(spacing: 0) {
            ToolbarGroup("Insert") {
                ToolbarIconButton(label: "Rule", icon: "paintbrush") {
                    append("\n.class-name {\n  \n}\n")
                }
                ToolbarIconButton(label: "Media Query", icon: "display") {
                    append("\n@media (max-width: 768px) {\n  \n}\n")
                }
                ToolbarIconButton(label: "Variable", icon: "textformat") {
                    append("\n  --var-name: value;")
                }
                ToolbarIconButton(label: "Keyframes", icon: "play") {
                    append("\n@keyframes name {\n  from { }\n  to { }\n}\n")
                }
            }

            ToolbarSep()

            ToolbarGroup("Layout") {
                ToolbarMenuButton(label: "Layout Snippets", icon: "rectangle.split.2x2") {
                    Button("Flexbox Container") {
                        append("\n  display: flex;\n  flex-direction: row;\n  align-items: center;\n  justify-content: space-between;\n  gap: 1rem;")
                    }
                    Button("Flex Column") {
                        append("\n  display: flex;\n  flex-direction: column;\n  gap: 1rem;")
                    }
                    Button("Grid Container") {
                        append("\n  display: grid;\n  grid-template-columns: repeat(3, 1fr);\n  gap: 1rem;")
                    }
                    Button("Center (flex)") {
                        append("\n  display: flex;\n  align-items: center;\n  justify-content: center;")
                    }
                }
                ToolbarIconButton(label: "Animation", icon: "waveform.path") {
                    append("\n  animation: name 1s ease-in-out infinite;")
                }
                ToolbarIconButton(label: "Transition", icon: "arrow.left.and.right") {
                    append("\n  transition: all 0.2s ease;")
                }
                ToolbarIconButton(label: "Variables (:root)", icon: "list.bullet.indent") {
                    append("\n:root {\n  --color-primary: #007aff;\n  --color-secondary: #5856d6;\n  --spacing-sm: 0.5rem;\n  --spacing-md: 1rem;\n  --font-body: system-ui, sans-serif;\n}\n")
                }
            }

            ToolbarSep()

            ToolbarGroup("Comment") {
                ToolbarIconButton(label: "Comment", icon: "text.justify.left") {
                    append("\n/* */")
                }
            }
        }
    }

    private func append(_ text: String) {
        document.updateContent(document.content + text)
    }
}

// MARK: - Plain Text Controls

struct PlainTextControls: View {
    @ObservedObject var document: DocumentModel

    var body: some View {
        HStack(spacing: 0) {
            ToolbarGroup("Edit") {
                ToolbarIconButton(label: "Sort Lines", icon: "arrow.up.arrow.down") {
                    sortLines()
                }
                ToolbarIconButton(label: "Remove Empty Lines", icon: "line.3.horizontal.decrease") {
                    removeEmptyLines()
                }
                ToolbarIconButton(label: "Trim Lines", icon: "scissors") {
                    trimLines()
                }
                ToolbarIconButton(label: "Remove Duplicates", icon: "minus.circle") {
                    removeDuplicates()
                }
            }

            ToolbarSep()

            ToolbarGroup("Case") {
                ToolbarIconButton(label: "UPPERCASE", icon: "textformat.abc") {
                    document.updateContent(document.content.uppercased())
                }
                ToolbarIconButton(label: "lowercase", icon: "textformat.abc.dottedunderline") {
                    document.updateContent(document.content.lowercased())
                }
            }
        }
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
