import SwiftUI

struct LaunchSplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var footerAppeared = false

    private let animateFooter: Bool

    init(animateFooter: Bool = true) {
        self.animateFooter = animateFooter
        _footerAppeared = State(initialValue: !animateFooter)
    }

    var body: some View {
        ZStack {
            if !reduceTransparency {
                LaunchSplashBackgroundView()
                    .ignoresSafeArea()
            } else {
                Brand.background.ignoresSafeArea()
            }

            VStack(spacing: DS.Spacing.s3) {
                Spacer()

                LaunchSplashWordmark()
                    .opacity(footerAppeared ? 1 : 0)

                LaunchDotsIndicator()
                    .opacity(footerAppeared ? 1 : 0)
                    .padding(.bottom, DS.Spacing.s6)
            }
            .frame(maxWidth: horizontalSizeClass == .regular ? 360 : .infinity)
            .padding(.horizontal, DS.Spacing.s4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.loading)
        .accessibilityIdentifier("launch_splash")
        .onAppear(perform: runEntranceAnimation)
    }

    private func runEntranceAnimation() {
        guard animateFooter else { return }

        if reduceMotion {
            footerAppeared = true
            return
        }

        withAnimation(.easeOut(duration: 0.35).delay(0.15)) {
            footerAppeared = true
        }
    }
}

private struct LaunchDotsIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let dotSize: CGFloat = 8
    private let inactiveOpacity = 0.35
    private let stepInterval: TimeInterval = 0.42

    var body: some View {
        Group {
            if reduceMotion {
                dotRow(activeIndex: 0)
            } else {
                TimelineView(.periodic(from: .now, by: stepInterval)) { context in
                    dotRow(activeIndex: activeStep(for: context.date))
                }
            }
        }
        .padding(.top, DS.Spacing.s1)
        .accessibilityHidden(true)
    }

    private func activeStep(for date: Date) -> Int {
        Int(date.timeIntervalSinceReferenceDate / stepInterval) % 3
    }

    private func dotRow(activeIndex: Int) -> some View {
        HStack(spacing: DS.Spacing.s2) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Brand.green)
                    .frame(width: dotSize, height: dotSize)
                    .opacity(index == activeIndex ? 1 : inactiveOpacity)
                    .scaleEffect(index == activeIndex ? 1.15 : 1)
                    .animation(.easeInOut(duration: 0.28), value: activeIndex)
            }
        }
    }
}

#if DEBUG
#Preview("Launch Splash Light") {
    LaunchSplashView(animateFooter: false)
        .environment(\.colorScheme, .light)
}

#Preview("Launch Splash Dark") {
    LaunchSplashView(animateFooter: false)
        .environment(\.colorScheme, .dark)
}

#Preview("Launch Splash — Light / Dark", traits: .sizeThatFitsLayout) {
    LaunchSplashAppearanceComparisonPreview()
}

private struct LaunchSplashAppearanceComparisonPreview: View {
    private let deviceWidth: CGFloat = 220
    private let deviceHeight: CGFloat = 476

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.s4) {
            appearanceColumn(title: "Light", scheme: .light)
            appearanceColumn(title: "Dark", scheme: .dark)
        }
        .padding(DS.Spacing.s4)
        .background(Color(.systemGroupedBackground))
    }

    private func appearanceColumn(title: String, scheme: ColorScheme) -> some View {
        VStack(spacing: DS.Spacing.s2) {
            LaunchSplashView(animateFooter: false)
                .frame(width: deviceWidth, height: deviceHeight)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg))
                .overlay {
                    RoundedRectangle(cornerRadius: DS.Radius.lg)
                        .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                }
                .environment(\.colorScheme, scheme)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}
#endif
