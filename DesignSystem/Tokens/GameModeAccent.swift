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
        case .americanCricket: Brand.proBot
        case .englishCricket: Brand.proBot
        case .mickeyMouse, .mulligan: Brand.orange
        case .blindKiller, .followTheLeader, .loop: Brand.red
        case .knockout, .suddenDeath, .fiftyOneByFives: Brand.orange
        case .golf, .football, .grandNational, .hareAndHounds: Brand.amber
        case .fleet: Brand.proBot
        case .prisoner, .scam, .snooker, .ticTacToe: Brand.redAccent
        case .aroundTheClock, .aroundTheClock180, .chaseTheDragon: Brand.green
        case .nineLives, .bobs27, .halveIt: Brand.green
        }
    }

    static func icon(for type: MatchType) -> String {
        switch type {
        case .x01: "target"
        case .cricket: "circle.grid.3x3.fill"
        case .baseball: "baseball.fill"
        case .killer: "bolt.fill"
        case .shanghai: "star.fill"
        case .americanCricket: "circle.grid.3x3"
        case .mickeyMouse: "circle.grid.2x2.fill"
        case .mulligan: "arrow.uturn.backward.circle.fill"
        case .englishCricket: "figure.cricket"
        case .blindKiller: "eye.slash.fill"
        case .knockout: "bolt.horizontal.fill"
        case .suddenDeath: "exclamationmark.triangle.fill"
        case .fiftyOneByFives: "5.circle.fill"
        case .golf: "figure.golf"
        case .football: "soccerball"
        case .fleet: "ferry.fill"
        case .grandNational: "flag.checkered"
        case .hareAndHounds: "hare.fill"
        case .followTheLeader: "arrow.turn.down.right"
        case .loop: "arrow.triangle.2.circlepath"
        case .prisoner: "lock.fill"
        case .scam: "theatermasks.fill"
        case .snooker: "circle.fill"
        case .ticTacToe: "number.square.fill"
        case .aroundTheClock: "clock.fill"
        case .aroundTheClock180: "clock.badge.fill"
        case .chaseTheDragon: "flame.fill"
        case .nineLives: "heart.fill"
        case .bobs27: "scope"
        case .halveIt: "divide.circle.fill"
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

