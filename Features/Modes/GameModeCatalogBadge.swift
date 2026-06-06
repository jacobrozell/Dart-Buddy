import SwiftUI

/// Catalog-keyed badge for unreleased modes and the Modes tab.
struct GameModeCatalogBadge: View {
    let entry: GameModeCatalogEntry
    var size: CGFloat = 28

    var body: some View {
        Image(systemName: entry.iconSystemName)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(entry.accentColor)
            .frame(width: size, height: size)
            .background(entry.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: DS.Radius.xs))
            .accessibilityHidden(true)
    }
}
