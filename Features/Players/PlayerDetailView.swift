import SwiftUI

struct PlayerDetailView: View {
    let player: EditablePlayer?
    let existingNames: [String]
    let dependencies: AppDependencies
    let onEdit: () -> Void
    let onArchiveToggle: () -> Void
    let onSave: (EditablePlayer) -> Void
    let onExportResult: (Result<URL, Error>) -> Void

    init(
        player: EditablePlayer?,
        existingNames: [String],
        dependencies: AppDependencies,
        onEdit: @escaping () -> Void,
        onArchiveToggle: @escaping () -> Void,
        onSave: @escaping (EditablePlayer) -> Void,
        onExportResult: @escaping (Result<URL, Error>) -> Void = { _ in }
    ) {
        self.player = player
        self.existingNames = existingNames
        self.dependencies = dependencies
        self.onEdit = onEdit
        self.onArchiveToggle = onArchiveToggle
        self.onSave = onSave
        self.onExportResult = onExportResult
    }

    var body: some View {
        Group {
            if let player {
                if player.isBot, player.isCustomBot {
                    CustomBotDetailView(
                        player: player,
                        existingNames: existingNames,
                        dependencies: dependencies,
                        onSave: onSave
                    )
                } else if player.isBot, player.botDifficulty != nil {
                    BotDetailView(
                        player: player,
                        difficulty: player.botDifficulty!,
                        existingNames: existingNames,
                        dependencies: dependencies,
                        onSave: onSave
                    )
                } else if player.isBot {
                    TrainingBotDetailView(
                        player: player,
                        existingNames: existingNames,
                        dependencies: dependencies,
                        onSave: onSave
                    )
                } else {
                    PlayerStatsDetailView(
                        player: player,
                        dependencies: dependencies,
                        onEdit: onEdit,
                        onArchiveToggle: onArchiveToggle,
                        onExportResult: onExportResult
                    )
                }
            } else {
                ContentUnavailableView(L10n.playerNotFound, systemImage: "person.crop.circle.badge.exclamationmark")
                    .brandScoreboardEmptyState()
            }
        }
        .navigationTitle(player?.isBot == true ? L10n.botDetailTitle : L10n.playerDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BotDetailView: View {
    let player: EditablePlayer
    let difficulty: BotDifficulty
    let existingNames: [String]
    let dependencies: AppDependencies
    let onSave: (EditablePlayer) -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @StateObject private var editViewModel: PlayerEditViewModel
    @StateObject private var statsViewModel: PlayerDetailViewModel

    init(
        player: EditablePlayer,
        difficulty: BotDifficulty,
        existingNames: [String],
        dependencies: AppDependencies,
        onSave: @escaping (EditablePlayer) -> Void
    ) {
        self.player = player
        self.difficulty = difficulty
        self.existingNames = existingNames
        self.dependencies = dependencies
        self.onSave = onSave
        _editViewModel = StateObject(wrappedValue: PlayerEditViewModel(existingNames: existingNames, editing: player))
        _statsViewModel = StateObject(wrappedValue: PlayerDetailViewModel(
            playerId: player.id,
            playerName: player.name,
            playerRepository: dependencies.playerRepository,
            matchRepository: dependencies.matchRepository,
            statsRepository: dependencies.statsRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                BotIdentityCard(
                    name: editViewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? player.name : editViewModel.name,
                    avatarStyle: editViewModel.avatarStyle,
                    colorToken: editViewModel.colorToken,
                    difficulty: difficulty,
                    notes: editViewModel.notes
                )

                BotDifficultyStatsSection(profile: difficulty.displayProfile)

                customizationSection

                PlayerDetailStatsContent(viewModel: statsViewModel)
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s6)
            .readableRootContentWidth(horizontalSizeClass)
        }
        .background(Brand.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.save) {
                    onSave(editViewModel.buildPlayer(from: player))
                }
                .disabled(!editViewModel.canSave)
                .accessibilityLabel(L10n.string("players.bots.save.accessibility"))
                .accessibilityIdentifier("botDetail_save")
            }
        }
        .task { await statsViewModel.load() }
    }

    private var customizationSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text(L10n.botCustomizationSection)
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)

            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                TextField("players.edit.name", text: $editViewModel.name)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(L10n.string("players.edit.name.accessibility"))
                    .accessibilityIdentifier("botDetail_name")
                    .onChange(of: editViewModel.name) { _, _ in editViewModel.validate() }

                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    Text(L10n.playersEditAvatar)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.textSecondary)
                    AvatarStylePicker(selection: $editViewModel.avatarStyle)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    Text(L10n.playersEditColor)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.textSecondary)
                    PlayerColorTokenPicker(selection: $editViewModel.colorToken)
                }

                TextField("players.edit.notes", text: $editViewModel.notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(L10n.string("players.edit.notes.accessibility"))

                if let message = editViewModel.validationMessage {
                    Text(message).foregroundStyle(.red).font(.footnote)
                }
            }
            .padding(DS.Spacing.s4)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        }
    }
}

