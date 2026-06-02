import SwiftUI

struct PlayRootView: View {
    let dependencies: AppDependencies
    @State private var path: [PlayRoute] = []
    @State private var hasAppliedSnapshotRoute = false
    @StateObject private var viewModel: PlayHomeViewModel
    @StateObject private var setupViewModel: MatchSetupViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(
            wrappedValue: PlayHomeViewModel(
                playerRepository: dependencies.playerRepository,
                matchRepository: dependencies.matchRepository,
                logger: dependencies.logger
            )
        )
        _setupViewModel = StateObject(
            wrappedValue: MatchSetupViewModel(
                playerRepository: dependencies.playerRepository,
                settingsRepository: dependencies.settingsRepository,
                matchRepository: dependencies.matchRepository,
                activeMatchStore: dependencies.activeMatchStore,
                pendingMatchPlayerSelections: dependencies.pendingMatchPlayerSelections
            )
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            SetupHomeView(
                homeViewModel: viewModel,
                setupViewModel: setupViewModel,
                pendingMatchPlayerSelections: dependencies.pendingMatchPlayerSelections,
                onResumeMatch: { match in
                    path.append(match.type == .x01 ? .x01Match(matchId: match.id) : .cricketMatch(matchId: match.id))
                },
                onStartRoute: { next in path.append(next) },
                onQuickAddPlayer: { path.append(.quickAddPlayer) }
            )
            .navigationDestination(for: PlayRoute.self) { route in
                switch route {
                case .setup:
                    EmptyView()
                case let .x01Match(matchId):
                    X01MatchScreen(
                        viewModel: X01MatchViewModel(
                            matchId: matchId,
                            store: dependencies.activeMatchStore,
                            logger: dependencies.logger,
                            matchRepository: dependencies.matchRepository,
                            statsRepository: dependencies.statsRepository
                        ),
                        onShowSummary: { path.append(.matchSummary(matchId: matchId)) },
                        audio: dependencies.audioFeedbackService,
                        haptics: dependencies.hapticsService
                    )
                case let .cricketMatch(matchId):
                    CricketMatchScreen(
                        viewModel: CricketMatchViewModel(
                            matchId: matchId,
                            store: dependencies.activeMatchStore,
                            logger: dependencies.logger,
                            matchRepository: dependencies.matchRepository,
                            statsRepository: dependencies.statsRepository
                        ),
                        onShowSummary: { path.append(.matchSummary(matchId: matchId)) },
                        audio: dependencies.audioFeedbackService,
                        haptics: dependencies.hapticsService
                    )
                case let .matchSummary(matchId):
                    MatchSummaryScreen(
                        viewModel: MatchSummaryViewModel(
                            matchId: matchId,
                            store: dependencies.activeMatchStore
                        ),
                        onStartNewMatch: { path.removeAll() },
                        onViewHistoryDetail: { id in path.append(.historyDetail(matchId: id)) }
                    )
                case let .historyDetail(matchId):
                    MatchHistoryDetailScreen(
                        viewModel: HistoryDetailViewModel(
                            matchId: matchId,
                            matchRepository: dependencies.matchRepository,
                            statsRepository: dependencies.statsRepository
                        ),
                        matchId: matchId
                    )
                case .quickAddPlayer:
                    QuickAddPlayerScreen(repository: dependencies.playerRepository) { created in
                        dependencies.pendingMatchPlayerSelections.enqueueForNextMatchSetup(created.id)
                        await setupViewModel.onAppear()
                    }
                }
            }
            .task {
                await viewModel.onAppear()
                await setupViewModel.onAppear()
                if hasAppliedSnapshotRoute == false {
                    hasAppliedSnapshotRoute = true
                    if ProcessInfo.processInfo.arguments.contains("-open_active_match"),
                       case let .readyWithActiveMatch(match) = viewModel.state {
                        path = [match.type == .x01 ? .x01Match(matchId: match.id) : .cricketMatch(matchId: match.id)]
                    } else if let snapshotRoute = initialSnapshotRoute() {
                        path = [snapshotRoute]
                    }
                }
            }
            .onChange(of: path) { _, newValue in
                if newValue.isEmpty {
                    Task {
                        await viewModel.onAppear()
                        await setupViewModel.onAppear()
                    }
                }
            }
        }
    }

    private func initialSnapshotRoute() -> PlayRoute? {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-snapshot_match_x01") {
            return .x01Match(matchId: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID())
        }
        if arguments.contains("-snapshot_match_cricket") {
            return .cricketMatch(matchId: UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID())
        }
        if arguments.contains("-snapshot_match_summary") {
            return .matchSummary(matchId: UUID(uuidString: "00000000-0000-0000-0000-000000000003") ?? UUID())
        }
        return nil
    }
}

