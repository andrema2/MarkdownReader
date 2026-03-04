import XCTest
@testable import MarkEdit

final class ExternalToolTests: XCTestCase {

    // MARK: - Find

    func testFindNonExistentTool() {
        let result = ExternalTool.find("definitelynotarealtool12345")
        XCTAssertNil(result)
    }

    func testFindKnownSystemTool() {
        // /usr/bin/env should exist on all macOS
        // ExternalTool.find checks specific paths, so this might not find it
        // But we verify it doesn't crash
        _ = ExternalTool.find("env")
    }

    // MARK: - BundledHighlight

    func testLanguageScriptTagsForPlaintext() {
        let tags = BundledHighlight.languageScriptTags(for: "plaintext")
        XCTAssertEqual(tags, "")
    }

    func testLanguageScriptTagsForSwift() {
        let tags = BundledHighlight.languageScriptTags(for: "swift")
        XCTAssertTrue(tags.contains("swift.min.js"))
    }

    func testLanguageScriptTagsForCPPIncludesC() {
        let tags = BundledHighlight.languageScriptTags(for: "cpp")
        XCTAssertTrue(tags.contains("c.min.js"))
        XCTAssertTrue(tags.contains("cpp.min.js"))
    }

    func testLanguageScriptTagsForTypeScriptIncludesJS() {
        let tags = BundledHighlight.languageScriptTags(for: "typescript")
        XCTAssertTrue(tags.contains("javascript.min.js"))
        XCTAssertTrue(tags.contains("typescript.min.js"))
    }

    func testLanguageScriptTagsForKotlinIncludesJava() {
        let tags = BundledHighlight.languageScriptTags(for: "kotlin")
        XCTAssertTrue(tags.contains("java.min.js"))
        XCTAssertTrue(tags.contains("kotlin.min.js"))
    }

    func testLanguageScriptTagsForUnknownLanguage() {
        let tags = BundledHighlight.languageScriptTags(for: "brainfuck")
        XCTAssertEqual(tags, "") // Not in bundledLanguages
    }
}
