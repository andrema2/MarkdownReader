import XCTest
@testable import MarkEdit

final class LintEngineTests: XCTestCase {

    // MARK: - Initial State

    func testInitialState() {
        let engine = LintEngine()
        XCTAssertTrue(engine.issues.isEmpty)
        XCTAssertFalse(engine.isRunning)
        XCTAssertNil(engine.selectedIssue)
        XCTAssertEqual(engine.errorCount, 0)
        XCTAssertEqual(engine.warningCount, 0)
        XCTAssertEqual(engine.infoCount, 0)
    }

    // MARK: - Clear

    func testClear() {
        let engine = LintEngine()
        engine.clear()
        XCTAssertTrue(engine.issues.isEmpty)
        XCTAssertNil(engine.selectedIssue)
    }

    // MARK: - Run with JSON

    @MainActor
    func testRunWithInvalidJSON() async {
        let engine = LintEngine()
        engine.run(content: "{bad}", fileExtension: "json")
        // Wait for async task
        try? await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertFalse(engine.issues.isEmpty)
        XCTAssertGreaterThan(engine.errorCount, 0)
    }

    @MainActor
    func testRunWithValidJSON() async {
        let engine = LintEngine()
        engine.run(content: "{\"key\": \"value\"}", fileExtension: "json")
        try? await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertTrue(engine.issues.isEmpty)
    }

    // MARK: - Run with unsupported extension

    @MainActor
    func testRunWithUnsupportedExtension() async {
        let engine = LintEngine()
        engine.run(content: "anything", fileExtension: "xyz")
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(engine.issues.isEmpty)
    }

    // MARK: - Counts

    func testCountProperties() {
        let engine = LintEngine()
        // Manually verify count computation
        XCTAssertEqual(engine.errorCount, 0)
        XCTAssertEqual(engine.warningCount, 0)
        XCTAssertEqual(engine.infoCount, 0)
    }
}

// MARK: - LintIssue Tests

final class LintIssueTests: XCTestCase {

    func testSeverityOrdering() {
        XCTAssertTrue(LintIssue.Severity.error < LintIssue.Severity.warning)
        XCTAssertTrue(LintIssue.Severity.warning < LintIssue.Severity.info)
        XCTAssertTrue(LintIssue.Severity.error < LintIssue.Severity.info)
    }

    func testIssueCreation() {
        let issue = LintIssue(line: 10, column: 5, severity: .error, message: "Test error", source: "Test", rule: "test-rule")
        XCTAssertEqual(issue.line, 10)
        XCTAssertEqual(issue.column, 5)
        XCTAssertEqual(issue.severity, .error)
        XCTAssertEqual(issue.message, "Test error")
        XCTAssertEqual(issue.source, "Test")
        XCTAssertEqual(issue.rule, "test-rule")
    }

    func testIssueCreationOptionalDefaults() {
        let issue = LintIssue(line: 1, severity: .info, message: "Info", source: "S")
        XCTAssertNil(issue.column)
        XCTAssertNil(issue.rule)
    }

    func testIssueIdentifiable() {
        let a = LintIssue(line: 1, severity: .error, message: "A", source: "X")
        let b = LintIssue(line: 1, severity: .error, message: "A", source: "X")
        XCTAssertNotEqual(a.id, b.id) // Each gets unique UUID
    }

    func testIssueHashable() {
        let issue = LintIssue(line: 1, severity: .error, message: "A", source: "X")
        var set = Set<LintIssue>()
        set.insert(issue)
        XCTAssertTrue(set.contains(issue))
    }
}
