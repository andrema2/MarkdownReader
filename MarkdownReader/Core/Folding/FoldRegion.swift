import Foundation

/// Represents a foldable region in source code.
struct FoldRegion: Identifiable, Equatable {
    let id: UUID
    let startLine: Int
    let endLine: Int
    let kind: Kind
    let nestingLevel: Int

    enum Kind: Equatable {
        case braces       // { ... }
        case brackets     // [ ... ]
        case markdownHeader(level: Int)  // # through ######
    }

    init(startLine: Int, endLine: Int, kind: Kind, nestingLevel: Int = 0) {
        self.id = UUID()
        self.startLine = startLine
        self.endLine = endLine
        self.kind = kind
        self.nestingLevel = nestingLevel
    }
}
