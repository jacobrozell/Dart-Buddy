import SwiftUI

struct SetupHomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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
                    .foregroundStyle(.white)
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
                        .shadow(color: .black.opacity(0.25), radius: 10, y: -4)
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
            .foregroundStyle(.white)
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
                .foregroundStyle(.white)

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
                                    .foregroundStyle(.white)
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
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.s2)
                .background(isSelected ? Brand.cardElevated : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.format("play.setup.mode.accessibilityFormat", L10n.string(mode == .x01 ? "play.x01.title" : "play.cricket.title")))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(mode == .x01 ? "setup_mode_x01" : "setup_mode_cricket")
    }

    private var chipsGrid: some View {
        VStack(spacing: DS.Spacing.s3) {
            HStack(spacing: DS.Spacing.s3) {
                pointsChip
                checkoutChip
                setsChip
            }
            HStack(spacing: DS.Spacing.s3) {
                legFormatChip
                checkInChip
                legsChip
            }
        }
    }

    private var pointsChip: some View {
        chip(title: L10n.setupChipPoints, color: Brand.green) {
            Menu {
                ForEach(X01StartScores.all, id: \.self) { score in
                    Button("\(score)") {
                        setupViewModel.x01StartScore = score
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox("\(setupViewModel.x01StartScore)", color: Brand.green, showsMenuIndicator: true)
            }
            .accessibilityLabel(chipAccessibilityLabel("play.setup.chip.points", "\(setupViewModel.x01StartScore)"))
            .accessibilityIdentifier("setup_startScoreChip")
        }
    }

    private var checkoutChip: some View {
        chip(title: L10n.setupChipCheckOut, color: Brand.red) {
            Menu {
                ForEach(X01CheckoutMode.allCases, id: \.rawValue) { value in
                    Button(value.displayName) {
                        setupViewModel.x01CheckoutMode = value
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(setupViewModel.x01CheckoutMode.displayName, color: Brand.red, showsMenuIndicator: true)
            }
            .accessibilityLabel(chipAccessibilityLabel("play.setup.chip.checkOut", setupViewModel.x01CheckoutMode.displayName))
            .accessibilityIdentifier("setup_checkoutChip")
        }
    }

    private var checkInChip: some View {
        chip(title: L10n.setupChipCheckIn, color: Brand.red) {
            Menu {
                ForEach(X01CheckInMode.allCases, id: \.rawValue) { value in
                    Button(value.displayName) {
                        setupViewModel.x01CheckInMode = value
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(setupViewModel.x01CheckInMode.displayName, color: Brand.red, showsMenuIndicator: true)
            }
            .accessibilityLabel(chipAccessibilityLabel("play.setup.chip.checkIn", setupViewModel.x01CheckInMode.displayName))
            .accessibilityIdentifier("setup_checkInChip")
        }
    }

    private var legFormatChip: some View {
        chip(title: L10n.setupChipSetLeg, color: Brand.green) {
            Menu {
                ForEach(X01LegFormat.allCases, id: \.rawValue) { value in
                    Button(value.displayName) {
                        setupViewModel.x01LegFormat = value
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(setupViewModel.x01LegFormat.displayName, color: Brand.green, showsMenuIndicator: true)
            }
            .accessibilityLabel(chipAccessibilityLabel("play.setup.chip.setLeg", setupViewModel.x01LegFormat.displayName))
            .accessibilityIdentifier("setup_setLegChip")
        }
    }

    private var setsChip: some View {
        chip(title: L10n.setupChipSets, color: Brand.green) {
            Menu {
                ForEach(1 ... 5, id: \.self) { value in
                    Button("\(value)") {
                        setupViewModel.x01SetsToWin = value
                        setupViewModel.x01SetsEnabled = value > 1
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox("\(setupViewModel.x01SetsEnabled ? setupViewModel.x01SetsToWin : 1)", color: Brand.green, showsMenuIndicator: true)
            }
            .accessibilityLabel(chipAccessibilityLabel("play.setup.chip.sets", "\(setupViewModel.x01SetsEnabled ? setupViewModel.x01SetsToWin : 1)"))
            .accessibilityIdentifier("setup_setsChip")
        }
    }

    private var legsChip: some View {
        chip(title: L10n.setupChipLegs, color: Brand.green) {
            Menu {
                ForEach(1 ... 9, id: \.self) { value in
                    Button("\(value)") {
                        setupViewModel.x01LegsToWin = value
                        setupViewModel.revalidate()
                    }
                    .accessibilityIdentifier("setup_legsOption_\(value)")
                }
            } label: {
                chipBox("\(setupViewModel.x01LegsToWin)", color: Brand.green, showsMenuIndicator: true)
            }
            .accessibilityLabel(chipAccessibilityLabel("play.setup.chip.legs", "\(setupViewModel.x01LegsToWin)"))
            .accessibilityIdentifier("setup_legsChip")
        }
    }

    private func chip<Content: View>(title: LocalizedStringKey, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 6) {
            Text(title).font(.caption).foregroundStyle(Brand.textSecondary)
            content()
        }
        .frame(maxWidth: .infinity)
    }

    private func chipBox(_ text: String, color: Color, showsMenuIndicator: Bool = false) -> some View {
        Text(text)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, 4)
            .background(color, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
            .overlay(alignment: .topTrailing) {
                if showsMenuIndicator {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(5)
                }
            }
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
            .modifier(OptionalAccessibilityHint(hint: setupViewModel.canStart ? nil : L10n.string("play.setup.start.disabledHint")))
            .accessibilityIdentifier("startMatchButton")

            ForEach(setupViewModel.validationErrors, id: \.self) { key in
                ErrorBanner(messageKey: key)
            }
        }
    }

    private var rosterControls: some View {
        HStack {
            Button { setupViewModel.randomOrder.toggle() } label: {
                HStack(spacing: 8) {
                    Image(systemName: setupViewModel.randomOrder ? "checkmark.square.fill" : "square")
                        .foregroundStyle(setupViewModel.randomOrder ? Brand.green : Brand.textSecondary)
                    Text(L10n.setupRandomOrder).foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.setupRandomOrder)
            .accessibilityAddTraits(setupViewModel.randomOrder ? .isSelected : [])
            Spacer()
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
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.Spacing.s3)
                    .padding(.vertical, DS.Spacing.s2)
                    .background(Brand.cardElevated, in: Capsule())
                    .overlay(Capsule().stroke(Brand.textSecondary.opacity(0.35), lineWidth: 1))
                }
                .accessibilityLabel(L10n.addBotTitle)
                Button { onQuickAddPlayer() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                        Text(L10n.setupAddPlayers).font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.Spacing.s3)
                    .padding(.vertical, DS.Spacing.s2)
                    .background(Brand.green, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.setupAddPlayers)
            }
        }
        .padding(.top, DS.Spacing.s2)
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
                    .foregroundStyle(.white)
                if setupViewModel.randomOrder {
                    Text(L10n.setupTurnOrderRandomHint)
                        .font(.footnote)
                        .foregroundStyle(Brand.textSecondary)
                }
                List {
                    ForEach(Array(setupViewModel.selectedPlayers.enumerated()), id: \.element.id) { index, player in
                        selectedRosterRow(player: player, position: index + 1)
                            .deleteDisabled(true)
                            .listRowBackground(Brand.card)
                            .listRowSeparatorTint(Brand.cardElevated)
                    }
                    .onMove { source, destination in
                        setupViewModel.moveSelectedPlayers(from: source, to: destination)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                .environment(\.editMode, .constant(setupViewModel.randomOrder ? .inactive : .active))
                .frame(height: CGFloat(setupViewModel.selectedPlayers.count) * 52)
                .accessibilityIdentifier("setup_turnOrderList")
            }
        }
    }

    @ViewBuilder
    private var availablePlayerList: some View {
        if setupViewModel.availableHumans.isEmpty
            && setupViewModel.availableBots.isEmpty
            && setupViewModel.selectedPlayers.isEmpty {
            Text(L10n.setupMinimumRosterHint)
                .font(.footnote)
                .foregroundStyle(Brand.textSecondary)
        } else if !setupViewModel.availableHumans.isEmpty || !setupViewModel.availableBots.isEmpty {
            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                if !setupViewModel.availableBots.isEmpty {
                    Text(L10n.botsSectionTitle).font(.headline).foregroundStyle(.white)
                    botRosterList
                }
                if !setupViewModel.availableHumans.isEmpty {
                    Text(L10n.addToMatchSection)
                        .font(.headline)
                        .foregroundStyle(.white)
                    humanRosterList
                }
            }
        }
    }

    private func selectedRosterRow(player: PlayerSummary, position: Int) -> some View {
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
                .foregroundStyle(.white)
            Spacer()
        }
        .accessibilityLabel(
            L10n.format("play.setup.turnOrder.rowAccessibilityFormat", position, player.name)
        )
        .accessibilityIdentifier("setup_selected_\(player.name)")
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                setupViewModel.removeFromSelection(player.id)
            } label: {
                Text(L10n.setupRemoveFromMatch)
            }
            .accessibilityLabel(L10n.setupRemoveFromMatch)
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

    private func chipAccessibilityLabel(_ titleKey: String, _ value: String) -> String {
        L10n.format("play.setup.chip.accessibilityFormat", L10n.string(titleKey), value)
    }

    private func recentMatchAccessibilityLabel(_ match: CompletedMatchPreview) -> String {
        let mode = match.type == .x01 ? L10n.string("play.x01.title") : L10n.string("play.cricket.title")
        let winner = match.winnerName.map { L10n.format("play.home.recentWinnerFormat", $0) } ?? ""
        return L10n.format("play.home.recentMatchAccessibilityFormat", mode, match.participantsLabel, winner)
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
}
