import SwiftUI

struct PlayerDetailView: View {
    let player: EditablePlayer?
    let dependencies: AppDependencies
    let onEdit: () -> Void
    let onArchiveToggle: () -> Void

    var body: some View {
        Group {
            if let player {
                PlayerStatsDetailView(player: player, dependencies: dependencies, onEdit: onEdit, onArchiveToggle: onArchiveToggle)
            } else {
                ContentUnavailableView(L10n.playerNotFound, systemImage: "person.crop.circle.badge.exclamationmark")
                    .brandScoreboardEmptyState()
            }
        }
        .navigationTitle(L10n.playerDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PlayerStatsDetailView: View {
    let player: EditablePlayer
    let onEdit: () -> Void
    let onArchiveToggle: () -> Void
    @StateObject private var viewModel: PlayerDetailViewModel
    @State private var loadTask: Task<Void, Never>?

    init(player: EditablePlayer, dependencies: AppDependencies, onEdit: @escaping () -> Void, onArchiveToggle: @escaping () -> Void) {
        self.player = player
        self.onEdit = onEdit
        self.onArchiveToggle = onArchiveToggle
        _viewModel = StateObject(wrappedValue: PlayerDetailViewModel(
            playerId: player.id,
            playerName: player.name,
            matchRepository: dependencies.matchRepository,
            statsRepository: dependencies.statsRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                PlayerIdentityCard(player: player)
                if player.isArchived {
                    Text(L10n.archived)
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                }

                if let lastPlayedText = viewModel.lastPlayedText {
                    Text(lastPlayedText)
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                }

                if viewModel.isLoading {
                    ProgressView().tint(Brand.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.s6)
                } else if !viewModel.hasAnyGames {
                    Text(L10n.playersDetailNoGames)
                        .foregroundStyle(Brand.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.s6)
                } else {
                    if let x01 = viewModel.x01, x01.games > 0 {
                        modeSection(title: L10n.x01Title, stats: x01, isX01: true)
                    }
                    if let cricket = viewModel.cricket, cricket.games > 0 {
                        modeSection(title: L10n.cricketTitle, stats: cricket, isX01: false)
                    }

                    if !viewModel.recentMatches.isEmpty {
                        recentMatchesSection
                    }
                }

                HStack(spacing: DS.Spacing.s3) {
                    Button(L10n.edit, action: onEdit)
                        .buttonStyle(.bordered)
                        .tint(Brand.green)
                        .accessibilityLabel(L10n.string("players.detail.edit.accessibility"))
                        .accessibilityIdentifier("playerDetail_edit")
                    if !player.isBot {
                        Button(player.isArchived ? "players.unarchive" : "players.archive", action: onArchiveToggle)
                            .buttonStyle(.bordered)
                            .tint(Brand.orange)
                            .accessibilityLabel(
                                L10n.string(player.isArchived ? "players.detail.unarchive.accessibility" : "players.detail.archive.accessibility")
                            )
                            .accessibilityIdentifier("playerDetail_archive")
                    }
                }
                .padding(.top, DS.Spacing.s2)
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s6)
        }
        .background(Brand.background.ignoresSafeArea())
        .task { await viewModel.load() }
        .onDisappear { loadTask?.cancel() }
    }

    @ViewBuilder
    private var recentMatchesSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text(L10n.playersDetailRecentMatches)
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.textPrimary)

            VStack(spacing: 0) {
                ForEach(viewModel.recentMatches) { match in
                    HStack(spacing: DS.Spacing.s3) {
                        Text(match.type == .x01 ? L10n.x01Title : L10n.cricketTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Brand.textSecondary)
                            .frame(width: 56, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(match.opponentLabel)
                                .font(.subheadline)
                                .foregroundStyle(Brand.textPrimary)
                                .lineLimit(1)
                            Text(match.playedAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(Brand.textSecondary)
                        }
                        Spacer()
                        Text(match.didWin ? L10n.playersDetailWin : L10n.playersDetailLoss)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(match.didWin ? Brand.green : Brand.red)
                    }
                    .padding(.horizontal, DS.Spacing.s3)
                    .padding(.vertical, DS.Spacing.s3)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(recentMatchAccessibilityLabel(match))
                    if match.id != viewModel.recentMatches.last?.id {
                        Divider().overlay(Brand.cardElevated)
                    }
                }
            }
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        }
    }

    private func recentMatchAccessibilityLabel(_ match: RecentMatchSummary) -> String {
        let mode = match.type == .x01 ? L10n.string("play.x01.title") : L10n.string("play.cricket.title")
        let outcome = match.didWin ? L10n.string("players.detail.win") : L10n.string("players.detail.loss")
        let date = DateFormatter.localizedString(from: match.playedAt, dateStyle: .medium, timeStyle: .none)
        return L10n.format("players.detail.recentMatch.accessibilityFormat", mode, match.opponentLabel, outcome, date)
    }

    @ViewBuilder
    private func modeSection(title: LocalizedStringKey, stats: PlayerStatBreakdown, isX01: Bool) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Spacing.s3) {
                StatTile(labelKey: "stats.games", value: "\(stats.games)")
                StatTile(labelKey: "stats.wins", value: "\(stats.wins) (\(String(format: "%.0f%%", stats.winPercent)))")
                StatTile(labelKey: "stats.throws", value: "\(stats.darts)")
                StatTile(labelKey: "stats.points", value: "\(stats.points)")
                if isX01 {
                    StatTile(labelKey: "stats.legsWon", value: "\(stats.legs)")
                    StatTile(labelKey: "stats.threeDartAverage", value: String(format: "%.1f", stats.average3Dart))
                    StatTile(labelKey: "stats.highestScore", value: "\(stats.highestScore)")
                    StatTile(labelKey: "stats.checkouts", value: "\(stats.checkouts)")
                    StatTile(labelKey: "stats.bestCheckout", value: stats.highestCheckout > 0 ? "\(stats.highestCheckout)" : "-")
                } else {
                    StatTile(labelKey: "stats.mpr", value: String(format: "%.2f", stats.marksPerRound))
                    StatTile(labelKey: "stats.marks", value: "\(stats.cricketMarks)")
                    StatTile(labelKey: "stats.rounds", value: "\(stats.cricketRounds)")
                }
                StatTile(labelKey: "stats.doublePercent", value: String(format: "%.1f%%", stats.doublePercent))
                StatTile(labelKey: "stats.triplePercent", value: String(format: "%.1f%%", stats.triplePercent))
            }

            if isX01, stats.average3Dart > 0 {
                Text(L10n.statsThreeDartAverage)
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                PlayerAverageChart(average: stats.average3Dart, playerName: stats.name)
                if viewModel.x01TrendPoints.count >= 2 {
                    Text(L10n.statsTrendTitle)
                        .font(.headline)
                        .foregroundStyle(Brand.textPrimary)
                    AverageTrendChart(points: viewModel.x01TrendPoints)
                }
            }

            if !stats.hitsBySector.isEmpty {
                Text(L10n.statsHitsInSector)
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                SectorHitsChart(hitsBySector: stats.hitsBySector, mode: isX01 ? .x01 : .cricket)
            }
        }
        .padding(.bottom, DS.Spacing.s3)
    }
}

private struct StatTile: View {
    let labelKey: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s1) {
            Text(LocalizedStringKey(labelKey))
                .font(.caption)
                .foregroundStyle(Brand.textSecondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Brand.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.s3)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(statTileAccessibilityLabel)
    }

    private var statTileAccessibilityLabel: String {
        L10n.format("stats.statTile.accessibilityFormat", L10n.string(labelKey), value)
    }
}
