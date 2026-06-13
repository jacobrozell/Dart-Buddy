import SwiftUI

enum MatchFeedbackStyle {
    case bust
    case legWin
    case cricketClosure
}

struct MatchFeedbackBanner: View {
    let text: LocalizedStringKey
    let style: MatchFeedbackStyle
    var animate: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var pulse = false
    @State private var shakePhase: CGFloat = 0

    var body: some View {
        Text(text)
            .font(style == .bust ? .headline.weight(.heavy) : .subheadline.weight(.bold))
            .foregroundStyle(foregroundColor)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.s2)
            .padding(.horizontal, DS.Spacing.s3)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
            .scaleEffect(scale)
            .modifier(ShakeEffect(animatableData: shakePhase))
            .onAppear { runEntranceAnimation() }
            .onChange(of: animate) { _, shouldAnimate in
                if shouldAnimate { runEntranceAnimation() }
            }
    }

    private var foregroundColor: Color {
        Brand.textPrimary
    }

    private var backgroundColor: Color {
        let fillOpacity: Double = colorScheme == .dark ? 0.32 : 0.22
        switch style {
        case .bust: return Brand.red.opacity(fillOpacity)
        case .legWin: return Brand.green.opacity(fillOpacity)
        case .cricketClosure: return Brand.amber.opacity(fillOpacity)
        }
    }

    private var scale: CGFloat {
        guard style != .bust, pulse, !reduceMotion else { return 1 }
        return 1.04
    }

    /// Hold the entrance pulse briefly before easing back to resting scale.
    private static let pulseSettleDelayNanoseconds: UInt64 = 500_000_000

    private func runEntranceAnimation() {
        guard animate, !reduceMotion else { return }
        if style == .bust {
            withAnimation(.linear(duration: 0.45)) { shakePhase = 1 }
            shakePhase = 0
        } else {
            pulse = false
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { pulse = true }
            Task {
                try? await Task.sleep(nanoseconds: Self.pulseSettleDelayNanoseconds)
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.2)) { pulse = false }
                }
            }
        }
    }
}

private struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = sin(animatableData * .pi * 6) * 6
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}
