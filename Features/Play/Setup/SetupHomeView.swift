import SwiftUI

struct SetupHomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var rosterRowHeight: CGFloat = 52
    @ScaledMetric(relativeTo: .body) private var turnOrderRowVerticalInset: CGFloat = 8
    @ObservedObject var homeViewModel: PlayHomeViewModel
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @ObservedObject var pendingMatchPlayerSelections: PendingMatchPlayerSelections
    let onResumeMatch: (MatchSummary) -> Void
    let onStartRoute: (PlayRoute) -> Void
    let onQuickAddPlayer: () -> Void
    @State private var startTask: Task<Void, Never>?
    @State private var showsGameRules = false
    @State private var showsCustomBotSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                BrandRootScreenTitle(title: L10n.appTitle)
                    .padding(.top, DS.Spacing.s2)

                if case let .readyWithActiveMatch(match) = homeViewModel.state {
                    resumeBanner(match)
                }

                modeSelector
                learnToPlayButton
                if setupViewModel.mode == .x01 {
                    chipsGrid
                } else {
                    cricketChipsGrid
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
        .sheet(isPresented: $showsGameRules) {
            GameRulesGuideView(initialMode: setupViewModel.mode.matchType)
        }
        .sheet(isPresented: $showsCustomBotSheet) {
            CustomBotCreationSheet { name, metrics in
                startTask?.cancel()
                startTask = Task { await setupViewModel.addCustomBot(name: name, metrics: metrics) }
            }
        }
        .onDisappear { startTask?.cancel() }
    }

    private var learnToPlayButton: some View {
        Button { showsGameRules = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "book.pages")
                Text(L10n.gameRulesLearnButton)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(Brand.green)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.gameRulesLearnButton)
        .accessibilityHint(L10n.string("play.rules.learnButton.hint"))
        .accessibilityIdentifier("setup_learnToPlayButton")
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
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.sm).stroke(Brand.green, lineWidth: 2))
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

    private var modeSelector: some View {
        BrandSegmented(
            options: [
                (.x01, L10n.string("play.x01.title")),
                (.cricket, L10n.string("play.cricket.title"))
            ],
            selection: Binding(
                get: { setupViewModel.mode },
                set: { setupViewModel.updateMode($0) }
            ),
            accessibilityIdentifiers: [
                .x01: "setup_mode_x01",
                .cricket: "setup_mode_cricket"
            ]
        )
        .frame(maxWidth: .infinity)
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
                if !setupViewModel.availableTrainingBots.isEmpty {
                    Section(L10n.trainingBotSetupSection) {
                        ForEach(setupViewModel.availableTrainingBots) { bot in
                            Button {
                                setupViewModel.addTrainingBot(bot.id)
                            } label: {
                                Label {
                                    Text(bot.name)
                                } icon: {
                                    Circle()
                                        .fill(PlayerVisualViews.trainingBotColor(linkedToken: bot.colorToken))
                                        .frame(width: 10, height: 10)
                                }
                            }
                            .accessibilityIdentifier("training_bot_add_setup")
                        }
                    }
                }
                if !setupViewModel.availableCustomBots.isEmpty {
                    Section(L10n.customBotSetupSection) {
                        ForEach(setupViewModel.availableCustomBots) { bot in
                            Button {
                                setupViewModel.addTrainingBot(bot.id)
                            } label: {
                                Text(bot.name)
                            }
                        }
                    }
                }
                Section(L10n.addBotTitle) {
                    Button {
                        showsCustomBotSheet = true
                    } label: {
                        Label(L10n.customBotAddMenu, systemImage: "slider.horizontal.3")
                    }
                    ForEach(BotDifficulty.allCases, id: \.self) { difficulty in
                        botMenuButton(difficulty.displayName, difficulty: difficulty, color: PlayerVisualViews.botDifficultyColor(difficulty))
                    }
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
                .background(Brand.cardElevated, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.sm).stroke(Brand.textSecondary.opacity(0.35), lineWidth: 1))
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
                .background(Brand.green, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
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
                            .listRowInsets(
                                EdgeInsets(
                                    top: turnOrderRowVerticalInset,
                                    leading: 0,
                                    bottom: turnOrderRowVerticalInset,
                                    trailing: 0
                                )
                            )
                    }
                    .onDelete { offsets in
                        setupViewModel.removeSelectedPlayers(at: offsets)
                    }
                    .onMove { source, destination in
                        setupViewModel.moveSelectedPlayers(from: source, to: destination)
                    }
                }
                .listStyle(.plain)
                .listRowSpacing(0)
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
                PlayerRosterAvatar(
                    avatarStyle: player.avatarStyle,
                    colorToken: player.colorToken,
                    size: 28
                )
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
            if let difficulty = player.botDifficulty {
                BotDifficultyBadge(difficulty: difficulty, prominence: .compact)
            } else if player.isCustomBot, let metrics = player.customBotMetrics {
                CustomBotBadge(metrics: metrics, prominence: .compact)
            }
            Button {
                setupViewModel.removeFromSelection(player.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Brand.textSecondary)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityLabel(L10n.setupRemoveFromMatch)
            .accessibilityIdentifier("setup_remove_\(player.name)")
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
                    player: bot,
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
                    player: player,
                    accessibilityId: "select_\(player.name)"
                )
                Divider().overlay(Brand.cardElevated)
            }
        }
    }

    private func rosterRow(player: PlayerSummary, accessibilityId: String) -> some View {
        Button { setupViewModel.togglePlayer(player.id) } label: {
            HStack(spacing: DS.Spacing.s3) {
                PlayerRosterAvatar(
                    avatarStyle: player.avatarStyle,
                    colorToken: player.colorToken,
                    size: 28
                )
                Text(player.name)
                    .font(.headline)
                    .foregroundStyle(Brand.textSecondary)
                Spacer()
                if let difficulty = player.botDifficulty {
                    BotDifficultyBadge(difficulty: difficulty, prominence: .compact)
                } else if player.isCustomBot, let metrics = player.customBotMetrics {
                    CustomBotBadge(metrics: metrics, prominence: .compact)
                }
                Image(systemName: "plus.circle")
                    .foregroundStyle(Brand.green)
            }
            .frame(minHeight: 44)
            .padding(.vertical, DS.Spacing.s3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(nameAccessibilityLabel(for: player))
        .accessibilityHint(L10n.string("play.setup.playerRow.accessibilityHint"))
        .accessibilityIdentifier(accessibilityId)
    }

    private func nameAccessibilityLabel(for player: PlayerSummary) -> String {
        if let difficulty = player.botDifficulty {
            return L10n.format("players.bots.roster.accessibilityFormat", player.name, difficulty.displayName)
        }
        return player.name
    }

    private var turnOrderListHeight: CGFloat {
        let count = setupViewModel.selectedPlayers.count
        guard count > 0 else { return 0 }
        let contentHeight = max(rosterRowHeight, 44)
        let rowHeight = contentHeight + (turnOrderRowVerticalInset * 2)
        return CGFloat(count) * rowHeight
    }

    private var setupStickyShadowColor: Color {
        colorScheme == .light ? .black.opacity(0.08) : .black.opacity(0.25)
    }
}
