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
            PlayHomeView(
                state: viewModel.state,
                onTapStartNewMatch: { path.append(.setup) },
                onTapResumeMatch: { match in
                    path.append(match.type == .x01 ? .x01Match(matchId: match.id) : .cricketMatch(matchId: match.id))
                }
            )
                .navigationTitle(L10n.playTitle)
                .navigationDestination(for: PlayRoute.self) { route in
                    switch route {
                    case .setup:
                        MatchSetupView(
                            viewModel: setupViewModel,
                            pendingMatchPlayerSelections: dependencies.pendingMatchPlayerSelections,
                            onStartRoute: { next in path.append(next) },
                            onQuickAddPlayer: { path.append(.quickAddPlayer) }
                        )
                    case let .x01Match(matchId):
                        X01MatchScreen(
                            viewModel: X01MatchViewModel(
                                matchId: matchId,
                                store: dependencies.activeMatchStore,
                                logger: dependencies.logger,
                                matchRepository: dependencies.matchRepository,
                                statsRepository: dependencies.statsRepository
                            ),
                            onShowSummary: { path.append(.matchSummary(matchId: matchId)) }
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
                            onShowSummary: { path.append(.matchSummary(matchId: matchId)) }
                        )
                    case let .matchSummary(matchId):
                        MatchSummaryScreen(
                            matchId: matchId,
                            store: dependencies.activeMatchStore,
                            onStartNewMatch: {
                                path.removeAll()
                                path.append(.setup)
                            },
                            onViewHistoryDetail: { id in
                                path.append(.historyDetail(matchId: id))
                            }
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
                    if let snapshotRoute = initialSnapshotRoute(),
                       hasAppliedSnapshotRoute == false {
                        hasAppliedSnapshotRoute = true
                        path = [snapshotRoute]
                    }
                }
        }
    }

    private func initialSnapshotRoute() -> PlayRoute? {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-snapshot_match_setup") {
            return .setup
        }
        if arguments.contains("-snapshot_match_x01") {
            return .x01Match(matchId: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID())
        }
        if arguments.contains("-snapshot_match_cricket") {
            return .cricketMatch(matchId: UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID())
        }
        return nil
    }
}

private func localizedText(_ key: String) -> Text {
    Text(LocalizedStringKey(key))
}

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
        .onDisappear {
            createTask?.cancel()
        }
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

