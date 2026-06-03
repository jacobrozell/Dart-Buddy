import SwiftUI

/// Layout rhythm and semantic colors for **native** surfaces (Settings light theme,
/// migration recovery footnotes). Scoreboard screens use `Brand` for colors — see `DesignSystem/README.md`.
enum DS {
    enum Spacing {
        static let s1: CGFloat = 4
        static let s2: CGFloat = 8
        static let s3: CGFloat = 12
        static let s4: CGFloat = 16
        static let s5: CGFloat = 20
        static let s6: CGFloat = 24
    }

    enum Radius {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }

    enum ColorRole {
        static let backgroundPrimary = Color(.systemBackground)
        static let backgroundSecondary = Color(.secondarySystemBackground)
        static let textPrimary = Color.primary
        static let textSecondary = Color.primary.opacity(0.72)
        static let success = Color.green
        static let warning = Color.orange
        static let danger = Color.red
        static let info = Color.blue
    }
}