private func localizedText(_ key: String) -> Text {
    Text(LocalizedStringKey(key))
}

// MARK: - Setup / Home

private struct SetupHomeView: View {
    @ObservedObject var homeViewModel: PlayHomeViewModel
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @ObservedObject var pendingMatchPlayerSelections: PendingMatchPlayerSelections
    let onResumeMatch: (MatchSummary) -> Void
    let onStartRoute: (PlayRoute) -> Void
    let onQuickAddPlayer: () -> Void
    @State private var startTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                Text("Dart Scoreboard")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.top, DS.Spacing.s2)

                if case let .readyWithActiveMatch(match) = homeViewModel.state {
                    resumeBanner(match)
                }

                modePill
                if setupViewModel.mode == .x01 {
                    chipsGrid
                }
                startButton
                rosterControls
                playerList
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s6)
        }
        .background(Brand.background.ignoresSafeArea())
        .navigationBarHidden(true)
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
                    Text("Resume match").font(.headline)
                    Text(match.type.rawValue.uppercased()).font(.caption).foregroundStyle(Brand.textSecondary)
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
        .accessibilityIdentifier("resumeMatchButton")
    }

    private var modePill: some View {
        HStack(spacing: 0) {
            modeButton("X01", mode: .x01)
            modeButton("Cricket", mode: .cricket)
        }
        .padding(4)
        .background(Brand.card, in: Capsule())
        .frame(maxWidth: .infinity)
    }

    private func modeButton(_ title: String, mode: MatchSetupViewModel.SetupMode) -> some View {
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
        chip(title: "Points", color: Brand.green) {
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
        }
    }

    private var checkoutChip: some View {
        chip(title: "Check-Out", color: Brand.red) {
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
        }
    }

    private var checkInChip: some View {
        chip(title: "Check-In", color: Brand.red) {
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
        }
    }

    private var legFormatChip: some View {
        chip(title: "Set/Leg", color: Brand.green) {
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
        }
    }

    private var setsChip: some View {
        chip(title: "Sets", color: Brand.green) {
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
        }
    }

    private var legsChip: some View {
        chip(title: "Legs", color: Brand.green) {
            Menu {
                ForEach(1 ... 9, id: \.self) { value in
                    Button("\(value)") {
                        setupViewModel.x01LegsToWin = value
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox("\(setupViewModel.x01LegsToWin)", color: Brand.green, showsMenuIndicator: true)
            }
        }
    }

    private func chip<Content: View>(title: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
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
            Button {
                startTask?.cancel()
                startTask = Task {
                    if let route = await setupViewModel.startMatchRoute() {
                        onStartRoute(route)
                    }
                }
            } label: {
                Text(setupViewModel.isSubmitting ? "STARTING…" : "START")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(setupViewModel.canStart ? Brand.red : Brand.red.opacity(0.4), in: RoundedRectangle(cornerRadius: DS.Radius.lg))
            }
            .buttonStyle(.plain)
            .disabled(!setupViewModel.canStart)
            .accessibilityIdentifier("startMatchButton")

            ForEach(setupViewModel.validationErrors, id: \.self) { key in
                localizedText(key).font(.footnote).foregroundStyle(Brand.red)
            }
        }
        .padding(.top, DS.Spacing.s2)
    }

    private var rosterControls: some View {
        HStack {
            Button { setupViewModel.randomOrder.toggle() } label: {
                HStack(spacing: 8) {
                    Image(systemName: setupViewModel.randomOrder ? "checkmark.square.fill" : "square")
                        .foregroundStyle(setupViewModel.randomOrder ? Brand.green : Brand.textSecondary)
                    Text("Random order").foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            Spacer()
            HStack(spacing: DS.Spacing.s2) {
                Menu {
                    botMenuButton("Easy", difficulty: .easy, color: Brand.green)
                    botMenuButton("Medium", difficulty: .medium, color: Brand.amber)
                    botMenuButton("Hard", difficulty: .hard, color: Brand.red)
                    botMenuButton("Pro", difficulty: .pro, color: Brand.proBot)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "cpu")
                        Text("Add Bot").font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.Spacing.s3)
                    .padding(.vertical, DS.Spacing.s2)
                    .background(Brand.cardElevated, in: Capsule())
                    .overlay(Capsule().stroke(Brand.textSecondary.opacity(0.35), lineWidth: 1))
                }
                Button { onQuickAddPlayer() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                        Text("Add Players").font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.Spacing.s3)
                    .padding(.vertical, DS.Spacing.s2)
                    .background(Brand.green, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, DS.Spacing.s2)
    }

    private func botMenuButton(_ title: String, difficulty: BotDifficulty, color: Color) -> some View {
        Button {
            setupViewModel.addBot(difficulty)
        } label: {
            Label {
                Text(title)
            } icon: {
                Circle().fill(color).frame(width: 10, height: 10)
            }
        }
    }

    @ViewBuilder
    private var playerList: some View {
        Text("Players").font(.headline).foregroundStyle(.white)
        if setupViewModel.availablePlayers.isEmpty && setupViewModel.selectedBots.isEmpty {
            Text("Add at least two players or bots to start a match.")
                .font(.footnote)
                .foregroundStyle(Brand.textSecondary)
        } else {
            VStack(spacing: 0) {
                ForEach(setupViewModel.selectedBots) { bot in
                    Button { setupViewModel.removeBot(bot.id) } label: {
                        HStack(spacing: DS.Spacing.s3) {
                            Image(systemName: "cpu.fill")
                                .foregroundStyle(botDifficultyColor(bot.difficulty))
                            Text(bot.displayName)
                                .font(.headline)
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(botDifficultyColor(bot.difficulty))
                        }
                        .padding(.vertical, DS.Spacing.s3)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("select_bot_\(bot.difficulty.rawValue)")
                    Divider().overlay(Brand.cardElevated)
                }
                ForEach(setupViewModel.availablePlayers) { player in
                    let isSelected = setupViewModel.selectedPlayerIds.contains(player.id)
                    Button { setupViewModel.togglePlayer(player.id) } label: {
                        HStack(spacing: DS.Spacing.s3) {
                            Image(systemName: "location.north.fill")
                                .rotationEffect(.degrees(135))
                                .foregroundStyle(Brand.textSecondary)
                            Text(player.name)
                                .font(.headline)
                                .foregroundStyle(isSelected ? .white : Brand.textSecondary)
                            Spacer()
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isSelected ? Brand.green : Brand.textSecondary)
                        }
                        .padding(.vertical, DS.Spacing.s3)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("select_\(player.name)")
                    Divider().overlay(Brand.cardElevated)
                }
            }
        }
    }

    private func botDifficultyColor(_ difficulty: BotDifficulty) -> Color {
        switch difficulty {
        case .easy: Brand.green
        case .medium: Brand.amber
        case .hard: Brand.red
        case .pro: Brand.proBot
        }
    }
}

// MARK: - Quick add player

private struct QuickAddPlayerScreen: View {
    let repository: any PlayerRepository
    let onCreated: (PlayerSummary) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var isSaving = false
    @State private var errorMessageKey: String?
    @State private var createTask: Task<Void, Never>?

    var body: some View {
        Form {
            Section("players.detail.identitySection") {
                TextField("players.edit.name", text: $name)
                    .textInputAutocapitalization(.words)
            }
            if let errorMessageKey {
                Section {
                    localizedText(errorMessageKey)
                        .foregroundStyle(DS.ColorRole.danger)
                }
            }
        }
        .navigationTitle(L10n.quickAddTitle)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "common.saving" : "common.save") {
                    createTask?.cancel()
                    createTask = Task { await createPlayer() }
                }
                .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onDisappear { createTask?.cancel() }
    }

    private func createPlayer() async {
        isSaving = true
        defer { isSaving = false }
        do {
            let created = try await repository.createPlayer(name: name)
            await onCreated(created)
            dismiss()
        } catch let appError as AppError {
            errorMessageKey = appError.userMessageKey
        } catch {
            errorMessageKey = "error.player.create"
        }
    }
}

// MARK: - Cricket match screen

private struct CricketMatchScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: CricketMatchViewModel
    let onShowSummary: () -> Void
    let audio: any AudioFeedbackService
    let haptics: any HapticsService
    @Environment(\.dismiss) private var dismiss
    @State private var showExitConfirmation = false
    @State private var actionTask: Task<Void, Never>?

    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? 700 : .infinity
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let state = viewModel.cricketState {
                    Text(L10n.format("play.cricket.roundTurn", state.roundIndex + 1, state.currentPlayerIndex + 1))
                        .foregroundStyle(Brand.textSecondary)
                    CricketBoardView(columns: viewModel.boardColumns)
                    CricketTapPad(
                        enteredDarts: $viewModel.enteredDarts,
                        selectedMultiplier: $viewModel.selectedMultiplier,
                        canSubmit: viewModel.canSubmit,
                        onSubmit: { submit() },
                        onUndoTurn: {
                            actionTask?.cancel()
                            actionTask = Task { await viewModel.undoLastTurn() }
                        }
                    )
                    .disabled(viewModel.canHumanInput == false)
                    .opacity(viewModel.canHumanInput ? 1 : 0.45)
                    .onChange(of: viewModel.enteredDarts) { old, darts in
                        guard viewModel.canHumanInput else { return }
                        if darts.count > old.count, let dart = darts.last { playDartFeedback(dart) }
                        if darts.count == 3 { submit() }
                    }
                } else {
                    ProgressView().tint(.white)
                }
                stateBanner
            }
            .frame(maxWidth: contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(DS.Spacing.s4)
        .background(Brand.background.ignoresSafeArea())
        .navigationTitle("play.cricket.navTitle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(L10n.cancel) { showExitConfirmation = true }
            }
        }
        .alert("play.match.exit.confirm.title", isPresented: $showExitConfirmation) {
            Button("common.stay", role: .cancel) {}
            Button("play.match.exit.saveAndExit") { dismiss() }
            Button("play.match.exit.abandon", role: .destructive) {
                actionTask?.cancel()
                actionTask = Task {
                    await viewModel.abandonMatch()
                    dismiss()
                }
            }
        } message: {
            Text("play.match.exit.confirm.message")
        }
        .onChange(of: viewModel.state) { _, newValue in
            if newValue == .matchCompleted {
                audio.playMatchFinished()
                onShowSummary()
            }
        }
        .task { await viewModel.onAppear() }
        .onDisappear { actionTask?.cancel() }
    }

    private func playDartFeedback(_ dart: DartInput) {
        if dart.isMiss { audio.playMiss() } else { audio.playHit() }
        haptics.playImpact()
    }

    private func submit() {
        actionTask?.cancel()
        actionTask = Task { await viewModel.submitTurn() }
    }

    @ViewBuilder
    private var stateBanner: some View {
        switch viewModel.state {
        case .readyTurn:
            if viewModel.isBotPlaying {
                Text("Bot throwing…").foregroundStyle(Brand.amber)
            } else {
                EmptyView()
            }
        case .submittingTurn:
            Text(L10n.submittingTurn).foregroundStyle(.white)
        case .closureTransition:
            Text(L10n.boardUpdated).foregroundStyle(Brand.textSecondary)
        case let .entryInvalid(key), let .error(key):
            localizedText(key).foregroundStyle(DS.ColorRole.danger)
        case .matchCompleted:
            Text(L10n.matchCompleteRoute).foregroundStyle(.white)
        }
    }
}

