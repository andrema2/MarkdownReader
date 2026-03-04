import XCTest
@testable import MarkEdit

final class YAMLLinterTests: XCTestCase {
    let linter = YAMLLinter()

    // MARK: - Valid YAML

    func testValidYAMLNoBuiltinIssues() async {
        let yaml = """
        ---
        name: test
        version: 1.0
        """
        let issues = await linter.lint(content: yaml, fileExtension: "yaml")
        // May have yamllint issues if installed, but builtin should be clean
        let builtinIssues = issues.filter { $0.source == "YAML" }
        XCTAssertTrue(builtinIssues.isEmpty)
    }

    // MARK: - Tab Detection

    func testTabsDetected() async {
        let yaml = "name:\tvalue\n"
        let issues = await linter.lint(content: yaml, fileExtension: "yaml")
        let tabIssues = issues.filter { $0.rule == "no-tabs" || $0.message.contains("Tab") }
        XCTAssertFalse(tabIssues.isEmpty, "Should detect tab characters")
        XCTAssertEqual(tabIssues.first?.severity, .error)
    }

    // MARK: - Trailing Whitespace

    func testTrailingWhitespace() async {
        let yaml = "name: value   \nother: ok\n"
        let issues = await linter.lint(content: yaml, fileExtension: "yaml")
        let trailingIssues = issues.filter { $0.message.contains("Trailing") || $0.rule == "trailing-spaces" }
        XCTAssertFalse(trailingIssues.isEmpty, "Should detect trailing whitespace")
    }

    // MARK: - Odd Indentation

    func testOddIndentation() async {
        let yaml = "parent:\n   child: value\n"
        let issues = await linter.lint(content: yaml, fileExtension: "yaml")
        let indentIssues = issues.filter { $0.rule == "indentation" || $0.message.contains("indentation") }
        XCTAssertFalse(indentIssues.isEmpty, "Should detect odd indentation (3 spaces)")
    }

    func testEvenIndentationNoWarning() async {
        let yaml = "parent:\n  child: value\n"
        let issues = await linter.lint(content: yaml, fileExtension: "yaml")
        let indentIssues = issues.filter { $0.rule == "indentation" }
        XCTAssertTrue(indentIssues.isEmpty, "Should not warn about 2-space indentation")
    }

    // MARK: - Duplicate Keys

    func testDuplicateRootKeys() async {
        let yaml = """
        name: first
        version: 1
        name: second
        """
        let issues = await linter.lint(content: yaml, fileExtension: "yaml")
        let dupIssues = issues.filter { $0.message.contains("Duplicate") || $0.rule == "no-duplicate-keys" }
        XCTAssertFalse(dupIssues.isEmpty, "Should detect duplicate root key 'name'")
    }

    func testNoDuplicateKeys() async {
        let yaml = "name: first\nversion: 1\n"
        let issues = await linter.lint(content: yaml, fileExtension: "yaml")
        let dupIssues = issues.filter { $0.message.contains("Duplicate") }
        XCTAssertTrue(dupIssues.isEmpty)
    }

    // MARK: - Document Start

    func testMissingDocumentStart() async {
        let yaml = "name: value\n"
        let issues = await linter.lint(content: yaml, fileExtension: "yaml")
        let startIssues = issues.filter { $0.rule == "document-start" || $0.message.contains("---") }
        XCTAssertFalse(startIssues.isEmpty, "Should suggest document start marker")
    }

    func testHasDocumentStart() async {
        let yaml = "---\nname: value\n"
        let issues = await linter.lint(content: yaml, fileExtension: "yaml")
        let startIssues = issues.filter { $0.source == "YAML" && $0.rule == "document-start" }
        XCTAssertTrue(startIssues.isEmpty, "Should not warn when --- present")
    }

    // MARK: - Supported Extensions

    func testSupportedExtensions() {
        XCTAssertTrue(linter.supportedExtensions.contains("yaml"))
        XCTAssertTrue(linter.supportedExtensions.contains("yml"))
    }

    // MARK: - Comments Ignored

    func testCommentsIgnored() async {
        let yaml = "---\n# This is a comment\nname: value\n"
        let issues = await linter.lint(content: yaml, fileExtension: "yaml")
        let builtinIssues = issues.filter { $0.source == "YAML" }
        XCTAssertTrue(builtinIssues.isEmpty)
    }
}
