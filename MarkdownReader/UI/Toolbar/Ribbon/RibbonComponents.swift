import SwiftUI

// MARK: - Ribbon Tab Identifier

enum RibbonTab: Hashable {
    case home
    case insert
    case view
    case fileType
    case convert
}

// MARK: - Ribbon Group

/// A labeled group of ribbon controls with a bottom label and vertical separator.
struct RibbonGroup<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                content()
            }
            .frame(maxHeight: .infinity)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

/// Vertical separator between ribbon groups.
struct RibbonGroupSeparator: View {
    var body: some View {
        Divider()
            .frame(height: 60)
            .padding(.horizontal, 2)
    }
}

// MARK: - Large Button (icon on top, text below)

struct RibbonLargeButton: View {
    let label: String
    let icon: String
    let active: Bool
    let action: () -> Void

    init(_ label: String, icon: String, active: Bool = false, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.active = active
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 28)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
            }
            .frame(minWidth: 48)
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(active ? Color.accentColor.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .foregroundColor(active ? .accentColor : .primary)
        .help(label)
    }
}

// MARK: - Small Button (icon left, text right, single row)

struct RibbonSmallButton: View {
    let label: String
    let icon: String
    let action: () -> Void

    init(_ label: String, icon: String, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .frame(width: 16)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .help(label)
    }
}

// MARK: - Small Icon-Only Button (for font formatting etc.)

struct RibbonSmallIconButton: View {
    let label: String
    let icon: String
    let action: () -> Void

    init(_ label: String, icon: String, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .frame(width: 28, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .help(label)
    }
}

// MARK: - Menu Button (icon + dropdown arrow)

struct RibbonMenuButton<Content: View>: View {
    let label: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .bold))
            }
            .frame(width: 36, height: 24)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help(label)
    }
}

// MARK: - QAT Button (Quick Access Toolbar)

struct QATButton: View {
    let label: String
    let icon: String
    let active: Bool
    let badge: Int
    let action: () -> Void

    init(_ label: String, icon: String, active: Bool = false, badge: Int = 0, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.active = active
        self.badge = badge
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(active ? .accentColor : .secondary)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(active ? .accentColor : .primary)
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 9, weight: .bold))
                        .monospacedDigit()
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.orange.opacity(0.2)))
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(active ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .help(label)
    }
}

// MARK: - QAT Divider

struct QATDivider: View {
    var body: some View {
        Divider()
            .frame(height: 18)
            .padding(.horizontal, 4)
    }
}
