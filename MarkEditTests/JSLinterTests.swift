import XCTest
@testable import MarkEdit

final class JSLinterTests: XCTestCase {
    let linter = JSLinter()

    // MARK: - Clean Code

    func testCleanCodeNoIssues() async {
        let code = """
        const x = 1;
        let y = 2;
        function add(a, b) { return a + b; }
        """
        let issues = await linter.lint(content: code, fileExtension: "js")
        // Builtin only — no ESLint
        let builtin = issues.filter { $0.source == "JS" }
        XCTAssertTrue(builtin.isEmpty)
    }

    func testEmptyContentNoIssues() async {
        let issues = await linter.lint(content: "", fileExtension: "js")
        XCTAssertTrue(issues.isEmpty)
    }

    // MARK: - console.log

    func testConsoleLogDetected() async {
        let code = "console.log('hello');\n"
        let issues = await linter.lint(content: code, fileExtension: "js")
        let consoleIssues = issues.filter { $0.rule == "no-console" }
        XCTAssertFalse(consoleIssues.isEmpty)
        XCTAssertEqual(consoleIssues.first?.severity, .warning)
    }

    // MARK: - var

    func testVarDetected() async {
        let code = "var x = 1;\n"
        let issues = await linter.lint(content: code, fileExtension: "js")
        let varIssues = issues.filter { $0.rule == "no-var" }
        XCTAssertFalse(varIssues.isEmpty)
        XCTAssertEqual(varIssues.first?.severity, .warning)
    }

    func testLetNotFlagged() async {
        let code = "let x = 1;\n"
        let issues = await linter.lint(content: code, fileExtension: "js")
        let varIssues = issues.filter { $0.rule == "no-var" }
        XCTAssertTrue(varIssues.isEmpty)
    }

    // MARK: - debugger

    func testDebuggerDetected() async {
        let code = "debugger;\n"
        let issues = await linter.lint(content: code, fileExtension: "js")
        let dbgIssues = issues.filter { $0.rule == "no-debugger" }
        XCTAssertFalse(dbgIssues.isEmpty)
        XCTAssertEqual(dbgIssues.first?.severity, .error)
    }

    // MARK: - alert

    func testAlertDetected() async {
        let code = "alert('hello');\n"
        let issues = await linter.lint(content: code, fileExtension: "js")
        let alertIssues = issues.filter { $0.rule == "no-alert" }
        XCTAssertFalse(alertIssues.isEmpty)
        XCTAssertEqual(alertIssues.first?.severity, .warning)
    }

    // MARK: - eval

    func testEvalDetected() async {
        let code = "eval('code');\n"
        let issues = await linter.lint(content: code, fileExtension: "js")
        let evalIssues = issues.filter { $0.rule == "no-eval" }
        XCTAssertFalse(evalIssues.isEmpty)
        XCTAssertEqual(evalIssues.first?.severity, .error)
    }

    // MARK: - == vs ===

    func testDoubleEqualsDetected() async {
        let code = "if (x == y) {}\n"
        let issues = await linter.lint(content: code, fileExtension: "js")
        let eqIssues = issues.filter { $0.rule == "eqeqeq" }
        XCTAssertFalse(eqIssues.isEmpty)
        XCTAssertEqual(eqIssues.first?.severity, .warning)
    }

    func testTripleEqualsNotFlagged() async {
        let code = "if (x === y) {}\n"
        let issues = await linter.lint(content: code, fileExtension: "js")
        let eqIssues = issues.filter { $0.rule == "eqeqeq" }
        XCTAssertTrue(eqIssues.isEmpty)
    }

    // MARK: - TypeScript: any type

    func testAnyTypeDetectedInTS() async {
        let code = "const x: any = 1;\n"
        let issues = await linter.lint(content: code, fileExtension: "ts")
        let anyIssues = issues.filter { $0.rule == "no-explicit-any" }
        XCTAssertFalse(anyIssues.isEmpty)
        XCTAssertEqual(anyIssues.first?.source, "TS")
    }

    func testAnyTypeNotFlaggedInJS() async {
        let code = "const x: any = 1;\n"
        let issues = await linter.lint(content: code, fileExtension: "js")
        let anyIssues = issues.filter { $0.rule == "no-explicit-any" }
        XCTAssertTrue(anyIssues.isEmpty)
    }

    // MARK: - Line Numbers

    func testCorrectLineNumbers() async {
        let code = """
        const a = 1;
        const b = 2;
        console.log(a);
        const c = 3;
        """
        let issues = await linter.lint(content: code, fileExtension: "js")
        let consoleIssue = issues.first { $0.rule == "no-console" }
        XCTAssertEqual(consoleIssue?.line, 3)
    }

    // MARK: - Multiple Issues

    func testMultipleIssuesDetected() async {
        let code = """
        var x = 1;
        console.log(x);
        eval('bad');
        debugger;
        """
        let issues = await linter.lint(content: code, fileExtension: "js")
        let builtin = issues.filter { $0.source == "JS" }
        XCTAssertGreaterThanOrEqual(builtin.count, 4) // var, console.log, eval, debugger
    }

    // MARK: - Supported Extensions

    func testSupportedExtensions() {
        XCTAssertTrue(linter.supportedExtensions.contains("js"))
        XCTAssertTrue(linter.supportedExtensions.contains("ts"))
        XCTAssertTrue(linter.supportedExtensions.contains("jsx"))
        XCTAssertTrue(linter.supportedExtensions.contains("tsx"))
    }
}
