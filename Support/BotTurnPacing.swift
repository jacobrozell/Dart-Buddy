import Foundation

/// Delays between bot dart reveals and submit, controlled by Settings feedback toggles.
enum BotTurnPacing {
    static let staggeredDartNanoseconds: UInt64 = 650_000_000
    static let fastDartNanoseconds: UInt64 = 220_000_000
    static let staggeredSubmitNanoseconds: UInt64 = 350_000_000
    static let fastSubmitNanoseconds: UInt64 = 180_000_000

    /// Pause that lets the Cricket closure banner register before returning to the ready state.
    static let cricketClosureTransitionNanoseconds: UInt64 = 550_000_000

    static func dartDelayNanoseconds(staggerEnabled: Bool) -> UInt64 {
        staggerEnabled ? staggeredDartNanoseconds : fastDartNanoseconds
    }

    static func submitDelayNanoseconds(staggerEnabled: Bool) -> UInt64 {
        staggerEnabled ? staggeredSubmitNanoseconds : fastSubmitNanoseconds
    }
}
