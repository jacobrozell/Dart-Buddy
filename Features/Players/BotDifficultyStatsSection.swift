import SwiftUI

struct BotDifficultyStatsSection: View {
    let profile: BotDifficultyDisplayProfile
    var showsHeader: Bool = true
    @State private var showsEngineDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            if showsHeader {
                Text(L10n.botStatsSection)
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
            }

            if let summary = profile.summary, summary.hasValues {
                summaryCard(summary)
            }

            DisclosureGroup(isExpanded: $showsEngineDetails) {
                engineDetailsContent
            } label: {
                Text(L10n.botStatsEngineDetails)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
            }
            .accessibilityIdentifier("botStats_engineDetails")

            Text(L10n.botStatsFooter)
                .font(.caption)
                .foregroundStyle(Brand.textSecondary)
        }
    }

    @ViewBuilder
    private var engineDetailsContent: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            modeCard(title: L10n.x01Title) {
                BotStatRow(
                    labelKey: "players.bots.stats.scoringVisitRange",
                    value: BotDifficultyDisplayProfile.range(profile.x01.scoringVisitMin, profile.x01.scoringVisitMax)
                )
                statDivider
                hitChanceRows(profile.x01.hitChances)
                statDivider
                BotStatRow(
                    labelKey: "players.bots.stats.checkoutAttemptRate",
                    value: BotDifficultyDisplayProfile.percent(profile.x01.checkoutAttemptChance)
                )
                BotStatRow(
                    labelKey: "players.bots.stats.offBoardMiss",
                    value: BotDifficultyDisplayProfile.percent(profile.x01.offBoardMissChance)
                )
                BotStatRow(
                    labelKey: "players.bots.stats.bustRisk",
                    value: BotDifficultyDisplayProfile.percent(profile.x01.riskyBustChance)
                )
                BotStatRow(
                    labelKey: "players.bots.stats.triplePreference",
                    value: BotDifficultyDisplayProfile.percent(profile.x01.triplePreference)
                )
                BotStatRow(
                    labelKey: "players.bots.stats.checkInBoost",
                    value: BotDifficultyDisplayProfile.percent(profile.x01.checkInHitBoost, signed: true)
                )
                if profile.x01.innerBullAimChance > 0 {
                    BotStatRow(
                        labelKey: "players.bots.stats.innerBullAim",
                        value: BotDifficultyDisplayProfile.percent(profile.x01.innerBullAimChance)
                    )
                }
                if profile.x01.masterInTripleOpenerChance > 0 {
                    BotStatRow(
                        labelKey: "players.bots.stats.masterInTriple",
                        value: BotDifficultyDisplayProfile.percent(profile.x01.masterInTripleOpenerChance)
                    )
                }
            }

            modeCard(title: L10n.cricketTitle) {
                hitChanceRows(profile.cricket.hitChances)
                statDivider
                BotStatRow(
                    labelKey: "players.bots.stats.offBoardMiss",
                    value: BotDifficultyDisplayProfile.percent(profile.cricket.offBoardMissChance)
                )
                BotStatRow(
                    labelKey: "players.bots.stats.wrongBed",
                    value: BotDifficultyDisplayProfile.percent(profile.cricket.wrongBedChance)
                )
            }
        }
        .padding(.top, DS.Spacing.s2)
    }

    @ViewBuilder
    private func summaryCard(_ summary: BotModeSummaryMetrics) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(L10n.botStatsSummarySection)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                if let x01Average = summary.x01Average {
                    BotStatRow(
                        labelKey: "customBot.x01Average.label",
                        value: String(format: "%.0f", x01Average)
                    )
                }
                if summary.x01Average != nil, summary.cricketMPR != nil {
                    statDivider
                }
                if let cricketMPR = summary.cricketMPR {
                    BotStatRow(
                        labelKey: "customBot.cricketMPR.label",
                        value: String(format: "%.2f", cricketMPR)
                    )
                }
            }
            .padding(.horizontal, DS.Spacing.s3)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))

            Text(L10n.botStatsSummaryHint)
                .font(.caption)
                .foregroundStyle(Brand.textSecondary)
        }
        .accessibilityIdentifier("botStats_summary")
    }

    @ViewBuilder
    private func modeCard(title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, DS.Spacing.s3)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        }
    }

    @ViewBuilder
    private func hitChanceRows(_ chances: BotDifficultyDisplayProfile.HitChances) -> some View {
        BotStatRow(
            labelKey: "players.bots.stats.hitChanceSingle",
            value: BotDifficultyDisplayProfile.percent(chances.single)
        )
        BotStatRow(
            labelKey: "players.bots.stats.hitChanceDouble",
            value: BotDifficultyDisplayProfile.percent(chances.double)
        )
        BotStatRow(
            labelKey: "players.bots.stats.hitChanceTriple",
            value: BotDifficultyDisplayProfile.percent(chances.triple)
        )
    }

    private var statDivider: some View {
        Divider().overlay(Brand.cardElevated)
    }
}

private struct BotStatRow: View {
    let labelKey: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(LocalizedStringKey(labelKey))
                .font(.subheadline)
                .foregroundStyle(Brand.textSecondary)
            Spacer(minLength: DS.Spacing.s3)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.textPrimary)
                .monospacedDigit()
        }
        .padding(.vertical, DS.Spacing.s2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("stats.statTile.accessibilityFormat", L10n.string(labelKey), value))
    }
}
