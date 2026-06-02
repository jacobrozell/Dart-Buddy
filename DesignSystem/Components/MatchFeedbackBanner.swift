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
        switch style {
        case .bust: Brand.red
        case .legWin: Brand.green
        case .cricketClosure: Brand.amber
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .bust: Brand.red.opacity(0.18)
        case .legWin: Brand.green.opacity(0.2)
        case .cricketClosure: Brand.amber.opacity(0.2)
        }
    }

    private var scale: CGFloat {
        guard style != .bust, pulse, !reduceMotion else { return 1 }
        return 1.04
    }

    private func runEntranceAnimation() {
        guard animate, !reduceMotion else { return }
        if style == .bust {
            withAnimation(.linear(duration: 0.45)) { shakePhase = 1 }
            shakePhase = 0
        } else {
            pulse = false
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { pulse = true }
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
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
