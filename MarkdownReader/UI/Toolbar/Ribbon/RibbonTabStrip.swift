import SwiftUI

/// Tab strip displaying Home / Insert / View / FileType / Convert tabs (26pt height).
struct RibbonTabStrip: View {
    @Binding var selectedTab: RibbonTab
    let fileType: DocumentModel.FileType
    let hasConvertTargets: Bool
    let onDoubleClick: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabItem("Home", tab: .home)
            tabItem("Insert", tab: .insert)
            tabItem("View", tab: .view)
            tabItem(fileType.displayName, tab: .fileType)
            if hasConvertTargets {
                tabItem("Convert", tab: .convert)
            }
            Spacer()
        }
        .frame(height: 26)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func tabItem(_ label: String, tab: RibbonTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            Text(label)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .accentColor : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(
                    Group {
                        if isSelected {
                            VStack(spacing: 0) {
                                Spacer()
                                Rectangle()
                                    .fill(Color.accentColor)
                                    .frame(height: 2)
                            }
                        }
                    }
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .onTapGesture(count: 2) {
            onDoubleClick()
        }
        .onTapGesture(count: 1) {
            selectedTab = tab
        }
    }
}
