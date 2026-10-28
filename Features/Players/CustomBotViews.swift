import SwiftUI

struct CustomBotBadge: View {
    let metrics: CustomBotMetrics
    var prominence: BotDifficultyBadge.Prominence = .standard

    private var accent: Color { Brand.proBot.opacity(0.85) }

    var body: some View {
        HStack(spacing: prominence == .compact ? 4 : 6) {
            Image(systemName: "slider.horizontal.3")
                .font(prominence == .compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
            Text(L10n.format("customBot.badge.format", metrics.x01Average, metrics.cricketMPR))
                .font(prominence == .compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
        }
        .foregroundStyle(accent)
        .padding(.horizontal, prominence == .compact ? DS.Spacing.s2 : DS.Spacing.s3)
        .padding(.vertical, prominence == .compact ? 4 : 6)
        .background(accent.opacity(0.15), in: Capsule())
        .overlay(Capsule().strokeBorder(accent.opacity(0.35), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("customBot.badge.accessibilityFormat", metrics.x01Average, metrics.cricketMPR))
    }
}

struct CustomBotMetricsEditor: View {
    @Binding var x01Average: Double
    @Binding var cricketMPR: Double

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            metricSlider(
                title: L10n.customBotX01AverageLabel,
                hint: L10n.customBotX01AverageHint,
                value: $x01Average,
                range: CustomBotMetrics.x01AverageRange,
                step: 1
            ) { String(format: "%.0f", $0) }

            metricSlider(
                title: L10n.customBotCricketMPRLabel,
                hint: L10n.customBotCricketMPRHint,
                value: $cricketMPR,
                range: CustomBotMetrics.cricketMPRRange,
                step: 0.05
            ) { String(format: "%.2f", $0) }
        }
    }

    private func metricSlider(
        title: LocalizedStringKey,
        hint: LocalizedStringKey,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: (Double) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
                Spacer()
                Text(format(value.wrappedValue))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Brand.green)
            }
            Slider(
                value: value,
                in: range,
                step: step
            )
            .tint(Brand.green)
            Text(hint)
                .font(.caption)
                .foregroundStyle(Brand.textSecondary)
        }
    }
}
