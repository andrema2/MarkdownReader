import XCTest
@testable import MarkEdit

final class DocumentModelTests: XCTestCase {

    // MARK: - Initial State

    func testInitialState() {
        let doc = DocumentModel()
        XCTAssertEqual(doc.content, "")
        XCTAssertNil(doc.fileURL)
        XCTAssertFalse(doc.isDirty)
        XCTAssertEqual(doc.encoding, .utf8)
        XCTAssertEqual(doc.fileType, .markdown)
        XCTAssertEqual(doc.cursorLine, 1)
        XCTAssertEqual(doc.cursorColumn, 1)
        XCTAssertNil(doc.currentLineIssue)
    }

    // MARK: - File Name

    func testFileNameWithoutURL() {
        let doc = DocumentModel()
        XCTAssertEqual(doc.fileName, "Untitled")
    }

    func testFileNameWithURL() {
        let doc = DocumentModel()
        doc.fileURL = URL(fileURLWithPath: "/tmp/test.json")
        XCTAssertEqual(doc.fileName, "test.json")
    }

    // MARK: - File Extension

    func testFileExtensionWithoutURL() {
        let doc = DocumentModel()
        XCTAssertEqual(doc.fileExtension, "md")
    }

    func testFileExtensionWithURL() {
        let doc = DocumentModel()
        doc.fileURL = URL(fileURLWithPath: "/tmp/config.yaml")
        XCTAssertEqual(doc.fileExtension, "yaml")
    }

    // MARK: - Update Content

    func testUpdateContentSetsDirty() {
        let doc = DocumentModel()
        XCTAssertFalse(doc.isDirty)
        doc.updateContent("hello")
        XCTAssertEqual(doc.content, "hello")
        XCTAssertTrue(doc.isDirty)
    }

    func testMarkClean() {
        let doc = DocumentModel()
        doc.updateContent("hello")
        XCTAssertTrue(doc.isDirty)
        doc.markClean()
        XCTAssertFalse(doc.isDirty)
    }
}

// MARK: - FileType Tests

final class FileTypeTests: XCTestCase {

    typealias FT = DocumentModel.FileType

    // MARK: - from(extension:)

    func testMarkdownExtensions() {
        XCTAssertEqual(FT.from(extension: "md"), .markdown)
        XCTAssertEqual(FT.from(extension: "markdown"), .markdown)
        XCTAssertEqual(FT.from(extension: "MD"), .markdown)
    }

    func testJSONExtensions() {
        XCTAssertEqual(FT.from(extension: "json"), .json)
        XCTAssertEqual(FT.from(extension: "jsonl"), .json)
    }

    func testYAMLExtensions() {
        XCTAssertEqual(FT.from(extension: "yaml"), .yaml)
        XCTAssertEqual(FT.from(extension: "yml"), .yaml)
    }

    func testJavaScriptExtensions() {
        XCTAssertEqual(FT.from(extension: "js"), .javascript)
        XCTAssertEqual(FT.from(extension: "jsx"), .javascript)
        XCTAssertEqual(FT.from(extension: "mjs"), .javascript)
        XCTAssertEqual(FT.from(extension: "cjs"), .javascript)
    }

    func testTypeScriptExtensions() {
        XCTAssertEqual(FT.from(extension: "ts"), .typescript)
        XCTAssertEqual(FT.from(extension: "tsx"), .typescript)
        XCTAssertEqual(FT.from(extension: "mts"), .typescript)
        XCTAssertEqual(FT.from(extension: "cts"), .typescript)
    }

    func testCSSExtensions() {
        XCTAssertEqual(FT.from(extension: "css"), .css)
        XCTAssertEqual(FT.from(extension: "scss"), .css)
        XCTAssertEqual(FT.from(extension: "less"), .css)
    }

    func testPlainTextFallback() {
        XCTAssertEqual(FT.from(extension: "txt"), .plain)
        XCTAssertEqual(FT.from(extension: "log"), .plain)
        XCTAssertEqual(FT.from(extension: "unknown"), .plain)
        XCTAssertEqual(FT.from(extension: ""), .plain)
    }

    // MARK: - Display Name

    func testDisplayNames() {
        XCTAssertEqual(FT.markdown.displayName, "Markdown")
        XCTAssertEqual(FT.json.displayName, "JSON")
        XCTAssertEqual(FT.yaml.displayName, "YAML")
        XCTAssertEqual(FT.javascript.displayName, "JavaScript")
        XCTAssertEqual(FT.typescript.displayName, "TypeScript")
        XCTAssertEqual(FT.css.displayName, "CSS")
        XCTAssertEqual(FT.plain.displayName, "Plain Text")
    }

    // MARK: - Icons

    func testIconsNotEmpty() {
        for type in FT.allCases {
            XCTAssertFalse(type.icon.isEmpty, "\(type) has empty icon")
        }
    }

    // MARK: - Primary Extension

    func testPrimaryExtensions() {
        XCTAssertEqual(FT.markdown.primaryExtension, "md")
        XCTAssertEqual(FT.json.primaryExtension, "json")
        XCTAssertEqual(FT.yaml.primaryExtension, "yaml")
        XCTAssertEqual(FT.javascript.primaryExtension, "js")
        XCTAssertEqual(FT.typescript.primaryExtension, "ts")
        XCTAssertEqual(FT.css.primaryExtension, "css")
        XCTAssertEqual(FT.plain.primaryExtension, "txt")
    }

    // MARK: - Convertible Targets

    func testMarkdownConvertibleTargets() {
        XCTAssertTrue(FT.markdown.convertibleTargets.contains(.plain))
    }

    func testJSONConvertibleTargets() {
        XCTAssertTrue(FT.json.convertibleTargets.contains(.yaml))
    }

    func testYAMLConvertibleTargets() {
        XCTAssertTrue(FT.yaml.convertibleTargets.contains(.json))
    }

    func testPlainConvertibleTargets() {
        XCTAssertTrue(FT.plain.convertibleTargets.contains(.markdown))
    }

    func testJSHasNoConvertibleTargets() {
        XCTAssertTrue(FT.javascript.convertibleTargets.isEmpty)
        XCTAssertTrue(FT.typescript.convertibleTargets.isEmpty)
        XCTAssertTrue(FT.css.convertibleTargets.isEmpty)
    }

    // MARK: - CaseIterable & Identifiable

    func testAllCasesCount() {
        XCTAssertEqual(FT.allCases.count, 7)
    }

    func testIdentifiable() {
        for type in FT.allCases {
            XCTAssertEqual(type.id, type.rawValue)
        }
    }
}