private struct PlayHomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let state: PlayHomeViewModel.State
    let onTapStartNewMatch: () -> Void
    let onTapResumeMatch: (MatchSummary) -> Void

    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? 700 : .infinity
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            switch state {
            case .loading:
                ProgressView(L10n.loading)
            case .readyNoActiveMatch:
                Text(L10n.noActiveMatch)
                    .foregroundStyle(DS.ColorRole.textSecondary)
                startButton
            case let .readyWithActiveMatch(match):
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    Text(L10n.resumeActiveMatch)
                        .font(.headline)
                    Text(L10n.format("play.home.modeFormat", match.type.rawValue.uppercased()))
                    Button {
                        onTapResumeMatch(match)
                    } label: {
                        Text(L10n.resumeMatch)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityHint("play.home.resumeButton.hint")
                }
                .padding(DS.Spacing.s4)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                startButton
            case .emptyNoPlayers:
                Spacer(minLength: 0)
                VStack(spacing: DS.Spacing.s2) {
                    Image(systemName: "person.2")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(DS.ColorRole.textSecondary)
                    Text(L10n.noPlayersGuidance)
                        .foregroundStyle(DS.ColorRole.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(DS.Spacing.s5)
                .background(DS.ColorRole.backgroundSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
                Spacer(minLength: 0)
            case let .error(messageKey):
                localizedText(messageKey)
                    .foregroundStyle(DS.ColorRole.danger)
                startButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, DS.Spacing.s4)
        .frame(maxWidth: contentMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, DS.Spacing.s4)
        .safeAreaInset(edge: .bottom) {
            if case .emptyNoPlayers = state {
                startButton
                .frame(maxWidth: .infinity)
                .padding(.horizontal, DS.Spacing.s4)
                .padding(.top, DS.Spacing.s2)
                .padding(.bottom, DS.Spacing.s3)
            }
        }
    }

    private var startButton: some View {
        Button {
            onTapStartNewMatch()
        } label: {
            Text(L10n.startNewMatch)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityHint("play.home.startNewMatch.hint")
    }
}

private struct MatchSetupView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject var viewModel: MatchSetupViewModel
    @ObservedObject var pendingMatchPlayerSelections: PendingMatchPlayerSelections
    let onStartRoute: (PlayRoute) -> Void
    let onQuickAddPlayer: () -> Void
    @State private var startTask: Task<Void, Never>?

    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? 760 : .infinity
    }

    private var usesInlineStartButton: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                modeSection
                playerSection
                if viewModel.mode == .x01 {
                    x01Section
                }
                validationSection
                if usesInlineStartButton {
                    startMatchButton
                        .padding(.top, DS.Spacing.s2)
                }
            }
            .padding(DS.Spacing.s4)
            .padding(.bottom, usesInlineStartButton ? DS.Spacing.s4 : 88)
            .frame(maxWidth: contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(ThemeTokens.appBackground)
        .navigationTitle(L10n.newMatchTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await viewModel.onAppear()
        }
        .onChange(of: pendingMatchPlayerSelections.changeCount) { _, _ in
            Task { await viewModel.onAppear() }
        }
        .safeAreaInset(edge: .bottom) {
            if !usesInlineStartButton {
                VStack(spacing: 0) {
                    Divider()
                    startMatchButton
                        .padding(.top, DS.Spacing.s3)
                        .padding(.bottom, DS.Spacing.s2)
                }
                .background(DS.ColorRole.backgroundPrimary.opacity(0.92))
            }
        }
        .onDisappear {
            startTask?.cancel()
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.modeSection).font(.headline)
            Group {
                if usesInlineStartButton {
                    Picker("play.setup.mode", selection: Binding(
                        get: { viewModel.mode },
                        set: { viewModel.updateMode($0) }
                    )) {
                        Text("settings.mode.x01").tag(MatchSetupViewModel.SetupMode.x01)
                        Text("settings.mode.cricket").tag(MatchSetupViewModel.SetupMode.cricket)
                    }
                    .pickerStyle(.menu)
                } else {
                    Picker("play.setup.mode", selection: Binding(
                        get: { viewModel.mode },
                        set: { viewModel.updateMode($0) }
                    )) {
                        Text("settings.mode.x01").tag(MatchSetupViewModel.SetupMode.x01)
                        Text("settings.mode.cricket").tag(MatchSetupViewModel.SetupMode.cricket)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.s4)
        .background(DS.ColorRole.backgroundSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.playersSection).font(.headline)
            if viewModel.availablePlayers.isEmpty {
                Text(L10n.setupPlayersEmptyHint)
                    .font(.footnote)
                    .foregroundStyle(DS.ColorRole.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if viewModel.selectedPlayerIds.count < 2 {
                Text(L10n.setupPlayersSelectionHint)
                    .font(.footnote)
                    .foregroundStyle(DS.ColorRole.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(viewModel.availablePlayers) { player in
                let isSelected = viewModel.selectedPlayerIds.contains(player.id)
                Button {
                    viewModel.togglePlayer(player.id)
                } label: {
                    HStack {
                        Text(player.name)
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .imageScale(.large)
                            .foregroundStyle(isSelected ? DS.ColorRole.info : DS.ColorRole.textSecondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(L10n.setupPlayerRowAccessibilityHint)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
            Button {
                onQuickAddPlayer()
            } label: {
                Text(L10n.quickAdd)
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.s4)
        .background(DS.ColorRole.backgroundSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private var x01Section: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.x01Options).font(.headline)
            Group {
                if usesInlineStartButton {
                    Picker("play.setup.startScore", selection: $viewModel.x01StartScore) {
                        Text("301").tag(301)
                        Text("501").tag(501)
                    }
                    .pickerStyle(.menu)
                } else {
                    Picker("play.setup.startScore", selection: $viewModel.x01StartScore) {
                        Text("301").tag(301)
                        Text("501").tag(501)
                    }
                    .pickerStyle(.segmented)
                }
            }
            Stepper(L10n.format("play.setup.legsToWinFormat", viewModel.x01LegsToWin), value: $viewModel.x01LegsToWin, in: 1 ... 99)
            Toggle("play.setup.setsEnabled", isOn: $viewModel.x01SetsEnabled)
            if viewModel.x01SetsEnabled {
                Stepper(L10n.format("play.setup.setsToWinFormat", viewModel.x01SetsToWin), value: $viewModel.x01SetsToWin, in: 1 ... 99)
            }
            Group {
                if usesInlineStartButton {
                    Picker("play.setup.checkout", selection: $viewModel.x01CheckoutMode) {
                        Text(L10n.singleOut).tag(X01CheckoutMode.singleOut)
                        Text(L10n.doubleOut).tag(X01CheckoutMode.doubleOut)
                    }
                    .pickerStyle(.menu)
                } else {
                    Picker("play.setup.checkout", selection: $viewModel.x01CheckoutMode) {
                        Text(L10n.singleOut).tag(X01CheckoutMode.singleOut)
                        Text(L10n.doubleOut).tag(X01CheckoutMode.doubleOut)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.s4)
        .background(DS.ColorRole.backgroundSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .onChange(of: viewModel.x01StartScore) { _, _ in viewModel.revalidate() }
        .onChange(of: viewModel.x01LegsToWin) { _, _ in viewModel.revalidate() }
        .onChange(of: viewModel.x01SetsEnabled) { _, _ in viewModel.revalidate() }
        .onChange(of: viewModel.x01SetsToWin) { _, _ in viewModel.revalidate() }
    }

    private var validationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(viewModel.validationErrors, id: \.self) { key in
                localizedText(key)
                    .font(.footnote)
                    .foregroundStyle(DS.ColorRole.danger)
            }
        }
    }

    private var startMatchButton: some View {
        Button {
            startTask?.cancel()
            startTask = Task {
                if let route = await viewModel.startMatchRoute() {
                    onStartRoute(route)
                }
            }
        } label: {
            Text(viewModel.isSubmitting ? "play.setup.starting" : "play.setup.startMatch")
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(usesInlineStartButton ? .regular : .large)
        .disabled(!viewModel.canStart)
        .frame(maxWidth: 360)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DS.Spacing.s4)
    }
}

private struct X01MatchScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: X01MatchViewModel
    let onShowSummary: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showExitConfirmation = false
    @State private var actionTask: Task<Void, Never>?
    
    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? 700 : .infinity
    }
    
    private var isSnapshotPreviewMode: Bool {
        ProcessInfo.processInfo.arguments.contains("-snapshot_match_x01")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.x01Title)
                    .font(.title2).bold()
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    if let session = viewModel.session, let state = session.runtime.x01State {
                        Text(L10n.format("play.x01.turnLegSet", state.currentPlayerIndex + 1, state.legIndex + 1, state.setIndex + 1))
                            .foregroundStyle(DS.ColorRole.textSecondary)
                        ForEach(Array(state.players.enumerated()), id: \.element.playerId) { index, player in
                            ViewThatFits {
                                HStack {
                                    Text(L10n.format("common.playerOrdinal", index + 1))
                                    Spacer()
                                    HStack(spacing: DS.Spacing.s1) {
                                        Text("\(player.remainingScore)")
                                            .font(.title3.weight(.semibold))
                                        if index == state.currentPlayerIndex && session.runtime.status == .inProgress {
                                            Text(L10n.active).font(.caption).foregroundStyle(DS.ColorRole.textSecondary)
                                        }
                                    }
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                }
                                VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                                    Text(L10n.format("common.playerOrdinal", index + 1))
                                    HStack(spacing: DS.Spacing.s1) {
                                        Text("\(player.remainingScore)")
                                            .font(.title3.weight(.semibold))
                                        if index == state.currentPlayerIndex && session.runtime.status == .inProgress {
                                            Text(L10n.active).font(.caption).foregroundStyle(DS.ColorRole.textSecondary)
                                        }
                                    }
                                }
                            }
                        }
                    } else if isSnapshotPreviewMode {
                        Text(L10n.format("play.x01.turnLegSet", 1, 1, 1))
                            .foregroundStyle(DS.ColorRole.textSecondary)
                        ForEach([501, 421], id: \.self) { score in
                            ViewThatFits {
                                HStack {
                                    Text(L10n.format("common.playerOrdinal", score == 501 ? 1 : 2))
                                    Spacer()
                                    HStack(spacing: DS.Spacing.s1) {
                                        Text("\(score)")
                                            .font(.title3.weight(.semibold))
                                        if score == 501 {
                                            Text(L10n.active).font(.caption).foregroundStyle(DS.ColorRole.textSecondary)
                                        }
                                    }
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                }
                                VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                                    Text(L10n.format("common.playerOrdinal", score == 501 ? 1 : 2))
                                    HStack(spacing: DS.Spacing.s1) {
                                        Text("\(score)")
                                            .font(.title3.weight(.semibold))
                                        if score == 501 {
                                            Text(L10n.active).font(.caption).foregroundStyle(DS.ColorRole.textSecondary)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        ProgressView(L10n.loading)
                    }
                }
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                ScoringInputPad(
                    modeOptions: [.totalEntry, .dartEntry],
                    mode: $viewModel.inputMode,
                    selectedMultiplier: $viewModel.selectedMultiplier,
                    enteredDarts: $viewModel.enteredDarts,
                    totalEntryText: $viewModel.totalEntryText,
                    canSubmit: viewModel.canSubmit,
                    onSubmit: {
                        actionTask?.cancel()
                        actionTask = Task { await viewModel.submitTurn() }
                    },
                    onUndo: {
                        actionTask?.cancel()
                        actionTask = Task { await viewModel.undoLastTurn() }
                    }
                )
                stateBanner
            }
            .frame(maxWidth: contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(DS.Spacing.s4)
        .navigationTitle("play.x01.navTitle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(L10n.cancel) {
                    showExitConfirmation = true
                }
            }
        }
        .alert("play.match.exit.confirm.title", isPresented: $showExitConfirmation) {
            Button("common.stay", role: .cancel) {}
            Button("common.exit", role: .destructive) { dismiss() }
        } message: {
            Text("play.match.exit.confirm.message")
        }
        .onChange(of: viewModel.state) { _, newValue in
            if newValue == .matchCompleted {
                onShowSummary()
            }
        }
        .task {
            await viewModel.onAppear()
        }
        .onDisappear {
            actionTask?.cancel()
        }
    }

    @ViewBuilder
    private var stateBanner: some View {
        switch viewModel.state {
        case .readyTurn:
            EmptyView()
        case .submittingTurn:
            Text(L10n.submittingTurn)
        case .bustFeedback:
            Text(L10n.bustFeedback)
                .foregroundStyle(DS.ColorRole.warning)
        case let .entryInvalid(key), let .error(key):
            localizedText(key).foregroundStyle(DS.ColorRole.danger)
        case .matchCompleted:
            Text(L10n.matchCompleteRoute)
        }
    }
}

private struct CricketMatchScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: CricketMatchViewModel
    let onShowSummary: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showExitConfirmation = false
    @State private var actionTask: Task<Void, Never>?
    
    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? 700 : .infinity
    }
    
    private var isSnapshotPreviewMode: Bool {
        ProcessInfo.processInfo.arguments.contains("-snapshot_match_cricket")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.cricketTitle)
                    .font(.title2).bold()
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    if let session = viewModel.session, let state = session.runtime.cricketState {
                        Text(L10n.format("play.cricket.roundTurn", state.roundIndex + 1, state.currentPlayerIndex + 1))
                            .foregroundStyle(DS.ColorRole.textSecondary)
                        ForEach(Array(state.players.enumerated()), id: \.element.playerId) { index, player in
                            VStack(alignment: .leading, spacing: 4) {
                                ViewThatFits {
                                    HStack {
                                        Text(L10n.format("common.playerOrdinal", index + 1))
                                        Spacer()
                                        HStack(spacing: DS.Spacing.s1) {
                                            Text(L10n.format("play.cricket.pointsFormat", player.score))
                                                .font(.title3.weight(.semibold))
                                            if index == state.currentPlayerIndex && session.runtime.status == .inProgress {
                                                Text(L10n.active).font(.caption).foregroundStyle(DS.ColorRole.textSecondary)
                                            }
                                        }
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)
                                    }
                                    VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                                        Text(L10n.format("common.playerOrdinal", index + 1))
                                        HStack(spacing: DS.Spacing.s1) {
                                            Text(L10n.format("play.cricket.pointsFormat", player.score))
                                                .font(.title3.weight(.semibold))
                                            if index == state.currentPlayerIndex && session.runtime.status == .inProgress {
                                                Text(L10n.active).font(.caption).foregroundStyle(DS.ColorRole.textSecondary)
                                            }
                                        }
                                    }
                                }
                                HStack(spacing: 6) {
                                    ForEach(CricketTarget.allCases, id: \.rawValue) { target in
                                        Text("\(target.rawValue):\(marksText(player.marks[target.rawValue] ?? 0))")
                                            .font(.caption2)
                                            .padding(.horizontal, 4)
                                            .background(.thinMaterial, in: Capsule())
                                    }
                                }
                            }
                        }
                    } else if isSnapshotPreviewMode {
                        Text(L10n.format("play.cricket.roundTurn", 1, 1))
                            .foregroundStyle(DS.ColorRole.textSecondary)
                        ForEach([32, 10], id: \.self) { points in
                            ViewThatFits {
                                HStack {
                                    Text(L10n.format("common.playerOrdinal", points == 32 ? 1 : 2))
                                    Spacer()
                                    HStack(spacing: DS.Spacing.s1) {
                                        Text(L10n.format("play.cricket.pointsFormat", points))
                                            .font(.title3.weight(.semibold))
                                        if points == 32 {
                                            Text(L10n.active).font(.caption).foregroundStyle(DS.ColorRole.textSecondary)
                                        }
                                    }
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                }
                                VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                                    Text(L10n.format("common.playerOrdinal", points == 32 ? 1 : 2))
                                    HStack(spacing: DS.Spacing.s1) {
                                        Text(L10n.format("play.cricket.pointsFormat", points))
                                            .font(.title3.weight(.semibold))
                                        if points == 32 {
                                            Text(L10n.active).font(.caption).foregroundStyle(DS.ColorRole.textSecondary)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        ProgressView(L10n.loading)
                    }
                }
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                ScoringInputPad(
                    modeOptions: [.dartEntry],
                    mode: .constant(.dartEntry),
                    selectedMultiplier: $viewModel.selectedMultiplier,
                    enteredDarts: $viewModel.enteredDarts,
                    totalEntryText: .constant(""),
                    canSubmit: viewModel.canSubmit,
                    onSubmit: {
                        actionTask?.cancel()
                        actionTask = Task { await viewModel.submitTurn() }
                    },
                    onUndo: {
                        actionTask?.cancel()
                        actionTask = Task { await viewModel.undoLastTurn() }
                    }
                )
                stateBanner
            }
            .frame(maxWidth: contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(DS.Spacing.s4)
        .navigationTitle("play.cricket.navTitle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(L10n.cancel) {
                    showExitConfirmation = true
                }
            }
        }
        .alert("play.match.exit.confirm.title", isPresented: $showExitConfirmation) {
            Button("common.stay", role: .cancel) {}
            Button("common.exit", role: .destructive) { dismiss() }
        } message: {
            Text("play.match.exit.confirm.message")
        }
        .onChange(of: viewModel.state) { _, newValue in
            if newValue == .matchCompleted {
                onShowSummary()
            }
        }
        .task {
            await viewModel.onAppear()
        }
        .onDisappear {
            actionTask?.cancel()
        }
    }

    private func marksText(_ marks: Int) -> String {
        let safe = max(0, min(3, marks))
        switch safe {
        case 0: return "ooo"
        case 1: return "Xoo"
        case 2: return "XXo"
        default: return "XXX"
        }
    }

    @ViewBuilder
    private var stateBanner: some View {
        switch viewModel.state {
        case .readyTurn:
            EmptyView()
        case .submittingTurn:
            Text(L10n.submittingTurn)
        case .closureTransition:
            Text(L10n.boardUpdated)
                .foregroundStyle(DS.ColorRole.textSecondary)
        case let .entryInvalid(key), let .error(key):
            localizedText(key).foregroundStyle(DS.ColorRole.danger)
        case .matchCompleted:
            Text(L10n.matchCompleteRoute)
        }
    }
}

private struct MatchSummaryScreen: View {
    let matchId: UUID
    let store: ActiveMatchStore
    let onStartNewMatch: () -> Void
    let onViewHistoryDetail: (UUID) -> Void

    var body: some View {
        let session = store.session(for: matchId)
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.summaryTitle).font(.title3).bold()
            Text(L10n.format("play.summary.matchIdFormat", String(matchId.uuidString.prefix(8))))
                .font(.footnote)
                .foregroundStyle(DS.ColorRole.textSecondary)
            if let session {
                Text(L10n.format("play.summary.modeFormat", session.runtime.type.rawValue.uppercased()))
                Text(L10n.format("play.summary.winnerFormat", session.runtime.winnerPlayerId.map { String($0.uuidString.prefix(8)) } ?? NSLocalizedString("common.unknown", comment: "")))
                Text(L10n.format("play.summary.eventsFormat", session.runtime.eventCount))
            }
            Button(L10n.summaryNewMatch) {
                onStartNewMatch()
            }
                .buttonStyle(.borderedProminent)
            Button(L10n.summaryHistoryDetail) {
                onViewHistoryDetail(matchId)
            }
                .buttonStyle(.bordered)
        }
        .padding(DS.Spacing.s4)
        .navigationTitle("play.summary.navTitle")
        .toolbar(.hidden, for: .tabBar)
    }
}

