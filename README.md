# MarkEdit

Editor de codigo e markup nativo para macOS, construido com Swift, SwiftUI e AppKit.

O MarkEdit suporta multiplos formatos de arquivo com syntax highlighting, linting em tempo real, code folding, diff integrado, bookmarks, bracket matching, column selection e controles contextuais por tipo de arquivo — tudo em uma interface nativa que segue as [Human Interface Guidelines da Apple](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos).

![macOS 15+](https://img.shields.io/badge/macOS-15%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![290 tests](https://img.shields.io/badge/tests-290%20passing-brightgreen)

---

## Funcionalidades

### Editor

- **Syntax highlighting** via Highlight.js para 23+ linguagens
- **Linting em tempo real** com ferramentas externas opcionais e regras builtin
- **Code folding** — colapsa blocos `{}`, `[]` e headers Markdown com triangulos clicaveis no gutter
- **Line numbers** — numeros de linha no gutter combinado com indicadores visuais
- **Column/block selection** — Option+drag para selecao retangular multi-linha
- **Bracket matching** — destaque visual do par correspondente para `{}`, `[]`, `()`, `<>`, aspas e backticks
- **Diff integrado** — compara versao atual com o arquivo salvo no disco (Cmd+D)
- **Line bookmarks** — marca/desmarca linhas (Cmd+F2) e navega entre elas (F2 / Shift+F2)
- **Find & Replace** — busca com highlight de todos os matches, auto-unfold de regioes colapsadas
- **Word wrap toggle** — liga/desliga quebra de linha pela status bar
- **Encoding picker** — detecta e permite trocar encoding (UTF-8, UTF-16, ASCII, ISO-8859-1, Windows-1252)
- **Preview side-by-side** — Markdown renderizado, HTML ao vivo, ou syntax highlight para outros formatos
- **Conversao de formato** — JSON<->YAML, Markdown->Plain Text
- **Edicao remota via SSH** — abre, edita e salva arquivos em servidores remotos via SFTP (Citadel/SwiftNIO)
- **Session restore completo** — restaura todas as abas (locais e remotas), posicoes e estados ao reabrir o app
- **Drag & drop** — arraste arquivos para abrir em nova aba
- **Multi-tab** — abas com Cmd+T, Cmd+W, Ctrl+Tab para navegar

### Gutter Combinado (56pt)

O gutter esquerdo integra multiplas informacoes em uma unica coluna:

| Zona | Largura | Conteudo |
|---|---|---|
| Diff | 0-3pt | Barra colorida (verde=adicionado, azul=modificado, vermelho=removido) |
| Marcadores | 3-10pt | Diamante de bookmark (accent color) / dot de erro/warning |
| Numeros | 10-40pt | Numero da linha (alinhado a direita, destaque na linha atual) |
| Fold | 42-56pt | Triangulo de disclosure (expandido/colapsado) |

### Status Bar

```
┌──────────────────────────────────────────────────────────────────────────┐
│ ⌶ Ln 42, Col 8 │ 156 lines, 3200 chars │ JSON │ 🌐 Remote │ Wrap │ UTF-8  │
└──────────────────────────────────────────────────────────────────────────┘
```

- Posicao do cursor (ou "Sel: Ln X-Y, Col X-Y" durante column selection)
- Contagem de linhas e caracteres
- Tipo de arquivo
- Indicador "Remote" (visivel apenas para arquivos remotos via SSH)
- Toggle de word wrap
- Picker de encoding com menu
- Sumario de lint (erros/warnings ou "No issues")
- Issue bar contextual quando o cursor esta em uma linha com problema

---

## Formatos Suportados

| Formato | Extensoes | Highlighting | Linting | Conversao |
|---|---|---|---|---|
| Markdown | `.md` `.markdown` `.mdown` `.mkd` | Highlight.js | — | -> Plain Text |
| JSON | `.json` `.jsonl` | Highlight.js | Nativo (JSONSerialization) | -> YAML |
| YAML | `.yaml` `.yml` | Highlight.js | yamllint + builtin | -> JSON |
| JavaScript | `.js` `.jsx` `.mjs` `.cjs` | Highlight.js | ESLint + builtin | — |
| TypeScript | `.ts` `.tsx` `.mts` `.cts` | Highlight.js | ESLint + builtin | — |
| CSS | `.css` `.scss` `.less` | Highlight.js | Stylelint + builtin | — |
| Plain Text | `.txt` e qualquer extensao nao reconhecida | — | — | -> Markdown |

Alem desses, o highlighter reconhece **23 linguagens** (Swift, Python, Go, Rust, Java, Kotlin, C/C++, Ruby, SQL, Bash, Dockerfile, Makefile, XML/HTML, INI e mais).

---

## Arquitetura

```
MarkdownReader/
├── App/
│   ├── MarkEditApp.swift          # @main, menus, atalhos, Notification.Name
│   └── AppDelegate.swift          # Abertura via Finder, session restore
├── Core/
│   ├── FileManager/
│   │   ├── DocumentModel.swift    # Estado do documento (ObservableObject)
│   │   ├── TabStore.swift         # Modelo de abas com session state
│   │   ├── FileIO.swift           # Open/Save panels, read/write, bookmarks
│   │   └── FormatConverter.swift  # JSON<->YAML, Markdown->Plain
│   ├── Lint/
│   │   ├── LintEngine.swift       # Orquestrador async com debounce
│   │   ├── JSONLinter.swift       # Validacao nativa de JSON
│   │   ├── YAMLLinter.swift       # yamllint externo + fallback builtin
│   │   ├── JSLinter.swift         # ESLint externo + fallback builtin (JS/TS)
│   │   ├── CSSLinter.swift        # Stylelint externo + fallback builtin
│   │   └── ExternalTool.swift     # Runner compartilhado para linters externos
│   ├── Folding/
│   │   ├── FoldRegion.swift       # Modelo de regiao dobravel
│   │   ├── FoldingEngine.swift    # Parser de content + gerenciador de estado
│   │   └── FoldLayoutManagerDelegate.swift  # NSLayoutManagerDelegate (altura zero)
│   ├── Diff/
│   │   └── DiffEngine.swift       # Diff LCS linha-a-linha com arquivo em disco
│   ├── Bookmarks/
│   │   └── BookmarkEngine.swift   # Toggle, navegacao e ajuste de bookmarks
│   ├── BracketMatching/
│   │   └── BracketMatcher.swift   # Match de brackets, aspas e backticks
│   ├── SSH/
│   │   ├── SSHConnectionProfile.swift   # Perfil de conexao (Codable, UserDefaults)
│   │   ├── RemoteFileReference.swift    # Referencia a arquivo remoto (profileID + path)
│   │   ├── SSHConnectionManager.swift   # Singleton: connect/disconnect/reconnect via Citadel
│   │   ├── RemoteFileIO.swift           # SFTP read/write/listDirectory
│   │   ├── SSHKeyBookmarkManager.swift  # NSOpenPanel + security-scoped bookmarks para chaves SSH
│   │   └── SSHKeychainManager.swift     # Armazenamento de senhas no macOS Keychain
│   └── SyntaxHighlight/
│       ├── HighlightEngine.swift  # WKWebView com Highlight.js embutido
│       ├── MarkdownRenderer.swift # Renderizador de Markdown
│       ├── HTMLPreview.swift      # Preview HTML ao vivo
│       └── LanguageMap.swift      # Mapeamento extensao -> linguagem
├── UI/
│   ├── TabContainerView.swift     # Container de abas com persistencia
│   ├── EditorView.swift           # View principal, orquestra tudo
│   ├── CodeTextView.swift         # NSTextView customizado (MarkEditTextView)
│   ├── Editor/
│   │   ├── ColumnSelection.swift  # Estado e helpers para selecao retangular
│   │   ├── FoldGutterView.swift   # NSRulerView combinado (numeros + fold + diff + dots)
│   │   ├── DiffGutterIndicator.swift  # Desenho de indicadores de diff
│   │   └── LineNumberGutterView.swift # Gutter standalone (referencia)
│   ├── FindReplace/
│   │   ├── FindReplaceEngine.swift    # Motor de busca e substituicao
│   │   └── FindReplacePanel.swift     # UI do painel de Find/Replace
│   ├── Toolbar/
│   │   ├── ToolbarView.swift      # Toolbar estilo Pages
│   │   ├── FormatControls.swift   # Controles contextuais por tipo
│   │   └── Ribbon/               # Componentes da ribbon toolbar
│   ├── SSH/
│   │   ├── SSHConnectionSheet.swift       # UI de perfis de conexao + formulario + connect
│   │   ├── RemoteFileBrowserSheet.swift   # Navegador SFTP com breadcrumb e filtro
│   │   └── SSHConnectionListView.swift    # Lista de conexoes com status (verde/cinza/vermelho)
│   ├── StatusBar/
│   │   └── StatusBarView.swift    # Cursor, contagem, encoding, lint, word wrap, indicador remoto
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
    ├──▶ FoldingEngine.parse() (regioes dobravies)
    ├──▶ BracketMatcher (par correspondente)
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
              ├──▶ CodeTextView (overlays de erro/warning)
              └──▶ FoldGutterView (dots vermelho/laranja no gutter)
```

```
SSHConnectionSheet (usuario seleciona servidor)
    │
    ▼
SSHConnectionManager.connect() -> SFTPClient
    │
    ▼
RemoteFileBrowserSheet (navega SFTP)
    │
    ▼
RemoteFileReference (profileID + remotePath)
    │
    ▼
TabContainerView.loadRemoteFile()
    │
    ├──▶ RemoteFileIO.read() -> content, encoding
    │
    ▼
DocumentModel (remoteFileRef, content, fileType)
    │
    └──▶ mesmos engines (lint, fold, bracket, highlight)
```

Menus e atalhos de teclado comunicam com `EditorView` via `NotificationCenter`, ja que SwiftUI `Commands` nao tem acesso direto ao estado.

---

## Layout da Interface

```
┌──────────────────────────────────────────────────────────────────┐
│ [Tab 1] [Tab 2] [🌐 Tab 3]                                 [+] │
├──────────────────────────────────────────────────────────────────┤
│ Toolbar Primaria: [Tipo] NomeArquivo •     [Preview][Lint]      │
│ Toolbar Secundaria: [Controles Contextuais]          [Converter]│
├──────────────────────────────────────────────────────────────────┤
│ [Find: ________] [Replace: ________] [◀ ▶] [Replace] [All]     │ ← Find/Replace (toggle)
├────┬─────────────────────────────────┬──────────────────────────┤
│ G  │                                 │                          │
│ u  │        CodeTextView             │    Preview (opcional)    │
│ t  │      (editor principal)         │   Markdown / HTML /     │
│ t  │                                 │   Syntax Highlight      │
│ e  │  ░░ linhas com erro/warning     │                          │
│ r  │  ◆ bookmark                     │                          │
│    │  ▼ fold region                  │                          │
│ 56 │  █ diff indicator               │                          │
│ pt │                                 │                          │
├────┴─────────────────────────────────┴──────────────────────────┤
│ ⚠ Erro na linha 42: Unexpected token   [JSON]                  │ ← Issue bar contextual
├─────────────────────────────────────────────────────────────────┤
│ ⌶ Ln 42, Col 8 │ 156 lines │ JSON │ 🌐 Remote │ Wrap │ UTF-8 │ ✓│ ← Status bar
└─────────────────────────────────────────────────────────────────┘
                                                    ┌─────────────┐
                                                    │ Lint Panel  │
                                                    │ [All][E][W] │
                                                    │ ✕ L12 ...   │
                                                    │ ⚠ L42 ...   │
                                                    │ ℹ L98 ...   │
                                                    └─────────────┘
```

---

## Code Folding

O editor detecta e permite colapsar regioes de codigo:

| Tipo | Detectado em | Exemplo |
|---|---|---|
| Chaves `{}` | Todos os formatos | Funcoes, objetos JSON, blocos CSS |
| Colchetes `[]` | Todos os formatos | Arrays JSON, listas |
| Headers Markdown | `.md` | `# Section` ate o proximo header de mesmo nivel ou superior |

- Triangulo ▼ (expandido) ou ▶ (colapsado) no gutter
- Click no triangulo para toggle
- Layout via `NSLayoutManagerDelegate` — texto original intacto (undo/find funcionam normalmente)
- Busca auto-expande regioes colapsadas que contem o match

---

## Column/Block Selection

**Option+Drag** ativa selecao retangular:

- Seleciona o mesmo intervalo de colunas em multiplas linhas
- `setSelectedRanges` com multiplos ranges para highlight nativo
- Copy (Cmd+C) gera texto em bloco retangular
- Status bar mostra "Sel: Ln X-Y, Col X-Y" durante a selecao
- Calculo baseado em largura fixa de caractere monoespacado (SF Mono 13pt)

---

## Bracket Matching

Quando o cursor esta adjacente a um bracket, o editor destaca visualmente o par correspondente:

| Caractere | Par |
|---|---|
| `{` `}` | Chaves |
| `[` `]` | Colchetes |
| `(` `)` | Parenteses |
| `<` `>` | Angle brackets |
| `"` `"` | Aspas duplas |
| `'` `'` | Aspas simples |
| `` ` `` `` ` `` | Backticks |

- Busca com depth tracking para brackets (respeita nesting)
- Busca com escape awareness para aspas (ignora `\"`, `\'`)
- Overlay com `controlAccentColor` (respeita preferencia de cor do usuario)

---

## Diff Integrado

**Cmd+D** compara o conteudo atual com a versao salva no disco:

- Algoritmo LCS (Longest Common Subsequence) linha-a-linha
- Indicadores coloridos no gutter esquerdo:
  - **Verde**: linhas adicionadas
  - **Azul**: linhas modificadas
  - **Vermelho**: linhas removidas
- Cores semanticas do sistema que adaptam automaticamente a light/dark mode

---

## Line Bookmarks

Marque linhas para navegacao rapida:

| Acao | Atalho |
|---|---|
| Toggle bookmark | `Cmd+F2` |
| Proximo bookmark | `F2` |
| Bookmark anterior | `Shift+F2` |

- Diamante colorido no gutter (usa `controlAccentColor` do sistema)
- Navegacao com wrap-around (do ultimo volta ao primeiro)
- Bookmarks ajustam posicao automaticamente ao editar o texto

---

## Session Restore

Ao fechar e reabrir o app, o estado completo e restaurado:

- Todas as abas abertas — locais (paths via security-scoped bookmarks) e remotas (reconexao automatica)
- Aba ativa selecionada
- Estado por aba: preview aberto, painel de lint, word wrap

Dados persistidos em `UserDefaults`:
- `openTabs` — array de paths (locais) ou placeholders `remote://` (remotos)
- `activeTabIndex` — indice da aba ativa
- `tabSessionStates` — array de dicionarios com estado de cada aba (inclui `remoteFileRef` encoded)

Abas remotas restauram automaticamente: o app decodifica o `RemoteFileReference`, reconecta via `SSHConnectionManager` (usando senha do Keychain) e recarrega o conteudo.

---

## Edicao Remota via SSH

O editor permite abrir, editar e salvar arquivos em servidores remotos via SFTP, usando a biblioteca [Citadel](https://github.com/orlandos-nl/Citadel) (pure Swift, SwiftNIO).

### Conexao

- **Perfis de conexao** — salve multiplos servidores com nome, host, porta, usuario, metodo de autenticacao e path padrao
- **Autenticacao por senha** — senha armazenada no macOS Keychain (`Security.framework`)
- **Autenticacao por chave privada** — Ed25519 e RSA; usuario seleciona o arquivo via NSOpenPanel, acesso persistido com security-scoped bookmarks
- **Reconexao automatica** — ao salvar ou restaurar sessao, reconecta transparentemente usando credenciais armazenadas
- **Status de conexao** — indicadores visuais: verde (conectado), amarelo (conectando), cinza (desconectado), vermelho (erro)

### Navegacao Remota

- **File browser SFTP** — lista diretorios com icones por tipo, tamanho formatado, ordenacao (diretorios primeiro, alfabetica)
- **Breadcrumb path bar** — navegacao clicavel por cada componente do path
- **Filtro por nome** — busca rapida na listagem atual
- **Double-click** — navega em diretorios, abre arquivos no editor

### Integracao com o Editor

- Abas remotas mostram icone `network` (azul) em vez do icone de tipo de arquivo
- Titulo da janela mostra "arquivo — NomeDoServidor" para abas remotas
- Status bar mostra indicador "Remote" apos o tipo de arquivo
- **Cmd+S** salva diretamente no servidor via SFTP
- Erro de save remoto mostra alert com opcoes: Retry / Save Locally / Cancel
- Linting, syntax highlighting, code folding e todas as features funcionam normalmente

### Seguranca

| Item | Armazenamento | Metodo |
|---|---|---|
| Senhas SSH | macOS Keychain | `SecItemAdd`/`SecItemCopyMatching` com service `com.andrema2.MarkEdit.ssh` |
| Chaves SSH | Security-scoped bookmark | NSOpenPanel -> `bookmarkData(options: .withSecurityScope)` |
| Perfis de conexao | UserDefaults (JSON) | Sem dados sensiveis — senha no Keychain, chave como bookmark |

### Fluxo: Abrir Arquivo Remoto

```
Menu "Open Remote..." (Cmd+Shift+O)
  -> SSHConnectionSheet (seleciona/cria perfil, conecta)
  -> RemoteFileBrowserSheet (navega SFTP)
  -> Seleciona arquivo -> RemoteFileReference
  -> tabStore.openRemoteFile(ref) -> TabItem
  -> loadRemoteFile(ref, tab):
      RemoteFileIO.read -> content, encoding
      document.remoteFileRef = ref
      document.fileURL = nil
      document.fileType = .from(extension)
      lintEngine.run()
      persistOpenTabs()
```

### Fluxo: Salvar Arquivo Remoto

```
Cmd+S -> saveActiveTab()
  -> document.isRemote ? saveRemoteTab() : local save
  -> RemoteFileIO.write(content, ref, encoding)
  -> document.markClean()
  -> Erro: NSAlert com Retry / Save Locally / Cancel
```

### Error Handling

| Situacao | Comportamento |
|---|---|
| Conexao falha | Alert com mensagem de erro, opcao de retry |
| Conexao cai durante edicao | Tab fica dirty, retry automatico no save |
| Save falha | NSAlert: Retry / Save Locally / Cancel |
| Chave SSH inaccessivel (stale bookmark) | Alert -> re-selecionar via NSOpenPanel |
| Senha incorreta | Re-prompt no formulario de conexao |

---

## Fluxos Principais

### Abrir Arquivo Local

Quatro caminhos convergem para abrir um arquivo local:

1. **Menu (Cmd+O)** -> `FileIO.open()` -> NSOpenPanel -> callback
2. **Finder (duplo clique / arrastar no Dock)** -> `AppDelegate.application(_:open:)` -> `FileOpenRequest`
3. **Drag & drop na janela** -> `onDrop(of: .fileURL)` -> `NSItemProvider.loadItem`
4. **Session restore** -> `AppDelegate` decodifica paths salvos -> `FileOpenRequest`

Ao abrir: le conteudo + detecta encoding -> define FileType pela extensao -> salva bookmark -> dispara lint -> parse fold regions -> atualiza titulo da janela.

### Abrir Arquivo Remoto

1. **Menu (Cmd+Shift+O)** -> post `.openRemoteDocument` -> `SSHConnectionSheet`
2. Seleciona/cria perfil de conexao -> `SSHConnectionManager.connect()` -> `SFTPClient`
3. `RemoteFileBrowserSheet` navega diretorios via SFTP
4. Double-click em arquivo -> cria `RemoteFileReference` -> `tabStore.openRemoteFile(ref)`
5. `loadRemoteFile()`: `RemoteFileIO.read()` -> preenche document (content, encoding, fileType, remoteFileRef) -> lint -> persist
6. **Session restore** -> `AppDelegate` detecta `remoteFileRef` no estado -> post `.openRemoteFile` -> reconecta automaticamente

### Salvar Arquivo

- **Cmd+S (local)**: salva no URL atual (ou cai no Save As se nao tiver URL)
- **Cmd+S (remoto)**: `RemoteFileIO.write()` via SFTP -> markClean; falha mostra alert (Retry / Save Locally / Cancel)
- **Cmd+Shift+S**: NSSavePanel -> novo URL -> atualiza FileType -> salva bookmark

### Conversao de Formato

`ToolbarView` -> menu "Converter para..." -> `FormatConverter.convert()` -> atualiza content e FileType -> proximo Save grava no novo formato.

| De | Para | Metodo |
|---|---|---|
| JSON | YAML | JSONSerialization -> serializador YAML recursivo |
| YAML | JSON | Parser linha-a-linha -> JSONSerialization |
| Markdown | Plain | 10 passes de regex (strip headers, bold, links, etc.) |
| Plain | Markdown | Identidade (texto puro e Markdown valido) |

### Linting em Tempo Real

1. Usuario edita -> `document.content` muda
2. `LintEngine.run()` cancela task anterior, lanca nova
3. Linter adequado ao FileType roda (async)
4. Issues publicadas -> UI reage:
   - **CodeTextView**: overlay vermelho (erro) ou laranja (warning) nas linhas
   - **StatusBarView**: mostra issue quando cursor esta na linha
   - **LintPanel**: lista completa com filtros (All/Errors/Warnings/Info)
   - **FoldGutterView**: dots coloridos no gutter ao lado do numero da linha
   - Clicar numa issue -> editor navega ate a linha com flash highlight

---

## Atalhos de Teclado

| Acao | Atalho |
|---|---|
| Novo documento | `Cmd+N` |
| Nova aba | `Cmd+T` |
| Fechar aba | `Cmd+W` |
| Proxima aba | `Ctrl+Tab` |
| Aba anterior | `Ctrl+Shift+Tab` |
| Abrir | `Cmd+O` |
| Abrir remoto | `Cmd+Shift+O` |
| Salvar | `Cmd+S` |
| Salvar como | `Cmd+Shift+S` |
| Find | `Cmd+F` |
| Find & Replace | `Cmd+H` |
| Toggle preview | `Cmd+Shift+P` |
| Toggle painel de lint | `Cmd+Shift+L` |
| Diff com disco | `Cmd+D` |
| Toggle bookmark | `Cmd+F2` |
| Proximo bookmark | `F2` |
| Bookmark anterior | `Shift+F2` |
| Apagar linha a partir do cursor | `Cmd+K` |
| Fechar painel de busca | `Esc` |
| Copy/Paste/Undo/Redo | Todos os padroes macOS mantidos |
| Column selection | `Option+Drag` |

---

## Design (Apple HIG)

A interface segue as [Human Interface Guidelines para macOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos):

- **Cores semanticas** — `windowBackgroundColor`, `tertiaryLabelColor`, `controlAccentColor`, `findHighlightColor`, `separatorColor` em vez de cores hardcoded
- **Respeito ao accent color** — bookmarks e bracket matching usam `controlAccentColor`, adaptando-se a preferencia do usuario em System Settings
- **Grid de 8pt** — padding e espacamento seguem multiplos de 8 (6pt vertical na status bar = 24pt total, 16pt entre grupos)
- **SF Symbols** — icones nativos (`character.cursor.ibeam`, `text.wrap`, `xmark.circle.fill`, etc.)
- **Dark/Light mode** — todas as cores adaptam automaticamente via system colors
- **Tipografia consistente** — 11pt system font na status bar, monospaced digits para numeros, medium weight para linha atual
- **Status bar 24pt** — altura minima conforme padrao macOS
- **Tooltips** — `.help()` em controles interativos
- **Encoding menu** — `menuStyle(.borderlessButton)` com checkmark na selecao atual
- **Separadores 1pt** — retina-safe com `separatorColor`

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
| `network.client` | WKWebView (recursos locais) + conexoes SSH/SFTP remotas |

Security-scoped bookmarks garantem que o app pode reabrir arquivos locais e chaves SSH mesmo apos reiniciar. Senhas SSH ficam no macOS Keychain (criptografadas pelo OS).

---

## Testes

**290 testes** cobrindo Core, Engines, Models e SSH:

| Suite | Testes | Cobertura |
|---|---|---|
| DocumentModelTests | 7 | Estado inicial, fileName, fileExtension, updateContent, markClean |
| DocumentModelRemoteTests | 9 | isRemote, fileName/fileExtension com remoteFileRef, prioridade remoto vs local |
| FileTypeTests | 17 | Todos os FileTypes, extensoes, displayName |
| LanguageMapTests | 25 | Todos os 40+ mapeamentos de extensao, case insensitivity, bundledLanguages |
| FormatConverterTests | 21 | canTransform, JSON<->YAML, Markdown->Plain, passthrough |
| JSONLinterTests | 12 | JSON valido/invalido, numeros de linha, extensoes |
| YAMLLinterTests | 11 | Tabs, whitespace, indentacao, chaves duplicadas, document-start |
| JSLinterTests | 15 | console.log, var, debugger, alert, eval, ==, any (TS), multiplos issues |
| CSSLinterTests | 8 | !important, empty rules, inline styles, line numbers, extensoes |
| LintEngineTests | 6 | Estado inicial, clear, run async, contadores |
| LintIssueTests | 5 | Severity ordering, criacao, Identifiable, Hashable |
| FileIOTests | 9 | Read/write UTF-8, encoding, round-trip, unicode |
| ExternalToolTests | 8 | find(), BundledHighlight script tags com dependencias |
| FoldingEngineTests | 17 | Parse braces/brackets/markdown, toggle, foldAll, unfoldAll, hidden ranges, re-parse |
| FoldRegionTests | 8 | Criacao, Kind (braces/brackets/markdownHeader), Identifiable, Equatable |
| BookmarkEngineTests | 16 | Toggle, isBookmarked, next/previous com wrap-around, clearAll, adjustForEdit |
| DiffEngineTests | 11 | Estado inicial, DiffHunk, identico, adicionado, removido, modificado, sem URL |
| BracketMatcherTests | 19 | {}, [], (), <>, "", '', backticks, nested, escaped, unbalanced, mappings |
| ColumnSelectionTests | 10 | State, lineRange, columnRange, Info, ranges simples/single/clamp/vazio |
| SSHConnectionProfileTests | 15 | Defaults (port 22, password), Codable roundtrip, Hashable, saveAll/loadAll, AuthMethod equality |
| RemoteFileReferenceTests | 12 | fileName, fileExtension, displayString, uniqueKey, Codable, Hashable, dotfiles |
| SSHKeychainManagerTests | 10 | Save/load/delete, overwrite, special chars, unicode, empty, isolacao entre perfis |
| TabStoreRemoteTests | 10 | openRemoteFile reuse/dedup, sessionState encode/decode, openTabPaths com remote |

```bash
xcodebuild test -project MarkEdit.xcodeproj -scheme MarkEdit -destination 'platform=macOS'
```

---

## Build

### Requisitos

- macOS 15+
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (para regenerar o .xcodeproj)

### Dependencias (SPM)

| Pacote | Versao | Funcao |
|---|---|---|
| [Citadel](https://github.com/orlandos-nl/Citadel) | 0.7.0+ | SSH/SFTP client (pure Swift, SwiftNIO) |

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
