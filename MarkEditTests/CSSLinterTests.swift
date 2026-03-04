import XCTest
@testable import MarkEdit

final class CSSLinterTests: XCTestCase {
    let linter = CSSLinter()

    // MARK: - Clean CSS

    func testCleanCSSNoIssues() async {
        let css = """
        .container {
          display: flex;
          padding: 16px;
        }
        """
        let issues = await linter.lint(content: css, fileExtension: "css")
        let builtin = issues.filter { $0.source == "CSS" }
        XCTAssertTrue(builtin.isEmpty)
    }

    func testEmptyContentNoIssues() async {
        let issues = await linter.lint(content: "", fileExtension: "css")
        XCTAssertTrue(issues.isEmpty)
    }

    // MARK: - !important

    func testImportantDetected() async {
        let css = ".btn { color: red !important; }\n"
        let issues = await linter.lint(content: css, fileExtension: "css")
        let impIssues = issues.filter { $0.rule == "no-important" }
        XCTAssertFalse(impIssues.isEmpty)
        XCTAssertEqual(impIssues.first?.severity, .warning)
    }

    // MARK: - Empty Rules

    func testEmptyRuleDetected() async {
        let css = ".empty {}\n"
        let issues = await linter.lint(content: css, fileExtension: "css")
        let emptyIssues = issues.filter { $0.rule == "no-empty-rules" }
        XCTAssertFalse(emptyIssues.isEmpty)
    }

    func testEmptyRuleWithSpaceDetected() async {
        let css = ".empty { }\n"
        let issues = await linter.lint(content: css, fileExtension: "css")
        let emptyIssues = issues.filter { $0.rule == "no-empty-rules" }
        XCTAssertFalse(emptyIssues.isEmpty)
    }

    // MARK: - Inline Styles

    func testInlineStyleDetected() async {
        let css = "<div style=\"color: red\"></div>\n"
        let issues = await linter.lint(content: css, fileExtension: "css")
        let inlineIssues = issues.filter { $0.rule == "no-inline-styles" }
        XCTAssertFalse(inlineIssues.isEmpty)
        XCTAssertEqual(inlineIssues.first?.severity, .info)
    }

    // MARK: - Supported Extensions

    func testSupportedExtensions() {
        XCTAssertTrue(linter.supportedExtensions.contains("css"))
        XCTAssertTrue(linter.supportedExtensions.contains("scss"))
        XCTAssertTrue(linter.supportedExtensions.contains("less"))
    }

    // MARK: - Line Numbers

    func testCorrectLineNumber() async {
        let css = """
        .a { display: flex; }
        .b { display: flex; }
        .c { color: red !important; }
        """
        let issues = await linter.lint(content: css, fileExtension: "css")
        let impIssue = issues.first { $0.rule == "no-important" }
        XCTAssertEqual(impIssue?.line, 3)
    }
}
