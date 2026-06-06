import SwiftUI
import UIKit

/// Brand palette for the scoreboard UI. Surfaces and text adapt to light/dark appearance;
/// accent colors stay consistent for gameplay recognition.
enum Brand {
    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    static let background = dynamic(
        light: UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1),
        dark: UIColor(red: 0.04, green: 0.04, blue: 0.05, alpha: 1)
    )
    static let card = dynamic(
        light: UIColor(red: 1, green: 1, blue: 1, alpha: 1),
        dark: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
    )
    static let cardElevated = dynamic(
        light: UIColor(red: 0.92, green: 0.92, blue: 0.94, alpha: 1),
        dark: UIColor(red: 0.16, green: 0.16, blue: 0.17, alpha: 1)
    )
    static let dartBox = dynamic(
        light: UIColor(red: 0.80, green: 0.80, blue: 0.82, alpha: 1),
        dark: UIColor(red: 0.02, green: 0.02, blue: 0.02, alpha: 1)
    )

    static let green = Color(red: 0.20, green: 0.68, blue: 0.32)
    static let red = Color(red: 0.90, green: 0.28, blue: 0.24)
    /// Deeper red used only as a **solid fill behind white text** (primary CTA, error
    /// banner). Meets WCAG 2.1 AA 4.5:1 with `textOnAccent`; `red` itself is reserved for
    /// foreground/tint accents where it must also stay legible as red text on dark surfaces.
    static let redAccent = Color(red: 0.84, green: 0.20, blue: 0.18)
    static let amber = Color(red: 0.96, green: 0.70, blue: 0.12)
    static let orange = Color(red: 0.93, green: 0.45, blue: 0.13)
    static let proBot = Color(red: 0.62, green: 0.38, blue: 0.98)

    static let key = dynamic(
        light: UIColor(red: 0.90, green: 0.90, blue: 0.92, alpha: 1),
        dark: UIColor(red: 0.27, green: 0.27, blue: 0.29, alpha: 1)
    )

    static let textPrimary = dynamic(
        light: UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1),
        dark: UIColor.white
    )
    static let textSecondary = dynamic(
        light: UIColor(red: 0.35, green: 0.35, blue: 0.38, alpha: 1),
        dark: UIColor(white: 1, alpha: 0.55)
    )

    /// Disabled primary actions (START, Continue) on `cardElevated` fills.
    /// `textSecondary` on elevated surfaces falls below WCAG AA 4.5:1 in dark mode.
    static let textDisabled = dynamic(
        light: UIColor(red: 0.28, green: 0.28, blue: 0.30, alpha: 1),
        dark: UIColor(white: 0.72, alpha: 1)
    )

    /// Secondary body copy on `card` surfaces (rules cards, list rows).
    static let textBodyOnCard = dynamic(
        light: UIColor(red: 0.35, green: 0.35, blue: 0.38, alpha: 1),
        dark: UIColor(white: 0.75, alpha: 1)
    )

    /// Foreground on saturated accent fills (primary CTA, selected chips, error banner).
    static let textOnAccent = Color.white

    /// Fixed dark ink for labels that sit on **bright** brand fills (amber/green/orange pad
    /// keys, ENTER, selected setup chips). Unlike `textPrimary` it does **not** flip to white
    /// in dark mode, where white-on-bright fails WCAG AA. Light mode is unchanged.
    static let inkOnBright = Color(red: 0.08, green: 0.08, blue: 0.10)
}
