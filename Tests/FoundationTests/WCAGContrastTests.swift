import Foundation
import Testing
@testable import DartsScoreboard

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