// MARK: - Match summary

private struct MatchSummaryScreen: View {
    @StateObject var viewModel: MatchSummaryViewModel
    let onStartNewMatch: () -> Void
    let onViewHistoryDetail: (UUID) -> Void

    @State private var celebrate = false

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.s4) {
                if viewModel.hasResult {
                    celebrationHeader
                    ForEach(viewModel.playerRows) { row in
                        playerCard(row)
                    }
                } else {
                    Text("Result").font(.title.weight(.heavy)).foregroundStyle(.white)
                }
                actions
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DS.Spacing.s4)
        }
        .background(Brand.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sensoryFeedback(.success, trigger: celebrate)
        .task {
            viewModel.refresh()
            try? await Task.sleep(nanoseconds: 120_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { celebrate = true }
        }
    }

    private var celebrationHeader: some View {
        VStack(spacing: DS.Spacing.s2) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 56))
                .foregroundStyle(Brand.amber)
                .scaleEffect(celebrate ? 1 : 0.4)
                .opacity(celebrate ? 1 : 0)
                .rotationEffect(.degrees(celebrate ? 0 : -25))
            if let winnerName = viewModel.winnerName {
                Text("\(winnerName) wins!")
                    .font(.title.weight(.heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            Text(viewModel.typeLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DS.Spacing.s4)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("matchSummaryHeader")
    }

    private func playerCard(_ row: MatchSummaryViewModel.PlayerRow) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(row.isWinner ? Brand.amber : Color.clear)
                .frame(width: 6)
            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                HStack(spacing: 6) {
                    if row.isWinner {
                        Image(systemName: "crown.fill").font(.caption).foregroundStyle(Brand.amber)
                    }
                    Text(row.name)
                        .font(.headline)
                        .foregroundStyle(row.isWinner ? Brand.amber : .white)
                }
                HStack(spacing: DS.Spacing.s4) {
                    ForEach(row.stats, id: \.label) { stat in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.value)
                                .font(.title3.weight(.bold).monospacedDigit())
                                .foregroundStyle(.white)
                            Text(stat.label)
                                .font(.caption2)
                                .foregroundStyle(Brand.textSecondary)
                        }
                    }
                }
            }
            .padding(DS.Spacing.s3)
            Spacer(minLength: 0)
        }
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private var actions: some View {
        VStack(spacing: DS.Spacing.s3) {
            Button(action: onStartNewMatch) {
                Text("New Match")
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Brand.red, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
            }
            .buttonStyle(.plain)
            Button(action: { onViewHistoryDetail(viewModel.matchId) }) {
                Text("View Game Statistics")
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, DS.Spacing.s2)
    }
}
