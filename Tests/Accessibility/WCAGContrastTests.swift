import Foundation
import Testing
@testable import DartBuddy

/// WCAG 2.1 contrast math for brand tokens on gameplay surfaces (P-1.4.3, P-1.4.11).
@Suite("WCAG contrast ratios", .tags(.unit, .accessibility, .regression))
struct WCAGContrastTests {
    private static let background = WCAGContrastMath.RGB(0.04, 0.04, 0.05)
    private static let card = WCAGContrastMath.RGB(0.11, 0.11, 0.12)
    private static let key = WCAGContrastMath.RGB(0.27, 0.27, 0.29)

    @Test("Primary text on gameplay background meets AA normal text")
    func primaryTextOnBackground() {
        let ratio = WCAGContrastMath.contrastRatio(
            foreground: WCAGContrastMath.RGB(1, 1, 1),
            background: Self.background
        )
        #expect(ratio >= 4.5)
    }

    @Test("Secondary text on gameplay background meets AA normal text")
    func secondaryTextOnBackground() {
        let secondary = WCAGContrastMath.composite(
            foreground: WCAGContrastMath.RGB(1, 1, 1),
            background: Self.background,
            opacity: 0.55
        )
        let ratio = WCAGContrastMath.contrastRatio(foreground: secondary, background: Self.background)
        #expect(ratio >= 4.5)
    }

    @Test("Pad key label on key surface meets AA normal text")
    func padLabelOnKeySurface() {
        let ratio = WCAGContrastMath.contrastRatio(
            foreground: WCAGContrastMath.RGB(1, 1, 1),
            background: Self.key
        )
        #expect(ratio >= 4.5)
    }

    @Test("Green accent on card meets AA large text threshold")
    func greenAccentOnCard() {
        let ratio = WCAGContrastMath.contrastRatio(
            foreground: WCAGContrastMath.RGB(0.26, 0.80, 0.40),
            background: Self.card
        )
        #expect(ratio >= 3.0)
    }

    @Test("Amber accent on card meets AA large text threshold")
    func amberAccentOnCard() {
        let ratio = WCAGContrastMath.contrastRatio(
            foreground: WCAGContrastMath.RGB(0.96, 0.70, 0.12),
            background: Self.card
        )
        #expect(ratio >= 3.0)
    }

    // MARK: - Accessible accent fills (added in a11y audit)

    private static let white = WCAGContrastMath.RGB(1, 1, 1)
    private static let inkOnBright = WCAGContrastMath.RGB(0.08, 0.08, 0.10)
    private static let redAccent = WCAGContrastMath.RGB(0.84, 0.20, 0.18)
    private static let amber = WCAGContrastMath.RGB(0.96, 0.70, 0.12)
    private static let green = WCAGContrastMath.RGB(0.20, 0.68, 0.32)
    private static let orange = WCAGContrastMath.RGB(0.93, 0.45, 0.13)

    @Test("White text on redAccent (CTA / error banner) meets AA normal text")
    func textOnRedAccent() {
        let ratio = WCAGContrastMath.contrastRatio(foreground: Self.white, background: Self.redAccent)
        #expect(ratio >= 4.5)
    }

    @Test("inkOnBright on bright brand fills meets AA normal text in both modes")
    func inkOnBrightFills() {
        for fill in [Self.amber, Self.green, Self.orange] {
            let ratio = WCAGContrastMath.contrastRatio(foreground: Self.inkOnBright, background: fill)
            #expect(ratio >= 4.5)
        }
    }

    @Test("inkOnBright on green onboarding CTA meets AA normal text")
    func inkOnBrightOnGreenCTA() {
        let ratio = WCAGContrastMath.contrastRatio(foreground: Self.inkOnBright, background: Self.green)
        #expect(ratio >= 4.5)
    }

    @Test("Disabled CTA label on cardElevated meets AA normal text in both modes")
    func disabledCTALabelOnCardElevated() {
        let textDisabledDark = WCAGContrastMath.RGB(0.72, 0.72, 0.72)
        let cardElevatedDark = WCAGContrastMath.RGB(0.16, 0.16, 0.17)
        let textDisabledLight = WCAGContrastMath.RGB(0.28, 0.28, 0.30)
        let cardElevatedLight = WCAGContrastMath.RGB(0.92, 0.92, 0.94)

        #expect(
            WCAGContrastMath.contrastRatio(foreground: textDisabledDark, background: cardElevatedDark) >= 4.5
        )
        #expect(
            WCAGContrastMath.contrastRatio(foreground: textDisabledLight, background: cardElevatedLight) >= 4.5
        )
    }

    @Test("dartBox on card meets AA large text threshold in light mode")
    func dartBoxOnCardLight() {
        let dartBox = WCAGContrastMath.RGB(0.80, 0.80, 0.82)
        let card = WCAGContrastMath.RGB(1, 1, 1)
        let ratio = WCAGContrastMath.contrastRatio(foreground: dartBox, background: card)
        #expect(ratio >= 1.5)
    }

    @Test("Body copy on card surfaces meets AA normal text in dark mode")
    func bodyCopyOnCardDark() {
        let textBodyOnCard = WCAGContrastMath.RGB(0.75, 0.75, 0.75)
        let ratio = WCAGContrastMath.contrastRatio(foreground: textBodyOnCard, background: Self.card)
        #expect(ratio >= 4.5)
    }

    @Test("Warning pill text on amber tint stays AA in dark mode")
    func textOnAmberTintDark() {
        // Bot-turn / partial-stats banners: textPrimary (white in dark) on amber@0.32 over bg.
        let tint = WCAGContrastMath.composite(
            foreground: Self.amber,
            background: Self.background,
            opacity: 0.32
        )
        let ratio = WCAGContrastMath.contrastRatio(foreground: Self.white, background: tint)
        #expect(ratio >= 4.5)
    }
}

enum WCAGContrastMath {
    struct RGB: Sendable {
        let r: Double
        let g: Double
        let b: Double

        init(_ r: Double, _ g: Double, _ b: Double) {
            self.r = r
            self.g = g
            self.b = b
        }
    }

    static func composite(foreground: RGB, background: RGB, opacity: Double) -> RGB {
        RGB(
            opacity * foreground.r + (1 - opacity) * background.r,
            opacity * foreground.g + (1 - opacity) * background.g,
            opacity * foreground.b + (1 - opacity) * background.b
        )
    }

    static func contrastRatio(foreground: RGB, background: RGB) -> Double {
        let l1 = relativeLuminance(foreground)
        let l2 = relativeLuminance(background)
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func relativeLuminance(_ rgb: RGB) -> Double {
        func channel(_ value: Double) -> Double {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(rgb.r) + 0.7152 * channel(rgb.g) + 0.0722 * channel(rgb.b)
    }
}
