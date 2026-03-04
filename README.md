# MarkEdit

Editor de código e markup nativo para macOS, construído com Swift, SwiftUI e AppKit.

O MarkEdit suporta múltiplos formatos de arquivo com syntax highlighting, linting em tempo real, controles contextuais por tipo de arquivo e conversão entre formatos — tudo em uma interface inspirada no Pages.

![macOS 15+](https://img.shields.io/badge/macOS-15%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![144 tests](https://img.shields.io/badge/tests-144%20passing-brightgreen)

---

## Formatos Suportados

| Formato | Extensoes | Highlighting | Linting | Conversao |
|---|---|---|---|---|
| Markdown | `.md` `.markdown` `.mdown` `.mkd` | Highlight.js | — | → Plain Text |
| JSON | `.json` `.jsonl` | Highlight.js | Nativo (JSONSerialization) | → YAML |
| YAML | `.yaml` `.yml` | Highlight.js | yamllint + builtin | → JSON |
| JavaScript | `.js` `.jsx` `.mjs` `.cjs` | Highlight.js | ESLint + builtin | — |
| TypeScript | `.ts` `.tsx` `.mts` `.cts` | Highlight.js | ESLint + builtin | — |
| CSS | `.css` `.scss` `.less` | Highlight.js | Stylelint + builtin | — |
| Plain Text | `.txt` e qualquer extensao nao reconhecida | — | — | → Markdown |

Alem desses, o highlighter reconhece **23 linguagens** (Swift, Python, Go, Rust, Java, Kotlin, C/C++, Ruby, SQL, Bash, Dockerfile, Makefile, XML/HTML, INI e mais).

---

## Arquitetura

```
MarkdownReader/
├── App/
│   ├── MarkEditApp.swift          # @main, menus, atalhos, Notification.Name
│   └── AppDelegate.swift          # Abertura via Finder, restore do ultimo arquivo
├── Core/
│   ├── FileManager/
│   │   ├── DocumentModel.swift    # Estado do documento (ObservableObject)
│   │   ├── FileIO.swift           # Open/Save panels, read/write, bookmarks
│   │   └── FormatConverter.swift  # JSON<->YAML, Markdown->Plain
│   ├── Lint/
│   │   ├── LintEngine.swift       # Orquestrador async com debounce
│   │   ├── JSONLinter.swift       # Validacao nativa de JSON
│   │   ├── YAMLLinter.swift       # yamllint externo + fallback builtin
│   │   ├── JSLinter.swift         # ESLint externo + fallback builtin (JS/TS)
│   │   └── CSSLinter.swift        # Stylelint externo + fallback builtin
│   └── SyntaxHighlight/
│       ├── HighlightEngine.swift  # WKWebView com Highlight.js embutido
│       └── LanguageMap.swift      # Mapeamento extensao -> linguagem
├── UI/
│   ├── EditorView.swift           # View principal, orquestra tudo
│   ├── CodeTextView.swift         # NSTextView customizado (MarkEditTextView)
│   ├── Toolbar/
│   │   ├── ToolbarView.swift      # Toolbar dupla estilo Pages
│   │   └── FormatControls.swift   # Controles contextuais por tipo
│   ├── StatusBar/
│   │   └── StatusBarView.swift    # Cursor, contagem, encoding, lint
│   └── Sidebar/
│       └── LintPanel.swift        # Painel de issues com filtros
└── Resources/
    └── highlight/                 # Highlight.js 11.9.0 bundled
```

### Fluxo de Dados

```
NSTextView (usuario edita)
    │
    ▼
DocumentModel (@Published content)
    │
    ├──▶ HighlightEngine (WKWebView re-render)
    │
    └──▶ LintEngine.run() (Task async com debounce)
              │
              ├── JSONLinter / YAMLLinter / JSLinter / CSSLinter
              │
              ▼
         LintEngine.issues (@Published)
              │
              ├──▶ LintPanel (lista clicavel)
              ├──▶ StatusBarView (issue da linha atual)
              └──▶ CodeTextView (overlays vermelho/laranja)
```

Menus e atalhos de teclado comunicam com `EditorView` via `NotificationCenter`, ja que SwiftUI `Commands` nao tem acesso direto ao estado.

---

## Layout da Interface

```
┌─────────────────────────────────────────────────────────┐
│ Toolbar Primaria: [Tipo] NomeArquivo •    [Preview][Lint]│
│ Toolbar Secundaria: [Controles Contextuais]   [Converter]│
├─────────────────────────────────────┬───────────────────┤
│                                     │                   │
│           CodeTextView              │   HighlightEngine │
│         (editor principal)          │    (preview opt.) │
│                                     │                   │
│  ░░ linhas com erro em vermelho     │                   │
│  ░░ linhas com warning em laranja   │                   │
│                                     │                   │
├─────────────────────────────────────┴───────────────────┤
│ ⚠ Erro na linha 42: Unexpected token (JSON)   [regra]  │ ← Issue bar (qdo cursor esta na linha)
├─────────────────────────────────────────────────────────┤
│ Ln 42, Col 8 │ 156 lines, 3.2K chars │ JSON │ UTF-8    │ ← Status bar
└─────────────────────────────────────────────────────────┘
                                              ┌───────────┐
                                              │ Lint Panel│
                                              │ [All][E][W]│
                                              │ ⛔ L12 ... │
                                              │ ⚠ L42 ... │
                                              │ ℹ L98 ... │
                                              └───────────┘
```

---

## Fluxos Principais

### Abrir Arquivo

Tres caminhos convergem para `EditorView.loadFile(url:)`:

1. **Menu (Cmd+O)** → `FileIO.open()` → NSOpenPanel → callback
2. **Finder (duplo clique / arrastar no Dock)** → `AppDelegate.application(_:open:)` → `FileOpenRequest`
3. **Drag & drop na janela** → `onDrop(of: .fileURL)` → `NSItemProvider.loadItem`

Ao abrir: le conteudo + detecta encoding → define FileType pela extensao → salva bookmark → dispara lint → atualiza titulo da janela.

### Salvar Arquivo

- **Cmd+S**: salva no URL atual (ou cai no Save As se nao tiver URL)
- **Cmd+Shift+S**: NSSavePanel → novo URL → atualiza FileType → salva bookmark

### Conversao de Formato

`ToolbarView` → menu "Converter para..." → `FormatConverter.convert()` → atualiza content e FileType → proximo Save grava no novo formato.

| De | Para | Metodo |
|---|---|---|
| JSON | YAML | JSONSerialization → serializador YAML recursivo |
| YAML | JSON | Parser linha-a-linha → JSONSerialization |
| Markdown | Plain | 10 passes de regex (strip headers, bold, links, etc.) |
| Plain | Markdown | Identidade (texto puro e Markdown valido) |

### Linting em Tempo Real

1. Usuario edita → `document.content` muda
2. `LintEngine.run()` cancela task anterior, lanca nova
3. Linter adequado ao FileType roda (async)
4. Issues publicadas → UI reage:
   - **CodeTextView**: overlay vermelho (erro) ou laranja (warning) nas linhas
   - **StatusBarView**: mostra issue quando cursor esta na linha
   - **LintPanel**: lista completa com filtros (All/Errors/Warnings/Info)
   - Clicar numa issue → editor navega ate a linha com flash amarelo

### Restaurar Ultimo Arquivo

No launch: `AppDelegate` le `UserDefaults["lastOpenedFile"]` → resolve security-scoped bookmark → abre automaticamente.

---

## Atalhos de Teclado

| Acao | Atalho |
|---|---|
| Novo documento | `Cmd+N` |
| Abrir | `Cmd+O` |
| Salvar | `Cmd+S` |
| Salvar como | `Cmd+Shift+S` |
| Toggle preview | `Cmd+Shift+P` |
| Toggle painel de lint | `Cmd+Shift+L` |
| Apagar linha a partir do cursor | `Cmd+K` |
| Find | `Cmd+F` (nativo NSTextView) |
| Copy/Paste/Undo/Redo | Todos os padroes macOS mantidos |

---

## Sistema de Lint

### Ferramentas Externas (opcionais)

O app funciona sem nenhuma ferramenta externa — degrada para checks builtin.

| Ferramenta | Usado por | Instalacao |
|---|---|---|
| `yamllint` | YAMLLinter | `brew install yamllint` |
| `eslint` | JSLinter (JS/TS) | `npm install -g eslint` ou local `node_modules` |
| `stylelint` | CSSLinter | `npm install -g stylelint` ou local `node_modules` |

Busca automatica em: `/opt/homebrew/bin`, `/usr/local/bin`, `/usr/bin`, `./node_modules/.bin`

### Regras Builtin

**JSON**: erros de parse com linha/coluna extraidos do NSError.

**YAML**: `no-tabs` (erro), `trailing-spaces` (warning), `indentation` (impar, warning), `document-start` (info), `no-duplicate-keys` (erro).

**JS/TS**: `no-console` (warning), `no-var` (warning), `no-debugger` (erro), `no-alert` (warning), `no-eval` (erro), `eqeqeq` (warning), `no-explicit-any` (TS only, warning).

**CSS**: `no-important` (warning), `no-inline-styles` (info), `no-empty-rules` (warning).

---

## Controles Contextuais por Tipo

Cada tipo de arquivo tem controles especificos na toolbar secundaria:

- **Markdown**: Bold, Italic, Strikethrough, Code, Headers (1-6), Quote, Divider, Link, Image, Listas, Code Block, Table
- **JSON**: Pretty Print, Compact, Insert Object/Array/Key-Value, Validate
- **YAML**: Insert Key-Value/List/Nested Object/Comment, Sort Keys, Trim Trailing
- **JS/TS**: Insert Function/Arrow Fn/console.log/If/Try-Catch, Line/Block/JSDoc Comment
- **CSS**: Insert Rule/Media Query/Variable/Keyframes, Block Comment
- **Plain Text**: Sort Lines, Remove Empty/Duplicates, Trim Lines, UPPERCASE/lowercase

---

## Registro de Tipos de Arquivo

O app se registra como handler no Finder via `Info.plist`:

- **Handler padrao** (abre automaticamente com duplo clique): Markdown, YAML, TypeScript
- **Handler alternativo** (aparece em "Abrir com"): JSON, JavaScript, CSS, Plain Text

UTIs customizados declarados para formatos sem UTI nativo (TypeScript, YAML, Markdown, CSS com SCSS/LESS).

---

## Sandbox e Seguranca

| Entitlement | Funcao |
|---|---|
| `app-sandbox` | Sandbox completo |
| `files.user-selected.read-write` | Acesso a arquivos escolhidos pelo usuario |
| `files.bookmarks.app-scope` | Persistir acesso entre sessoes |
| `network.client` | WKWebView (carregamento local de recursos) |

Security-scoped bookmarks garantem que o app pode reabrir o ultimo arquivo mesmo apos reiniciar.

---

## Testes

**144 testes** cobrindo toda a camada Core:

| Suite | Testes | Cobertura |
|---|---|---|
| DocumentModelTests | 20 | Estado inicial, fileName, fileExtension, updateContent, markClean, todos os FileTypes |
| LanguageMapTests | 25 | Todos os 40+ mapeamentos de extensao, case insensitivity, bundledLanguages |
| FormatConverterTests | 18 | canTransform, JSON↔YAML, Markdown→Plain, passthrough |
| JSONLinterTests | 10 | JSON valido/invalido, numeros de linha, extensoes |
| YAMLLinterTests | 11 | Tabs, whitespace, indentacao, chaves duplicadas, document-start |
| JSLinterTests | 16 | console.log, var, debugger, alert, eval, ==, any (TS), multiplos issues |
| CSSLinterTests | 7 | !important, empty rules, inline styles, line numbers |
| LintEngineTests | 6 | Estado inicial, clear, run async, contadores |
| LintIssueTests | 5 | Severity ordering, criacao, Identifiable, Hashable |
| FileIOTests | 9 | Read/write UTF-8, encoding, round-trip, unicode |
| ExternalToolTests | 6 | find(), BundledHighlight script tags com dependencias |

```bash
xcodebuild test -project MarkEdit.xcodeproj -scheme MarkEdit -destination 'platform=macOS'
```

---

## Build

### Requisitos

- macOS 15+
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (para regenerar o .xcodeproj)

### Comandos

```bash
# Gerar projeto Xcode
xcodegen generate

# Build
xcodebuild build -project MarkEdit.xcodeproj -scheme MarkEdit -destination 'platform=macOS'

# Rodar testes
xcodebuild test -project MarkEdit.xcodeproj -scheme MarkEdit -destination 'platform=macOS'
```

---

## Licenca

Uso pessoal.
