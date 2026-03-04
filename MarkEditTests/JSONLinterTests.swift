import XCTest
@testable import MarkEdit

final class JSONLinterTests: XCTestCase {
    let linter = JSONLinter()

    // MARK: - Valid JSON

    func testValidObjectNoIssues() async {
        let issues = await linter.lint(content: "{\"key\": \"value\"}", fileExtension: "json")
        XCTAssertTrue(issues.isEmpty)
    }

    func testValidArrayNoIssues() async {
        let issues = await linter.lint(content: "[1, 2, 3]", fileExtension: "json")
        XCTAssertTrue(issues.isEmpty)
    }

    func testValidNestedNoIssues() async {
        let json = """
        {
          "users": [
            {"name": "Alice", "age": 30},
            {"name": "Bob", "age": 25}
          ]
        }
        """
        let issues = await linter.lint(content: json, fileExtension: "json")
        XCTAssertTrue(issues.isEmpty)
    }

    func testEmptyStringNoIssues() async {
        let issues = await linter.lint(content: "", fileExtension: "json")
        XCTAssertTrue(issues.isEmpty)
    }

    func testWhitespaceOnlyNoIssues() async {
        let issues = await linter.lint(content: "   \n\n  ", fileExtension: "json")
        XCTAssertTrue(issues.isEmpty)
    }

    // MARK: - Invalid JSON

    func testInvalidJSONProducesError() async {
        let issues = await linter.lint(content: "{invalid}", fileExtension: "json")
        XCTAssertFalse(issues.isEmpty)
        XCTAssertEqual(issues.first?.severity, .error)
        XCTAssertEqual(issues.first?.source, "JSON")
    }

    func testTrailingCommaAccepted() async {
        // JSONSerialization with .fragmentsAllowed accepts trailing commas
        let json = """
        {"key": "value",}
        """
        let issues = await linter.lint(content: json, fileExtension: "json")
        XCTAssertTrue(issues.isEmpty)
    }

    func testUnclosedBraceError() async {
        let json = """
        {"key": "value"
        """
        let issues = await linter.lint(content: json, fileExtension: "json")
        XCTAssertFalse(issues.isEmpty)
    }

    func testUnclosedStringError() async {
        let json = """
        {"key": "value
        """
        let issues = await linter.lint(content: json, fileExtension: "json")
        XCTAssertFalse(issues.isEmpty)
    }

    func testSingleQuotesError() async {
        let json = "{'key': 'value'}"
        let issues = await linter.lint(content: json, fileExtension: "json")
        XCTAssertFalse(issues.isEmpty)
    }

    // MARK: - Line Number Extraction

    func testErrorHasLineNumber() async {
        let json = """
        {
          "a": 1,
          "b": 2,
          "c": bad
        }
        """
        let issues = await linter.lint(content: json, fileExtension: "json")
        XCTAssertFalse(issues.isEmpty)
        XCTAssertGreaterThan(issues.first!.line, 0)
    }

    // MARK: - Supported Extensions

    func testSupportedExtensions() {
        XCTAssertTrue(linter.supportedExtensions.contains("json"))
    }
}
