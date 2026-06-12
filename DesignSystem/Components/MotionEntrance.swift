import SwiftUI

/// Class B entrance: fade + slight upward slide for banners and hints.
private struct MotionBannerEntranceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : (reduceMotion ? 1 : 0))
            .offset(y: appeared ? 0 : (reduceMotion ? 0 : 6))
            .onAppear {
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(Motion.fast) {
                        appeared = true
                    }
                }
            }
    }
}

/// Class B reveal when tab content finishes its initial load.
private struct MotionTabContentRevealModifier: ViewModifier {
    let isRevealed: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : (reduceMotion ? 1 : 0))
            .onChange(of: isRevealed, initial: true) { _, revealed in
                guard revealed else {
                    visible = false
                    return
                }
                if reduceMotion {
                    visible = true
                } else if !visible {
                    withAnimation(Motion.fast) {
                        visible = true
                    }
                }
            }
    }
}

/// Class B staggered fade-in for match summary player rows after celebration.
private struct MotionStaggeredRevealModifier: ViewModifier {
    let index: Int
    let isRevealed: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : (reduceMotion ? 1 : 0))
            .task(id: revealKey) {
                guard isRevealed else {
                    visible = false
                    return
                }
                if reduceMotion {
                    visible = true
                    return
                }
                visible = false
                try? await Task.sleep(for: MotionPolicy.staggerDelay(for: index))
                guard !Task.isCancelled else { return }
                withAnimation(Motion.fast) {
                    visible = true
                }
            }
    }

    private var revealKey: String {
        "\(isRevealed)-\(index)"
    }
}

/// Class C brief scale pulse when a cricket mark count increases.
private struct MotionMarkIncrementPulseModifier: ViewModifier {
    let marks: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: marks) { previous, new in
                guard new > previous, MotionPolicy.shouldAnimate(reduceMotion: reduceMotion) else { return }
                scale = 1.03
                withAnimation(Motion.fast) {
                    scale = 1
                }
            }
    }
}

extension View {
    func motionBannerEntrance() -> some View {
        modifier(MotionBannerEntranceModifier())
    }

    func motionTabContentReveal(when isRevealed: Bool) -> some View {
        modifier(MotionTabContentRevealModifier(isRevealed: isRevealed))
    }

    func motionStaggeredReveal(index: Int, when isRevealed: Bool) -> some View {
        modifier(MotionStaggeredRevealModifier(index: index, isRevealed: isRevealed))
    }

    func motionMarkIncrementPulse(marks: Int) -> some View {
        modifier(MotionMarkIncrementPulseModifier(marks: marks))
    }

    /// Class C numeric score tween — only when `animatesChanges` is true (committed turns, not mid-visit entry).
    func motionNumericScore(_ score: Int, animatesChanges: Bool) -> some View {
        modifier(MotionNumericScoreModifier(score: score, animatesChanges: animatesChanges))
    }
}

private struct MotionNumericScoreModifier: ViewModifier {
    let score: Int
    let animatesChanges: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .contentTransition(.numericText())
            .animation(scoreAnimation, value: score)
    }

    private var scoreAnimation: Animation? {
        guard animatesChanges else { return nil }
        return MotionPolicy.standardAnimation(reduceMotion: reduceMotion)
    }
}
