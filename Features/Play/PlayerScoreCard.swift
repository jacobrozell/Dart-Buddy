import SwiftUI

/// One player's row on the X01 match screen: remaining score, current visit, and running stats.
/// Switches to a stacked layout at accessibility text sizes.
struct PlayerScoreCard: View {
    let name: String
    let score: Int
    let setsWon: Int
    let legsWon: Int
    let isActive: Bool
    let visitDarts: [DartInput]
    let dartsThrown: Int
    let average: Double

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var scoreFontSize: CGFloat = 40
    @ScaledMetric(relativeTo: .caption) private var dartBoxSize: CGFloat = 38

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(isActive ? Brand.green : Color.clear)
                .frame(width: 6)
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    accessibilityBody
                } else {
                    compactBody
                }
            }
            .padding(DS.Spacing.s3)
        }
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityIdentifier(isActive ? "scoreCard_active" : "scoreCard")
    }

    private var compactBody: some View {
        HStack(alignment: .center, spacing: DS.Spacing.s3) {
            scoreNameColumn
            Spacer(minLength: DS.Spacing.s2)
            visitColumn
            Spacer(minLength: DS.Spacing.s2)
            statsColumn
        }
    }

    private var accessibilityBody: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            scoreNameColumn
            visitColumn
            statsColumn
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var displayScoreFontSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? min(scoreFontSize, 56) : scoreFontSize
    }

    private var displayDartBoxSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? min(dartBoxSize, 44) : dartBoxSize
    }

    private var scoreNameColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(score)")
                .font(.system(size: displayScoreFontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(Brand.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityIdentifier(isActive ? "scoreCard_remaining" : "")
            Text(name)
                .font(.subheadline)
                .foregroundStyle(isActive ? Brand.green : Brand.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
    }

    private var visitColumn: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                ForEach(0 ..< 3, id: \.self) { slot in
                    dartBox(slot < visitDarts.count ? dartLabel(visitDarts[slot]) : nil)
                        .accessibilityIdentifier(isActive ? "scoreCard_dartSlot_\(slot)" : "")
                }
            }
            Text("\(visitTotal)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
                .accessibilityIdentifier(isActive ? "scoreCard_visitTotal" : "")
        }
    }

    private var statsColumn: some View {
        VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 6) {
            setsLegsLabels
            HStack(spacing: 4) {
                Image(systemName: "scope").font(.footnote)
                Text("\(dartsThrown)").font(.footnote.weight(.semibold))
            }
            .foregroundStyle(Brand.textSecondary)
            .accessibilityIdentifier(isActive ? "scoreCard_dartsThrown" : "")
            HStack(spacing: 4) {
                Image(systemName: "chart.bar.fill").font(.footnote)
                Text(String(format: "%.2f", average)).font(.footnote.weight(.semibold))
            }
            .foregroundStyle(Brand.textSecondary)
            .accessibilityIdentifier(isActive ? "scoreCard_average" : "")
        }
        .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? nil : 72, alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
    }

    private var setsLegsLabels: some View {
        VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 2) {
            Text(L10n.format("play.x01.setsCountFormat", setsWon))
            Text(L10n.format("play.x01.legsCountFormat", legsWon))
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(Brand.textSecondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    private var visitTotal: Int {
        visitDarts.reduce(0) { $0 + $1.points }
    }

    private var accessibilitySummary: String {
        var parts = [L10n.format("play.x01.scoreCard.summaryFormat", name, score)]
        if isActive {
            parts.append(L10n.string("play.x01.turn.active"))
        }
        let dartSpeech = visitDarts.map(\.spokenAccessibilityName)
        if !dartSpeech.isEmpty {
            parts.append(L10n.format("play.x01.scoreCard.visitDartsFormat", dartSpeech.joined(separator: ", ")))
        }
        parts.append(L10n.format("play.x01.scoreCard.visitTotalFormat", visitTotal))
        parts.append(L10n.format("play.x01.setsLegsFormat", setsWon, legsWon))
        parts.append(L10n.format("play.x01.scoreCard.dartsThrownFormat", dartsThrown))
        parts.append(L10n.format("play.x01.scoreCard.averageFormat", average))
        return parts.joined(separator: ". ")
    }

    private func dartBox(_ label: String?) -> some View {
        Text(label ?? "")
            .font(.system(size: max(13, displayDartBoxSize * 0.4), weight: .bold, design: .rounded))
            .foregroundStyle(Brand.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: displayDartBoxSize, height: displayDartBoxSize)
            .background(Brand.dartBox, in: RoundedRectangle(cornerRadius: 6))
    }

    private func dartLabel(_ dart: DartInput) -> String {
        if dart.isMiss { return "0" }
        switch dart.segment {
        case let .oneToTwenty(value):
            switch dart.multiplier {
            case .single: return "\(value)"
            case .double: return "D\(value)"
            case .triple: return "T\(value)"
            }
        case .outerBull: return "25"
        case .innerBull: return "50"
        case .miss: return "0"
        }
    }
}
