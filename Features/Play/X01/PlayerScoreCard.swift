import SwiftUI

/// One player's row on the X01 match screen: remaining score, current visit, and running stats.
/// Switches to a stacked layout at accessibility text sizes.
struct PlayerScoreCard: View {
    let name: String
    let score: Int
    let setsWon: Int
    let legsWon: Int
    let isActive: Bool
    let colorToken: PlayerColorToken
    let visitDarts: [DartInput]
    let dartsThrown: Int
    let average: Double

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ScaledMetric(relativeTo: .largeTitle) private var scoreFontSize: CGFloat = 40
    @ScaledMetric(relativeTo: .caption) private var dartBoxSize: CGFloat = 38
    @ScaledMetric(relativeTo: .largeTitle) private var compactScoreFontSize: CGFloat = 34
    @ScaledMetric(relativeTo: .caption) private var compactDartBoxSize: CGFloat = 30

    private var usesWideLayout: Bool {
        GameplayLayout.usesWidePlayerScoreCardLayout(
            horizontalSizeClass: horizontalSizeClass,
            dynamicTypeSize: dynamicTypeSize
        )
    }

    private var usesCompactDensity: Bool {
        !usesWideLayout && !dynamicTypeSize.isAccessibilitySize
    }

    private var accentColor: Color {
        PlayerVisualViews.accentColor(token: colorToken)
    }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(isActive ? accentColor : Color.clear)
                .frame(width: 6)
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    accessibilityBody
                } else if usesWideLayout {
                    wideBody
                } else {
                    compactBody
                }
            }
            .padding(usesCompactDensity ? DS.Spacing.s2 : DS.Spacing.s3)
        }
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityIdentifier(isActive ? "scoreCard_active" : "scoreCard")
    }

    private var compactBody: some View {
        HStack(alignment: .center, spacing: DS.Spacing.s3) {
            scoreNameColumn
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
            visitColumn
            statsColumn
        }
    }

    /// iPad / regular width: score and name share a row so names are not squeezed by visit slots.
    private var wideBody: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s3) {
                scoreLabel
                Text(name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isActive ? accentColor : Brand.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity, alignment: .leading)
                statsColumn
            }
            visitColumn
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
        if dynamicTypeSize.isAccessibilitySize { return min(scoreFontSize, 56) }
        return usesCompactDensity ? compactScoreFontSize : scoreFontSize
    }

    private var displayDartBoxSize: CGFloat {
        if dynamicTypeSize.isAccessibilitySize { return min(dartBoxSize, 44) }
        return usesCompactDensity ? compactDartBoxSize : dartBoxSize
    }

    private var scoreLabel: some View {
        Text("\(score)")
            .font(.system(size: displayScoreFontSize, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(Brand.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .accessibilityIdentifier(isActive ? "scoreCard_remaining" : "")
    }

    private var scoreNameColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            if isActive && dynamicTypeSize.isAccessibilitySize {
                Text(L10n.string("play.x01.turn.active"))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(accentColor)
                    .accessibilityHidden(true)
            }
            scoreLabel
            Text(name)
                .font(.subheadline)
                .foregroundStyle(isActive ? accentColor : Brand.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var visitColumn: some View {
        VStack(spacing: usesCompactDensity ? 2 : 4) {
            HStack(spacing: usesCompactDensity ? 4 : 6) {
                ForEach(0 ..< 3, id: \.self) { slot in
                    dartBox(slot < visitDarts.count ? dartLabel(visitDarts[slot]) : nil)
                        .accessibilityIdentifier(isActive ? "scoreCard_dartSlot_\(slot)" : "")
                }
            }
            Text("\(visitTotal)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(Brand.textSecondary)
                .accessibilityIdentifier(showsVisitTotalAccessibility ? "scoreCard_visitTotal" : "")
        }
    }

    private var statsColumn: some View {
        VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: usesCompactDensity ? 4 : 6) {
            setsLegsLabels
            HStack(spacing: 4) {
                Image(systemName: "scope").font(.footnote)
                Text("\(dartsThrown)").font(.footnote.weight(.semibold)).monospacedDigit()
            }
            .foregroundStyle(Brand.textSecondary)
            .accessibilityIdentifier(isActive ? "scoreCard_dartsThrown" : "")
            HStack(spacing: 4) {
                Image(systemName: "chart.bar.fill").font(.footnote)
                Text(String(format: "%.2f", average)).font(.footnote.weight(.semibold)).monospacedDigit()
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

    private var showsVisitTotalAccessibility: Bool {
        isActive || !visitDarts.isEmpty
    }

    private var accessibilitySummary: String {
        var parts = [L10n.format("play.x01.scoreCard.summaryFormat", name, score)]
        guard isActive else { return parts.joined(separator: ". ") }
        parts.append(L10n.string("play.x01.turn.active"))
        let dartSpeech = visitDarts.map(\.spokenAccessibilityName)
        if !dartSpeech.isEmpty {
            parts.append(L10n.format("play.x01.scoreCard.visitDartsFormat", dartSpeech.joined(separator: ", ")))
        }
        return parts.joined(separator: ". ")
    }

    private func dartBox(_ label: String?) -> some View {
        Text(label ?? "")
            .font(.system(size: max(13, displayDartBoxSize * 0.4), weight: .bold, design: .rounded))
            .foregroundStyle(Brand.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: displayDartBoxSize, height: displayDartBoxSize)
            .background(Brand.dartBox, in: ScoringPadStyle.visitSlotShape)
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
