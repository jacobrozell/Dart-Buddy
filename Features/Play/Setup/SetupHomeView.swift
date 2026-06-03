import SwiftUI

struct SetupHomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var rosterRowHeight: CGFloat = 52
    @ObservedObject var homeViewModel: PlayHomeViewModel
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @ObservedObject var pendingMatchPlayerSelections: PendingMatchPlayerSelections
    let onResumeMatch: (MatchSummary) -> Void
    let onStartRoute: (PlayRoute) -> Void
    let onQuickAddPlayer: () -> Void
    let onViewCompletedMatch: (UUID) -> Void
    @State private var startTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                Text(L10n.appTitle)
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(Brand.textPrimary)
                    .padding(.top, DS.Spacing.s2)

                if case let .readyWithActiveMatch(match) = homeViewModel.state {
                    resumeBanner(match)
                }

                if !homeViewModel.recentCompletedMatches.isEmpty {
                    recentCompletedSection
                }

                modePill
                if setupViewModel.mode == .x01 {
                    chipsGrid
                }
                rosterControls
                if GameplayLayout.usesAccessibilitySetupHomeLayout(dynamicTypeSize: dynamicTypeSize),
                   !setupViewModel.displayValidationErrors.isEmpty {
                    setupInlineValidationHints
                }
                selectedRosterSection
                availablePlayerList
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s4)
            .frame(maxWidth: GameplayLayout.contentMaxWidth(horizontalSizeClass: horizontalSizeClass))
            .frame(maxWidth: .infinity)
        }
        .background(Brand.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            startButton
                .padding(.horizontal, DS.Spacing.s4)
                .padding(.top, DS.Spacing.s3)
                .padding(.bottom, DS.Spacing.s2)
                .background {
                    Brand.background
                        .shadow(color: setupStickyShadowColor, radius: 10, y: -4)
                        .ignoresSafeArea(edges: .bottom)
                }
        }
        .onChange(of: pendingMatchPlayerSelections.changeCount) { _, _ in
            Task { await setupViewModel.onAppear() }
        }
        .alert("play.setup.activeConflict.title", isPresented: $setupViewModel.showActiveMatchConflict) {
            Button("common.cancel", role: .cancel) {}
            Button("play.setup.activeConflict.confirm", role: .destructive) {
                startTask?.cancel()
                startTask = Task {
                    if let route = await setupViewModel.confirmReplaceActiveMatch() {
                        onStartRoute(route)
                    }
                }
            }
        } message: {
            Text("play.setup.activeConflict.message")
        }
        .onDisappear { startTask?.cancel() }
    }

    private func resumeBanner(_ match: MatchSummary) -> some View {
        Button { onResumeMatch(match) } label: {
            HStack {
                Image(systemName: "play.circle.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.resumeMatch).font(.headline)
                    Text(MatchConfigText.modeLabel(for: match.type)).font(.caption).foregroundStyle(Brand.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Brand.textSecondary)
            }
            .foregroundStyle(Brand.textPrimary)
            .padding(DS.Spacing.s4)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.md).stroke(Brand.green, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            L10n.format(
                "play.home.resumeAccessibilityFormat",
                L10n.string("play.home.resumeButton"),
                match.type == .x01 ? L10n.string("play.x01.title") : L10n.string("play.cricket.title")
            )
        )
        .accessibilityIdentifier("resumeMatchButton")
    }

    private var recentCompletedSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text(L10n.recentGames)
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)

            VStack(spacing: 0) {
                ForEach(homeViewModel.recentCompletedMatches) { match in
                    Button { onViewCompletedMatch(match.id) } label: {
                        HStack(spacing: DS.Spacing.s3) {
                            Text(match.type == .x01 ? L10n.x01Title : L10n.cricketTitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Brand.textSecondary)
                                .frame(width: 56, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(match.participantsLabel)
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.textPrimary)
                                    .lineLimit(1)
                                if let winnerName = match.winnerName {
                                    Text(L10n.format("play.home.recentWinnerFormat", winnerName))
                                        .font(.caption)
                                        .foregroundStyle(Brand.textSecondary)
                                }
                            }
                            Spacer()
                            Text(match.playedAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(Brand.textSecondary)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Brand.textSecondary)
                        }
                        .padding(.horizontal, DS.Spacing.s3)
                        .padding(.vertical, DS.Spacing.s3)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(recentMatchAccessibilityLabel(match))
                    if match.id != homeViewModel.recentCompletedMatches.last?.id {
                        Divider().overlay(Brand.cardElevated)
                    }
                }
            }
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        }
    }

    private var modePill: some View {
        HStack(spacing: 0) {
            modeButton(L10n.x01Title, mode: .x01)
            modeButton(L10n.cricketTitle, mode: .cricket)
        }
        .padding(4)
        .background(Brand.card, in: Capsule())
        .frame(maxWidth: .infinity)
    }

    private func modeButton(_ title: LocalizedStringKey, mode: MatchSetupViewModel.SetupMode) -> some View {
        let isSelected = setupViewModel.mode == mode
        return Button { setupViewModel.updateMode(mode) } label: {
            Text(title)
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.vertical, DS.Spacing.s2)
                .background(isSelected ? Brand.cardElevated : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.format("play.setup.mode.accessibilityFormat", L10n.string(mode == .x01 ? "play.x01.title" : "play.cricket.title")))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(mode == .x01 ? "setup_mode_x01" : "setup_mode_cricket")
    }

    private var startButton: some View {
        VStack(spacing: 6) {
            PrimaryActionButton(
                title: setupViewModel.isSubmitting ? L10n.setupStartingButton : L10n.setupStartButton,
                isEnabled: setupViewModel.canStart && !setupViewModel.isSubmitting
            ) {
                startTask?.cancel()
                startTask = Task {
                    if let route = await setupViewModel.startMatchRoute() {
                        onStartRoute(route)
                    }
                }
            }
            .accessibilityLabel(L10n.string(setupViewModel.isSubmitting ? "play.setup.startingButton" : "play.setup.startButton"))
            .modifier(OptionalAccessibilityHint(hint: setupStartAccessibilityHint))
            .accessibilityIdentifier("startMatchButton")

            if !GameplayLayout.usesAccessibilitySetupHomeLayout(dynamicTypeSize: dynamicTypeSize) {
                ForEach(setupViewModel.displayValidationErrors, id: \.self) { key in
                    ErrorBanner(messageKey: key)
                }
            }
        }
    }

    private var setupInlineValidationHints: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            ForEach(setupViewModel.displayValidationErrors, id: \.self) { key in
                SetupValidationHint(messageKey: key)
            }
        }
        .accessibilityIdentifier("setupValidationHints")
    }

    private var setupStartAccessibilityHint: String? {
        guard !setupViewModel.canStart else { return nil }
        if setupViewModel.isRosterEmpty {
            return L10n.string("play.setup.playersEmptyHint")
        }
        return SetupValidationMessages.startButtonAccessibilityHint(
            canStart: setupViewModel.canStart,
            validationErrors: setupViewModel.validationErrors
        )
    }

    private var rosterControls: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                    randomOrderToggle
                    rosterActionButtons
                }
            } else {
                HStack {
                    randomOrderToggle
                    Spacer()
                    rosterActionButtons
                }
            }
        }
        .padding(.top, DS.Spacing.s2)
    }

    private var randomOrderToggle: some View {
        Button { setupViewModel.randomOrder.toggle() } label: {
            HStack(spacing: 8) {
                Image(systemName: setupViewModel.randomOrder ? "checkmark.square.fill" : "square")
                    .foregroundStyle(setupViewModel.randomOrder ? Brand.green : Brand.textSecondary)
                Text(L10n.setupRandomOrder).foregroundStyle(Brand.textPrimary)
            }
            .frame(minHeight: 44, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.setupRandomOrder)
        .accessibilityAddTraits(setupViewModel.randomOrder ? .isSelected : [])
    }

    private var rosterActionButtons: some View {
        HStack(spacing: DS.Spacing.s2) {
            Menu {
                ForEach(BotDifficulty.allCases, id: \.self) { difficulty in
                    botMenuButton(difficulty.displayName, difficulty: difficulty, color: botDifficultyColor(difficulty))
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "cpu")
                    Text(L10n.addBotTitle).font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Brand.textPrimary)
                .padding(.horizontal, DS.Spacing.s3)
                .padding(.vertical, DS.Spacing.s3)
                .frame(minHeight: 44)
                .background(Brand.cardElevated, in: Capsule())
                .overlay(Capsule().stroke(Brand.textSecondary.opacity(0.35), lineWidth: 1))
            }
            .accessibilityLabel(L10n.addBotTitle)
            Button { onQuickAddPlayer() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.badge.plus")
                    Text(L10n.setupAddPlayers).font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Brand.textPrimary)
                .padding(.horizontal, DS.Spacing.s3)
                .padding(.vertical, DS.Spacing.s2)
                .background(Brand.green, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.setupAddPlayers)
        }
    }

    private func botMenuButton(_ title: String, difficulty: BotDifficulty, color: Color) -> some View {
        Button {
            startTask?.cancel()
            startTask = Task { await setupViewModel.addBot(difficulty) }
        } label: {
            Label {
                Text(title)
            } icon: {
                Circle().fill(color).frame(width: 10, height: 10)
            }
        }
        .accessibilityIdentifier("add_bot_\(difficulty.rawValue)")
    }

    @ViewBuilder
    private var selectedRosterSection: some View {
        if !setupViewModel.selectedPlayers.isEmpty {
            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                Text(L10n.setupTurnOrder)
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                if setupViewModel.randomOrder {
                    Text(L10n.setupTurnOrderRandomHint)
                        .font(.footnote)
                        .foregroundStyle(Brand.textSecondary)
                }
                List {
                    ForEach(Array(setupViewModel.selectedPlayers.enumerated()), id: \.element.id) { index, player in
                        selectedRosterRow(player: player, position: index + 1)
                            .listRowBackground(Brand.card)
                            .listRowSeparatorTint(Brand.cardElevated)
                    }
                    .onDelete { offsets in
                        setupViewModel.removeSelectedPlayers(at: offsets)
                    }
                    .onMove { source, destination in
                        setupViewModel.moveSelectedPlayers(from: source, to: destination)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                .environment(
                    \.editMode,
                    .constant(
                        GameplayLayout.usesAccessibilitySetupHomeLayout(dynamicTypeSize: dynamicTypeSize)
                            ? .inactive
                            : .active
                    )
                )
                .frame(height: turnOrderListHeight)
                .accessibilityIdentifier("setup_turnOrderList")
            }
        }
    }

    @ViewBuilder
    private var availablePlayerList: some View {
        if setupViewModel.isRosterEmpty {
            Text(L10n.setupPlayersEmptyHint)
                .font(.footnote)
                .foregroundStyle(Brand.textSecondary)
        } else if !setupViewModel.availableHumans.isEmpty || !setupViewModel.availableBots.isEmpty {
            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                if !setupViewModel.availableBots.isEmpty {
                    Text(L10n.botsSectionTitle).font(.headline).foregroundStyle(Brand.textPrimary)
                    botRosterList
                }
                if !setupViewModel.availableHumans.isEmpty {
                    Text(L10n.addToMatchSection)
                        .font(.headline)
                        .foregroundStyle(Brand.textPrimary)
                    humanRosterList
                }
            }
        }
    }

    private func selectedRosterRow(player: PlayerSummary, position: Int) -> some View {
        HStack(spacing: DS.Spacing.s3) {
            HStack(spacing: DS.Spacing.s3) {
                Text(L10n.format("common.playerOrdinal", position))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Brand.textSecondary)
                    .frame(width: 28, alignment: .leading)
                if player.isBot, let difficulty = player.botDifficulty {
                    Image(systemName: "cpu.fill")
                        .foregroundStyle(botDifficultyColor(difficulty))
                } else {
                    Image(systemName: "location.north.fill")
                        .rotationEffect(.degrees(135))
                        .foregroundStyle(Brand.textSecondary)
                }
                Text(player.name)
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                L10n.format("play.setup.turnOrder.rowAccessibilityFormat", position, player.name)
            )
            .accessibilityIdentifier("setup_selected_\(player.name)")
            Spacer()
            if GameplayLayout.usesAccessibilitySetupHomeLayout(dynamicTypeSize: dynamicTypeSize) {
                Button {
                    setupViewModel.removeFromSelection(player.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Brand.textSecondary)
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel(L10n.setupRemoveFromMatch)
                .accessibilityIdentifier("setup_remove_\(player.name)")
            }
        }
        .accessibilityAction(named: Text(L10n.setupRemoveFromMatch)) {
            setupViewModel.removeFromSelection(player.id)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                setupViewModel.removeFromSelection(player.id)
            } label: {
                Text(L10n.setupRemoveFromMatch)
            }
            .accessibilityLabel(L10n.setupRemoveFromMatch)
            .accessibilityIdentifier("setup_remove_\(player.name)")
        }
    }

    private var botRosterList: some View {
        VStack(spacing: 0) {
            ForEach(setupViewModel.availableBots) { bot in
                rosterRow(
                    id: bot.id,
                    name: bot.name,
                    difficulty: bot.botDifficulty,
                    accessibilityId: "select_bot_\(bot.botDifficultyRaw ?? "unknown")"
                )
                Divider().overlay(Brand.cardElevated)
            }
        }
    }

    private var humanRosterList: some View {
        VStack(spacing: 0) {
            ForEach(setupViewModel.availableHumans) { player in
                rosterRow(
                    id: player.id,
                    name: player.name,
                    difficulty: nil,
                    accessibilityId: "select_\(player.name)"
                )
                Divider().overlay(Brand.cardElevated)
            }
        }
    }

    private func rosterRow(id: UUID, name: String, difficulty: BotDifficulty?, accessibilityId: String) -> some View {
        Button { setupViewModel.togglePlayer(id) } label: {
            HStack(spacing: DS.Spacing.s3) {
                if let difficulty {
                    Image(systemName: "cpu.fill")
                        .foregroundStyle(botDifficultyColor(difficulty))
                } else {
                    Image(systemName: "location.north.fill")
                        .rotationEffect(.degrees(135))
                        .foregroundStyle(Brand.textSecondary)
                }
                Text(name)
                    .font(.headline)
                    .foregroundStyle(Brand.textSecondary)
                Spacer()
                Image(systemName: "plus.circle")
                    .foregroundStyle(Brand.green)
            }
            .padding(.vertical, DS.Spacing.s3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityHint(L10n.string("play.setup.playerRow.accessibilityHint"))
        .accessibilityIdentifier(accessibilityId)
    }

    private func recentMatchAccessibilityLabel(_ match: CompletedMatchPreview) -> String {
        let mode = match.type == .x01 ? L10n.string("play.x01.title") : L10n.string("play.cricket.title")
        let winner = match.winnerName.map { L10n.format("play.home.recentWinnerFormat", $0) } ?? ""
        return L10n.format("play.home.recentMatchAccessibilityFormat", mode, match.participantsLabel, winner)
    }

    private var turnOrderListHeight: CGFloat {
        CGFloat(setupViewModel.selectedPlayers.count) * rosterRowHeight
    }

    private func botDifficultyColor(_ difficulty: BotDifficulty) -> Color {
        switch difficulty {
        case .veryEasy: Color(red: 0.45, green: 0.82, blue: 0.55)
        case .easy: Brand.green
        case .medium: Brand.amber
        case .hard: Brand.red
        case .pro: Brand.proBot
        }
    }

    private var setupStickyShadowColor: Color {
        colorScheme == .light ? .black.opacity(0.08) : .black.opacity(0.25)
    }
}
