import SwiftUI

/// Launch-only colors tuned for ambient splash legibility in light and dark mode.
struct LaunchSplashPalette {
    let face: Color
    let wedgeDark: Color
    let wedgeLight: Color
    let accentRed: Color
    let accentGreen: Color
    let rim: Color
    let wire: Color
    let canvasBackground: Color
    let glowColor: Color
    let glowOpacity: Double
    let bullGlowOpacity: Double
    let boardShadowColor: Color
    let boardShadowRadius: CGFloat
    let boardShadowY: CGFloat
    let vignetteEdge: Color
    let bottomFadeMid: Color

    static func forColorScheme(_ colorScheme: ColorScheme) -> LaunchSplashPalette {
        switch colorScheme {
        case .dark:
            LaunchSplashPalette(
                face: Color(red: 0.14, green: 0.14, blue: 0.17),
                wedgeDark: Color(red: 0.19, green: 0.19, blue: 0.22),
                wedgeLight: Color(red: 0.26, green: 0.26, blue: 0.30),
                accentRed: Brand.red,
                accentGreen: Brand.green,
                rim: Color(red: 0.32, green: 0.32, blue: 0.36),
                wire: Color.white.opacity(0.14),
                canvasBackground: Color(red: 0.05, green: 0.06, blue: 0.09),
                glowColor: Brand.green,
                glowOpacity: 0.24,
                bullGlowOpacity: 0.18,
                boardShadowColor: Brand.green.opacity(0.35),
                boardShadowRadius: 28,
                boardShadowY: 0,
                vignetteEdge: Color.black.opacity(0.45),
                bottomFadeMid: Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.55)
            )
        default:
            LaunchSplashPalette(
                face: Color(red: 0.98, green: 0.97, blue: 0.95),
                wedgeDark: Color(red: 0.78, green: 0.77, blue: 0.74),
                wedgeLight: Color(red: 0.93, green: 0.92, blue: 0.89),
                accentRed: Brand.red.opacity(0.90),
                accentGreen: Brand.green.opacity(0.90),
                rim: Color(red: 0.86, green: 0.84, blue: 0.80),
                wire: Color.black.opacity(0.08),
                canvasBackground: Color(red: 0.95, green: 0.94, blue: 0.92),
                glowColor: Brand.green,
                glowOpacity: 0.28,
                bullGlowOpacity: 0.32,
                boardShadowColor: Brand.green.opacity(0.22),
                boardShadowRadius: 24,
                boardShadowY: 10,
                vignetteEdge: Color(red: 0.72, green: 0.70, blue: 0.66).opacity(0.22),
                bottomFadeMid: Color(red: 0.95, green: 0.94, blue: 0.92).opacity(0.50)
            )
        }
    }
}
