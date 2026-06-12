import SwiftUI

struct LaunchSplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var heroAppeared = false
    @State private var wordmarkAppeared = false

    private let markSize: CGFloat = 120

    var body: some View {
        ZStack {
            Brand.background.ignoresSafeArea()

            if !reduceTransparency {
                DartboardWedgeBackdrop()
                    .ignoresSafeArea()
            }

            VStack(spacing: DS.Spacing.s4) {
                Image("LaunchMark")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: markSize, height: markSize)
                    .scaleEffect(heroAppeared ? 1 : 0.92)
                    .opacity(heroAppeared ? 1 : 0)

                Text(L10n.brandTitle)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
                    .opacity(wordmarkAppeared ? 1 : 0)

                LaunchDotsIndicator()
                    .opacity(heroAppeared ? 1 : 0)
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
        if reduceMotion {
            heroAppeared = true
            wordmarkAppeared = true
            return
        }

        withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
            heroAppeared = true
        }
        withAnimation(.easeOut(duration: 0.35).delay(0.2)) {
            wordmarkAppeared = true
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
#Preview("Launch Splash") {
    LaunchSplashView()
}
#endif