private struct PlayerStatsDetailView: View {
    let player: EditablePlayer
    let dependencies: AppDependencies
    let onEdit: () -> Void
    let onArchiveToggle: () -> Void
    let onExportResult: (Result<URL, Error>) -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var viewModel: PlayerDetailViewModel

    init(
        player: EditablePlayer,
        dependencies: AppDependencies,
        onEdit: @escaping () -> Void,
        onArchiveToggle: @escaping () -> Void,
        onExportResult: @escaping (Result<URL, Error>) -> Void
    ) {
        self.player = player
        self.dependencies = dependencies
        self.onEdit = onEdit
        self.onArchiveToggle = onArchiveToggle
        self.onExportResult = onExportResult
        _viewModel = StateObject(wrappedValue: PlayerDetailViewModel(
            playerId: player.id,
            playerName: player.name,
            playerRepository: dependencies.playerRepository,
            matchRepository: dependencies.matchRepository,
            statsRepository: dependencies.statsRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                PlayerIdentityCard(player: player)
                TrainingPartnerSection(
                    humanPlayerId: player.id,
                    viewModel: viewModel,
                    playerColorToken: player.colorToken,
                    pendingSelections: dependencies.pendingMatchPlayerSelections
                )
                if player.isArchived {
                    Text(L10n.archived)
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                }

                PlayerDetailStatsContent(viewModel: viewModel)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.s3) {
                        Button(L10n.edit, action: onEdit)
                            .buttonStyle(.bordered)
                            .tint(Brand.green)
                            .accessibilityLabel(L10n.string("players.detail.edit.accessibility"))
                            .accessibilityIdentifier("playerDetail_edit")
                        Button(player.isArchived ? "players.unarchive" : "players.archive", action: onArchiveToggle)
                            .buttonStyle(.bordered)
                            .tint(Brand.orange)
                            .accessibilityLabel(
                                L10n.string(player.isArchived ? "players.detail.unarchive.accessibility" : "players.detail.archive.accessibility")
                            )
                            .accessibilityIdentifier("playerDetail_archive")
                        Button(L10n.playersDetailExport, action: exportPlayer)
                            .buttonStyle(.bordered)
                            .tint(Brand.textSecondary)
                            .disabled(viewModel.isExporting)
                            .accessibilityLabel(L10n.string("players.detail.export.accessibility"))
                            .accessibilityIdentifier("playerDetail_export")
                    }
                }
                .padding(.top, DS.Spacing.s2)
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s6)
            .readableRootContentWidth(horizontalSizeClass)
        }
        .background(Brand.background.ignoresSafeArea())
        .overlay {
            if viewModel.isExporting {
                ProgressView()
                    .tint(Brand.textPrimary)
                    .padding(DS.Spacing.s4)
                    .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
            }
        }
        .task { await viewModel.load() }
    }

    private func exportPlayer() {
        Task {
            do {
                let url = try await viewModel.exportBundle(playerName: player.name)
                onExportResult(.success(url))
            } catch {
                onExportResult(.failure(error))
            }
        }
    }
}

struct PlayerDetailStatsContent: View {
    @ObservedObject var viewModel: PlayerDetailViewModel

