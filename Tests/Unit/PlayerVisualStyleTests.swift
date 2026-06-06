import Foundation
import Testing
@testable import DartBuddy

@Suite("Player visual style", .tags(.unit, .player, .localization, .regression))
struct PlayerVisualStyleTests {
    @Test("Every avatar style maps to a non-empty SF Symbol", arguments: PlayerAvatarStyle.allCases)
    func avatarHasSymbol(style: PlayerAvatarStyle) {
        #expect(!style.symbolName.isEmpty)
    }

    @Test("Avatar SF Symbols are unique across styles")
    func avatarSymbolsAreUnique() {
        let symbols = PlayerAvatarStyle.allCases.map(\.symbolName)
        #expect(Set(symbols).count == symbols.count)
    }

    @Test("Every avatar style has a localized display name", arguments: PlayerAvatarStyle.allCases)
    func avatarHasLocalizedName(style: PlayerAvatarStyle) {
        let name = style.displayName
        #expect(!name.isEmpty)
        // A missing key falls back to the key itself; ensure the string is resolved.
        #expect(name != "players.avatar.\(style.rawValue)")
    }

    @Test("Every color token has a localized display name", arguments: PlayerColorToken.allCases)
    func colorHasLocalizedName(token: PlayerColorToken) {
        let name = token.displayName
        #expect(!name.isEmpty)
        #expect(name != "players.identity.color.\(token.rawValue)")
    }

    @Test("resolved falls back to defaults for unknown raw values")
    func resolvedFallsBack() {
        #expect(PlayerAvatarStyle.resolved(raw: "not-a-style") == .dart)
        #expect(PlayerColorToken.resolved(raw: "not-a-color") == .green)
    }

    @Test("resolved round-trips every known raw value")
    func resolvedRoundTrips() {
        for style in PlayerAvatarStyle.allCases {
            #expect(PlayerAvatarStyle.resolved(raw: style.rawValue) == style)
        }
        for token in PlayerColorToken.allCases {
            #expect(PlayerColorToken.resolved(raw: token.rawValue) == token)
        }
    }
}
