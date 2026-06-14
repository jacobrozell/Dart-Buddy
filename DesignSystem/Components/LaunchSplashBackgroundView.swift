import SwiftUI

/// Full-screen ambient launch backdrop. Title and spinner stay in `LaunchSplashView`
/// so copy stays localized and live UI can sit on top.
struct LaunchSplashBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    private enum Layout {
        /// Fraction of the short screen edge used for the board diameter.
        static let boardScale: CGFloat = 0.88
    }

    var body: some View {
        GeometryReader { geometry in
            let palette = LaunchSplashPalette.forColorScheme(colorScheme)
            let side = min(geometry.size.width, geometry.size.height)
            let boardSize = side * Layout.boardScale
            let boardCenter = CGPoint(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )

            ZStack {
                palette.canvasBackground

                RadialGradient(
                    colors: [
                        palette.glowColor.opacity(palette.glowOpacity),
                        palette.canvasBackground.opacity(0)
                    ],
                    center: .center,
                    startRadius: boardSize * 0.05,
                    endRadius: boardSize * 0.62
                )

                Circle()
                    .fill(palette.glowColor.opacity(palette.bullGlowOpacity))
                    .frame(width: boardSize * 0.34, height: boardSize * 0.34)
                    .blur(radius: boardSize * 0.08)
                    .position(boardCenter)

                LaunchMarkView()
                    .frame(width: boardSize, height: boardSize)
                    .position(boardCenter)
                    .shadow(
                        color: palette.boardShadowColor,
                        radius: palette.boardShadowRadius,
                        y: palette.boardShadowY
                    )

                RadialGradient(
                    colors: [
                        palette.canvasBackground.opacity(0),
                        palette.vignetteEdge
                    ],
                    center: .center,
                    startRadius: side * 0.35,
                    endRadius: side * 0.95
                )

                LinearGradient(
                    colors: [
                        palette.canvasBackground.opacity(0),
                        palette.bottomFadeMid,
                        palette.canvasBackground
                    ],
                    startPoint: UnitPoint(x: 0.5, y: 0.55),
                    endPoint: .bottom
                )
            }
        }
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("Launch Splash Background Light") {
    LaunchSplashBackgroundView()
        .environment(\.colorScheme, .light)
}

#Preview("Launch Splash Background Dark") {
    LaunchSplashBackgroundView()
        .environment(\.colorScheme, .dark)
}
#endif
