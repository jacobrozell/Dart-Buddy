import SwiftUI

/// Brand palette tuned to match the dark "Dart Scoreboard" reference look:
/// near-black surfaces, a vivid green accent, and a red primary action.
enum Brand {
    static let background = Color(red: 0.04, green: 0.04, blue: 0.05)
    static let card = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let cardElevated = Color(red: 0.16, green: 0.16, blue: 0.17)
    static let dartBox = Color(red: 0.02, green: 0.02, blue: 0.02)

    static let green = Color(red: 0.26, green: 0.80, blue: 0.40)
    static let red = Color(red: 0.90, green: 0.28, blue: 0.24)
    static let amber = Color(red: 0.96, green: 0.70, blue: 0.12)
    static let orange = Color(red: 0.93, green: 0.45, blue: 0.13)

    static let key = Color(red: 0.27, green: 0.27, blue: 0.29)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
}