    var body: some View {
        Group {
            if let lastPlayedText = viewModel.lastPlayedText {
                Text(lastPlayedText)
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
            }

            if viewModel.isLoading {
                ProgressView().tint(Brand.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.s6)
                    .accessibilityLabel(L10n.loading)
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
        }
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

private struct TrainingPartnerSection: View {
    let humanPlayerId: UUID
    @ObservedObject var viewModel: PlayerDetailViewModel
    let playerColorToken: PlayerColorToken
    let pendingSelections: PendingMatchPlayerSelections

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text(L10n.trainingBotSectionTitle)
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)

            if let bot = viewModel.trainingBot {
                Text(bot.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)

                if let x01Summary = viewModel.calibratedSummary(for: .x01) {
                    Text(x01Summary).font(.footnote).foregroundStyle(Brand.textSecondary)
                }
                if let cricketSummary = viewModel.calibratedSummary(for: .cricket) {
                    Text(cricketSummary).font(.footnote).foregroundStyle(Brand.textSecondary)
                }

                HStack(spacing: DS.Spacing.s2) {
                    practiceButton(mode: .x01, title: L10n.x01Title)
                    practiceButton(mode: .cricket, title: L10n.cricketTitle)
                }
            } else {
                eligibilityRows
                Button {
                    Task { await viewModel.createTrainingBot() }
                } label: {
                    Text(L10n.trainingBotCreate)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Brand.green)
                .disabled(!canCreate || viewModel.isCreatingTrainingBot)
                .accessibilityIdentifier("training_bot_create")
            }

            if let errorKey = viewModel.trainingBotErrorKey {
                Text(L10n.string(errorKey)).font(.footnote).foregroundStyle(.red)
            }
        }
        .padding(DS.Spacing.s4)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private var canCreate: Bool {
        viewModel.x01Eligibility.isEligible || viewModel.cricketEligibility.isEligible
    }

    @ViewBuilder
    private var eligibilityRows: some View {
        if !viewModel.x01Eligibility.isEligible {
            eligibilityChip(viewModel.x01Eligibility, modeLabel: L10n.string("play.x01.title"))
        }
        if !viewModel.cricketEligibility.isEligible {
            eligibilityChip(viewModel.cricketEligibility, modeLabel: L10n.string("play.cricket.title"))
        }
    }

    private func eligibilityChip(_ eligibility: TrainingBotEligibility, modeLabel: String) -> some View {
        Text(L10n.format(
            "trainingBot.eligibility.progressFormat",
            eligibility.gamesPlayed,
            eligibility.requiredGames,
            modeLabel
        ))
        .font(.footnote)
        .foregroundStyle(Brand.textSecondary)
        .accessibilityIdentifier("training_bot_eligibility_progress")
    }

    private func practiceButton(mode: MatchType, title: LocalizedStringKey) -> some View {
        Button {
            guard let bot = viewModel.trainingBot else { return }
            pendingSelections.enqueuePractice(humanId: humanPlayerId, trainingBotId: bot.id, mode: mode)
        } label: {
            Text(title).font(.caption.weight(.semibold))
        }
        .buttonStyle(.bordered)
        .tint(PlayerVisualViews.trainingBotColor(linkedToken: playerColorToken))
        .disabled(viewModel.trainingBot == nil || !(mode == .x01 ? viewModel.x01Eligibility : viewModel.cricketEligibility).isEligible)
    }
}

struct TrainingBotDetailView: View {
    let player: EditablePlayer
    let existingNames: [String]
    let dependencies: AppDependencies
    let onSave: (EditablePlayer) -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @StateObject private var editViewModel: PlayerEditViewModel
    @StateObject private var statsViewModel: PlayerDetailViewModel

    init(
        player: EditablePlayer,
        existingNames: [String],
        dependencies: AppDependencies,
        onSave: @escaping (EditablePlayer) -> Void
    ) {
        self.player = player
        self.existingNames = existingNames
        self.dependencies = dependencies
        self.onSave = onSave
        _editViewModel = StateObject(wrappedValue: PlayerEditViewModel(existingNames: existingNames, editing: player))
        _statsViewModel = StateObject(wrappedValue: PlayerDetailViewModel(
            playerId: player.id,
            playerName: player.name,
            playerRepository: dependencies.playerRepository,
            matchRepository: dependencies.matchRepository,
            statsRepository: dependencies.statsRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                BotIdentityCard(
                    name: editViewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? player.name : editViewModel.name,
                    avatarStyle: editViewModel.avatarStyle,
                    colorToken: editViewModel.colorToken,
                    difficulty: nil,
                    notes: editViewModel.notes
                )

                if let profile = resolvedProfile {
                    BotDifficultyStatsSection(profile: profile.displayProfile)
                    Text(L10n.format("trainingBot.calibrated.footer", linkedPlayerName))
                        .font(.footnote)
                        .foregroundStyle(Brand.textSecondary)
                }

                customizationSection
                PlayerDetailStatsContent(viewModel: statsViewModel)
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s6)
            .readableRootContentWidth(horizontalSizeClass)
        }
        .background(Brand.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.save) {
                    onSave(editViewModel.buildPlayer(from: player))
                }
                .disabled(!editViewModel.canSave)
            }
        }
        .task { await statsViewModel.load() }
    }

    private var linkedPlayerName: String {
        player.name.replacingOccurrences(of: "'s Training Partner", with: "")
    }

    private var resolvedProfile: BotSkillProfile? {
        guard player.linkedPlayerId != nil else { return nil }
        let breakdown = statsViewModel.x01 ?? statsViewModel.cricket
        guard let breakdown else { return BotDifficulty.easy.skillProfile }
        return TrainingBotSkillResolver.resolve(breakdown: breakdown, mode: .x01)
    }

    private var customizationSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text(L10n.botCustomizationSection)
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
            TextField("players.edit.name", text: $editViewModel.name)
                .textFieldStyle(.roundedBorder)
        }
        .padding(DS.Spacing.s4)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }
}
