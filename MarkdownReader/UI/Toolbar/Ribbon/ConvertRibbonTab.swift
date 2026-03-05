import SwiftUI

/// Convert tab — each conversion target as a large button.
struct ConvertRibbonTab: View {
    @ObservedObject var document: DocumentModel

    var body: some View {
        let targets = document.fileType.convertibleTargets
        if targets.isEmpty {
            RibbonGroup(label: "Convert") {
                Text("No conversions available")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        } else {
            RibbonGroup(label: "Convert To") {
                ForEach(targets) { target in
                    RibbonLargeButton(target.displayName, icon: target.icon) {
                        convertDocument(to: target)
                    }
                }
            }
        }
    }

    private func convertDocument(to target: DocumentModel.FileType) {
        let source = document.fileType
        if let converted = FormatConverter.convert(document.content, from: source, to: target) {
            document.updateContent(converted)
        }
        document.fileType = target

        if let url = document.fileURL {
            let newURL = url.deletingPathExtension().appendingPathExtension(target.primaryExtension)
            document.fileURL = newURL
        }
    }
}
