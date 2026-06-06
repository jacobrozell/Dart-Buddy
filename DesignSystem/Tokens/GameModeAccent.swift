import SwiftUI

/// Per-game-mode visual identity: a stable accent color and SF Symbol for each
/// `MatchType`. As modes multiply (X01, Cricket, Baseball, Killer, Shanghai, …),
/// reusing one accent + glyph per mode lets players parse "which game" at a glance
/// across the mode catalog, history rows, and stats filters.
///
/// Accents are drawn from the existing `Brand` palette so they stay in the brand's
/// color family and inherit its contrast guarantees — this is identity, not status,
/// so it must never be confused with `positive`/`negative`/`warning` roles.
enum GameModeAccent {
    static func color(for type: MatchType) -> Color {
        switch type {
        case .x01: Brand.green
        case .cricket: Brand.proBot
        case .baseball: Brand.orange
        case .killer: Brand.red
        case .shanghai: Brand.amber
        }
    }

    static func icon(for type: MatchType) -> String {
        switch type {
        case .x01: "target"
        case .cricket: "circle.grid.3x3.fill"
        case .baseball: "baseball.fill"
        case .killer: "bolt.fill"
        case .shanghai: "star.fill"
        }
    }

}

/// Small leading badge (mode glyph on a tinted square) used to mark a row or card
/// with its game mode. Decorative — callers own the surrounding accessibility label.
struct GameModeBadge: View {
    let type: MatchType
    var size: CGFloat = 28

    private var accent: Color {
        GameModeAccent.color(for: type)
    }

    var body: some View {
        Image(systemName: GameModeAccent.icon(for: type))
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(accent)
            .frame(width: size, height: size)
            .background(accent.opacity(0.16), in: RoundedRectangle(cornerRadius: DS.Radius.xs))
            .accessibilityHidden(true)
    }
}

