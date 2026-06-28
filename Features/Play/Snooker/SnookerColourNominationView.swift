import SwiftUI

struct SnookerColourNominationView: View {
    let selectedColour: SnookerColour?
    let onSelect: (SnookerColour) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(L10n.string("play.snooker.nominateColour"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.s2) {
                    ForEach(SnookerColour.allCases, id: \.self) { colour in
                        Button {
                            onSelect(colour)
                        } label: {
                            VStack(spacing: 4) {
                                Text(L10n.string(colour.localizationKey))
                                    .font(.caption.weight(.semibold))
                                Text("\(colour.points)")
                                    .font(.caption2.monospacedDigit())
                            }
                            .padding(.horizontal, DS.Spacing.s2)
                            .padding(.vertical, DS.Spacing.s1)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.sm)
                                    .fill(selectedColour == colour ? Brand.green.opacity(0.25) : Brand.card)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.sm)
                                    .strokeBorder(selectedColour == colour ? Brand.green : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("snooker_nominate_\(colour.rawValue)")
                    }
                }
            }
            Text(L10n.string("play.snooker.pad.nominationHint"))
                .font(.caption2)
                .foregroundStyle(Brand.textSecondary)
        }
        .accessibilityIdentifier("snooker_colour_nomination")
    }
}
