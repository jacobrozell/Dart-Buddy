import SwiftUI

/// Full-screen launch backdrop compositions. Background art only — title and spinner stay in
/// `LaunchSplashView` so copy stays localized and live UI can sit on top.
struct LaunchSplashBackgroundView: View {
    enum Style: String, CaseIterable {
        /// Large centered board (~78% of the short edge), upper-center placement.
        case hero
        /// Oversized board cropped at the edges for an immersive fill.
        case ambient
        /// Soft watermark board with a sharper hero mark near center.
        case soft
    }

    let style: Style

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)

            ZStack {
                Brand.background

                switch style {
                case .hero:
                    LaunchMarkView()
                        .frame(width: side * 0.78, height: side * 0.78)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height * 0.4
                        )

                case .ambient:
                    LaunchMarkView()
                        .frame(width: side * 1.18, height: side * 1.18)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height * 0.43
                        )

                    LinearGradient(
                        colors: [
                            Brand.background.opacity(0),
                            Brand.background.opacity(0.55),
                            Brand.background
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0.55),
                        endPoint: .bottom
                    )

                case .soft:
                    LaunchMarkView()
                        .opacity(0.12)
                        .frame(width: side * 1.02, height: side * 1.02)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height * 0.4
                        )

                    LaunchMarkView()
                        .frame(width: side * 0.42, height: side * 0.42)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height * 0.4
                        )
                }
            }
        }
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("Launch Splash Hero") {
    LaunchSplashBackgroundView(style: .hero)
}

#Preview("Launch Splash Ambient") {
    LaunchSplashBackgroundView(style: .ambient)
}

#Preview("Launch Splash Soft") {
    LaunchSplashBackgroundView(style: .soft)
}
#endif
