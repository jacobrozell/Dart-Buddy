import SwiftUI

struct MatchSummaryCelebrationHeader: View {
    @ObservedObject var viewModel: MatchSummaryViewModel
    let trophyPointSize: CGFloat
    let celebrate: Bool
    let usesLandscapeSplit: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var headlineFont: Font {
        usesLandscapeSplit ? .largeTitle.weight(.heavy) : .title.weight(.heavy)
    }

    var body: some View {
        VStack(spacing: DS.Spacing.s2) {
            if viewModel.isForfeited {
                Image(systemName: "flag.checkered.2.crossed")
                    .font(.system(size: trophyPointSize))
                    .foregroundStyle(Brand.amber)
                    .accessibilityHidden(true)
                Text(L10n.string("play.summary.forfeit.title"))
                    .font(headlineFont)
                    .foregroundStyle(Brand.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("matchSummaryForfeitBanner")
                if let forfeiter = viewModel.forfeiterName, let winner = viewModel.winnerName {
                    Text(L10n.format("play.summary.forfeit.subtitle", forfeiter, winner))
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("matchSummaryForfeitSubtitle")
                } else if viewModel.forfeiterName != nil {
                    Text(L10n.string("play.summary.forfeit.solo.subtitle"))
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("matchSummaryForfeitSubtitle")
                }
            } else if viewModel.isCoopMatch {
                Image(systemName: viewModel.coopTeamVictory == true ? "checkmark.seal.fill" : "xmark.octagon.fill")
                    .font(.system(size: trophyPointSize))
                    .foregroundStyle(viewModel.coopTeamVictory == true ? Brand.green : Brand.redAccent)
                    .scaleEffect(celebrate ? 1 : (reduceMotion ? 1 : 0.4))
                    .opacity(celebrate ? 1 : (reduceMotion ? 1 : 0))
                    .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.6), value: celebrate)
                    .accessibilityHidden(true)
                Text(L10n.string(viewModel.coopHeadlineKey))
                    .font(headlineFont)
                    .foregroundStyle(Brand.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("matchSummaryCoopHeadline")
                if let subheadline = viewModel.coopSubheadline {
                    Text(subheadline)
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("matchSummaryCoopSubheadline")
                }
                if let mvpName = viewModel.coopMvpName {
                    Text(L10n.format("play.raid.mvpFormat", mvpName))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.amber)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("matchSummaryCoopMVP")
                }
            } else {
                Image(systemName: "trophy.fill")
                    .font(.system(size: trophyPointSize))
                    .foregroundStyle(Brand.amber)
                    .scaleEffect(celebrate ? 1 : (reduceMotion ? 1 : 0.4))
                    .opacity(celebrate ? 1 : (reduceMotion ? 1 : 0))
                    .rotationEffect(.degrees(celebrate ? 0 : (reduceMotion ? 0 : -25)))
                    .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.6), value: celebrate)
                if let winnerName = viewModel.winnerName {
                    Text(L10n.format("play.summary.winsFormat", winnerName))
                        .font(headlineFont)
                        .foregroundStyle(Brand.textPrimary)
                        .multilineTextAlignment(.center)
                }
            }
            Text(viewModel.typeLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
            if viewModel.hasResult {
                MatchSummaryGameRecordedBadge(isForfeited: viewModel.isForfeited)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, usesLandscapeSplit ? 0 : DS.Spacing.s4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityIdentifier("matchSummaryHeader")
    }

    private var accessibilitySummary: String {
        if viewModel.isForfeited {
            var parts = [L10n.string("play.summary.forfeit.title")]
            if let forfeiter = viewModel.forfeiterName, let winner = viewModel.winnerName {
                parts.append(L10n.format("play.summary.forfeit.subtitle", forfeiter, winner))
            } else if viewModel.forfeiterName != nil {
                parts.append(L10n.string("play.summary.forfeit.solo.subtitle"))
            }
            parts.append(viewModel.typeLabel)
            if viewModel.hasResult {
                parts.append(L10n.string("play.summary.forfeit.statsSaved"))
            }
            return parts.joined(separator: ". ")
        }
        if viewModel.isCoopMatch {
            var parts = [L10n.string(viewModel.coopHeadlineKey)]
            if let subheadline = viewModel.coopSubheadline {
                parts.append(subheadline)
            }
            if let mvpName = viewModel.coopMvpName {
                parts.append(L10n.format("play.raid.mvpFormat", mvpName))
            }
            parts.append(viewModel.typeLabel)
            if viewModel.hasResult {
                parts.append(L10n.string("play.summary.gameRecorded"))
            }
            return parts.joined(separator: ". ")
        }
        guard let winnerName = viewModel.winnerName else { return viewModel.typeLabel }
        let recorded = viewModel.hasResult ? L10n.string("play.summary.gameRecorded") : ""
        return L10n.format("play.summary.header.accessibilityFormat", winnerName, viewModel.typeLabel)
            + (recorded.isEmpty ? "" : ". \(recorded)")
    }
}

struct MatchSummaryGameRecordedBadge: View {
    let isForfeited: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isForfeited ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
            Text(isForfeited ? L10n.string("play.summary.forfeit.statsSaved") : L10n.string("play.summary.gameRecorded"))
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(isForfeited ? Brand.amber : Brand.green)
        .accessibilityIdentifier("matchSummaryGameRecorded")
    }
}
