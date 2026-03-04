import XCTest
@testable import MarkEdit

final class LanguageMapTests: XCTestCase {

    // MARK: - Web Languages

    func testJavaScript() {
        XCTAssertEqual(LanguageMap.language(for: "js"), "javascript")
        XCTAssertEqual(LanguageMap.language(for: "mjs"), "javascript")
        XCTAssertEqual(LanguageMap.language(for: "cjs"), "javascript")
    }

    func testTypeScript() {
        XCTAssertEqual(LanguageMap.language(for: "ts"), "typescript")
        XCTAssertEqual(LanguageMap.language(for: "mts"), "typescript")
        XCTAssertEqual(LanguageMap.language(for: "cts"), "typescript")
    }

    func testJSON() {
        XCTAssertEqual(LanguageMap.language(for: "json"), "json")
        XCTAssertEqual(LanguageMap.language(for: "jsonl"), "json")
    }

    func testCSS() {
        XCTAssertEqual(LanguageMap.language(for: "css"), "css")
    }

    func testHTML() {
        XCTAssertEqual(LanguageMap.language(for: "html"), "xml")
        XCTAssertEqual(LanguageMap.language(for: "htm"), "xml")
        XCTAssertEqual(LanguageMap.language(for: "xml"), "xml")
        XCTAssertEqual(LanguageMap.language(for: "svg"), "xml")
    }

    // MARK: - Markup / Config

    func testMarkdown() {
        XCTAssertEqual(LanguageMap.language(for: "md"), "markdown")
        XCTAssertEqual(LanguageMap.language(for: "markdown"), "markdown")
    }

    func testYAML() {
        XCTAssertEqual(LanguageMap.language(for: "yaml"), "yaml")
        XCTAssertEqual(LanguageMap.language(for: "yml"), "yaml")
    }

    func testINI() {
        XCTAssertEqual(LanguageMap.language(for: "ini"), "ini")
        XCTAssertEqual(LanguageMap.language(for: "cfg"), "ini")
        XCTAssertEqual(LanguageMap.language(for: "conf"), "ini")
        XCTAssertEqual(LanguageMap.language(for: "toml"), "ini")
    }

    // MARK: - Systems Languages

    func testSwift() {
        XCTAssertEqual(LanguageMap.language(for: "swift"), "swift")
    }

    func testC() {
        XCTAssertEqual(LanguageMap.language(for: "c"), "c")
        XCTAssertEqual(LanguageMap.language(for: "h"), "c")
    }

    func testCPP() {
        XCTAssertEqual(LanguageMap.language(for: "cpp"), "cpp")
        XCTAssertEqual(LanguageMap.language(for: "cc"), "cpp")
        XCTAssertEqual(LanguageMap.language(for: "hpp"), "cpp")
    }

    func testGo() {
        XCTAssertEqual(LanguageMap.language(for: "go"), "go")
    }

    func testRust() {
        XCTAssertEqual(LanguageMap.language(for: "rs"), "rust")
    }

    func testJava() {
        XCTAssertEqual(LanguageMap.language(for: "java"), "java")
    }

    func testKotlin() {
        XCTAssertEqual(LanguageMap.language(for: "kt"), "kotlin")
        XCTAssertEqual(LanguageMap.language(for: "kts"), "kotlin")
    }

    // MARK: - Scripting

    func testPython() {
        XCTAssertEqual(LanguageMap.language(for: "py"), "python")
        XCTAssertEqual(LanguageMap.language(for: "pyw"), "python")
    }

    func testRuby() {
        XCTAssertEqual(LanguageMap.language(for: "rb"), "ruby")
    }

    func testBash() {
        XCTAssertEqual(LanguageMap.language(for: "sh"), "bash")
        XCTAssertEqual(LanguageMap.language(for: "bash"), "bash")
        XCTAssertEqual(LanguageMap.language(for: "zsh"), "bash")
    }

    // MARK: - Data / Ops

    func testSQL() {
        XCTAssertEqual(LanguageMap.language(for: "sql"), "sql")
    }

    func testDockerfile() {
        XCTAssertEqual(LanguageMap.language(for: "dockerfile"), "dockerfile")
    }

    func testMakefile() {
        XCTAssertEqual(LanguageMap.language(for: "makefile"), "makefile")
        XCTAssertEqual(LanguageMap.language(for: "mk"), "makefile")
    }

    // MARK: - Fallback

    func testUnknownReturnPlaintext() {
        XCTAssertEqual(LanguageMap.language(for: "xyz"), "plaintext")
        XCTAssertEqual(LanguageMap.language(for: ""), "plaintext")
        XCTAssertEqual(LanguageMap.language(for: "abc123"), "plaintext")
    }

    // MARK: - Case Insensitivity

    func testCaseInsensitive() {
        XCTAssertEqual(LanguageMap.language(for: "JS"), "javascript")
        XCTAssertEqual(LanguageMap.language(for: "Swift"), "swift")
        XCTAssertEqual(LanguageMap.language(for: "PY"), "python")
    }

    // MARK: - Bundled Languages Set

    func testBundledLanguagesNotEmpty() {
        XCTAssertFalse(LanguageMap.bundledLanguages.isEmpty)
    }

    func testBundledLanguagesContainsCommon() {
        let expected: Set<String> = ["javascript", "typescript", "json", "swift", "python", "bash", "yaml", "css", "go", "rust"]
        for lang in expected {
            XCTAssertTrue(LanguageMap.bundledLanguages.contains(lang), "Missing bundled language: \(lang)")
        }
    }
}
