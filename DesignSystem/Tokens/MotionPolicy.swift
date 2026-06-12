import SwiftUI

/// Canonical motion durations and curves — see `specs/AnimationSpec.md` §7.
enum Motion {
    static let fast = Animation.easeOut(duration: 0.17)
    static let standard = Animation.easeInOut(duration: 0.21)
    static let emphasis = Animation.spring(response: 0.5, dampingFraction: 0.6)
}

enum MotionPolicy {
    static func shouldAnimate(reduceMotion: Bool, animationsEnabled: Bool = true) -> Bool {
        animationsEnabled && !reduceMotion
    }

    static func fastAnimation(reduceMotion: Bool, animationsEnabled: Bool = true) -> Animation? {
        shouldAnimate(reduceMotion: reduceMotion, animationsEnabled: animationsEnabled) ? Motion.fast : nil
    }

    static func standardAnimation(reduceMotion: Bool, animationsEnabled: Bool = true) -> Animation? {
        shouldAnimate(reduceMotion: reduceMotion, animationsEnabled: animationsEnabled) ? Motion.standard : nil
    }

    static func animateIfAllowed(
        reduceMotion: Bool,
        animationsEnabled: Bool = true,
        _ animation: Animation = Motion.fast,
        _ body: () -> Void
    ) {
        if shouldAnimate(reduceMotion: reduceMotion, animationsEnabled: animationsEnabled) {
            withAnimation(animation, body)
        } else {
            body()
        }
    }

    /// Stagger delay per index for summary stat rows (40ms per spec).
    static func staggerDelay(for index: Int) -> Duration {
        .milliseconds(index * 40)
    }
}

enum MotionTransition {
    /// Onboarding step change — opacity-only when Reduce Motion; otherwise a short horizontal slide.
    static func onboardingStep(reduceMotion: Bool, layoutDirection: LayoutDirection) -> AnyTransition {
        if reduceMotion {
            return .opacity
        }
        let insertionEdge: Edge = layoutDirection == .rightToLeft ? .leading : .trailing
        let removalEdge: Edge = layoutDirection == .rightToLeft ? .trailing : .leading
        return .asymmetric(
            insertion: .move(edge: insertionEdge).combined(with: .opacity),
            removal: .move(edge: removalEdge).combined(with: .opacity)
        )
    }
}
