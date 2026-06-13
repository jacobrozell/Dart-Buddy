import SwiftUI

struct BotStatSliderRow: View {
    let title: LocalizedStringKey
    let hint: LocalizedStringKey?
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String

    init(
        title: LocalizedStringKey,
        hint: LocalizedStringKey? = nil,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 0.01,
        format: @escaping (Double) -> String = { BotDifficultyDisplayProfile.percent($0) }
    ) {
        self.title = title
        self.hint = hint
        self._value = value
        self.range = range
        self.step = step
        self.format = format
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
                Spacer()
                Text(format(value))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Brand.green)
            }
            Slider(value: $value, in: range, step: step)
                .tint(Brand.green)
            if let hint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(format(value)))
    }
}
