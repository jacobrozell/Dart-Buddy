import SwiftUI

struct PlayRootView: View {
    let dependencies: AppDependencies
    @State private var path: [PlayRoute] = []
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
                activeMatchStore: dependencies.activeMatchStore
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
                            matchId: matchId,
                            statsRepository: dependencies.statsRepository
                        )
                    case .quickAddPlayer:
                        QuickAddPlayerScreen(repository: dependencies.playerRepository) {
                            await setupViewModel.onAppear()
                            path.removeLast()
                        }
                    }
                }
                .task {
                    await viewModel.onAppear()
                }
        }
    }
}

private struct QuickAddPlayerScreen: View {
    let repository: any PlayerRepository
    let onCreated: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var isSaving = false
    @State private var errorMessageKey: String?

    var body: some View {
        Form {
            Section("players.detail.identitySection") {
                TextField("players.edit.name", text: $name)
                    .textInputAutocapitalization(.words)
            }
            if let errorMessageKey {
                Section {
                    Text(errorMessageKey)
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
                    Task { await createPlayer() }
                }
                .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func createPlayer() async {
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await repository.createPlayer(name: name)
            await onCreated()
            dismiss()
        } catch let appError as AppError {
            errorMessageKey = appError.userMessageKey
        } catch {
            errorMessageKey = "error.player.create"
        }
    }
}

private struct PlayHomeView: View {
    let state: PlayHomeViewModel.State
    let onTapStartNewMatch: () -> Void
    let onTapResumeMatch: (MatchSummary) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch state {
            case .loading:
                ProgressView(L10n.loading)
            case .readyNoActiveMatch:
                Text(L10n.noActiveMatch)
                    .foregroundStyle(DS.ColorRole.textSecondary)
            case let .readyWithActiveMatch(match):
                VStack(alignment: .leading, spacing: 8) {
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
            case .emptyNoPlayers:
                Text(L10n.noPlayersGuidance)
                    .foregroundStyle(DS.ColorRole.textSecondary)
            case let .error(messageKey):
                Text(messageKey)
                    .foregroundStyle(DS.ColorRole.danger)
            }

            Button {
                onTapStartNewMatch()
            } label: {
                Text(L10n.startNewMatch)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint("play.home.startNewMatch.hint")
        }
        .padding(DS.Spacing.s4)
    }
}

private struct MatchSetupView: View {
    @ObservedObject var viewModel: MatchSetupViewModel
    let onStartRoute: (PlayRoute) -> Void
    let onQuickAddPlayer: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                modeSection
                playerSection
                if viewModel.mode == .x01 {
                    x01Section
                }
                validationSection
            }
            .padding()
        }
        .navigationTitle(L10n.newMatchTitle)
        .task {
            await viewModel.onAppear()
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                Task {
                    if let route = await viewModel.startMatchRoute() {
                        onStartRoute(route)
                    }
                }
            } label: {
                Text(viewModel.isSubmitting ? "play.setup.starting" : "play.setup.startMatch")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canStart)
            .frame(minHeight: 56)
            .padding(DS.Spacing.s4)
            .background(.ultraThinMaterial)
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.modeSection).font(.headline)
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

    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.playersSection).font(.headline)
            ForEach(viewModel.availablePlayers) { player in
                Button {
                    viewModel.togglePlayer(player.id)
                } label: {
                    HStack {
                        Text(player.name)
                        Spacer()
                        if viewModel.selectedPlayerIds.contains(player.id) {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            Button {
                onQuickAddPlayer()
            } label: {
                Text(L10n.quickAdd)
            }
            .buttonStyle(.bordered)
        }
    }

    private var x01Section: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.x01Options).font(.headline)
            Picker("play.setup.startScore", selection: $viewModel.x01StartScore) {
                Text("301").tag(301)
                Text("501").tag(501)
            }
            .pickerStyle(.segmented)
            Stepper(L10n.format("play.setup.legsToWinFormat", viewModel.x01LegsToWin), value: $viewModel.x01LegsToWin, in: 1 ... 99)
            Toggle("play.setup.setsEnabled", isOn: $viewModel.x01SetsEnabled)
            if viewModel.x01SetsEnabled {
                Stepper(L10n.format("play.setup.setsToWinFormat", viewModel.x01SetsToWin), value: $viewModel.x01SetsToWin, in: 1 ... 99)
            }
            Picker("play.setup.checkout", selection: $viewModel.x01CheckoutMode) {
                Text(L10n.singleOut).tag(X01CheckoutMode.singleOut)
                Text(L10n.doubleOut).tag(X01CheckoutMode.doubleOut)
            }
            .pickerStyle(.segmented)
        }
        .onChange(of: viewModel.x01StartScore) { _, _ in viewModel.revalidate() }
        .onChange(of: viewModel.x01LegsToWin) { _, _ in viewModel.revalidate() }
        .onChange(of: viewModel.x01SetsEnabled) { _, _ in viewModel.revalidate() }
        .onChange(of: viewModel.x01SetsToWin) { _, _ in viewModel.revalidate() }
    }

    private var validationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(viewModel.validationErrors, id: \.self) { key in
                Text(key)
                    .font(.footnote)
                    .foregroundStyle(DS.ColorRole.danger)
            }
        }
    }
}

private struct X01MatchScreen: View {
    @ObservedObject var viewModel: X01MatchViewModel
    let onShowSummary: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showExitConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.x01Title)
                .font(.title2).bold()
            if let session = viewModel.session, let state = session.runtime.x01State {
                Text(L10n.format("play.x01.turnLegSet", state.currentPlayerIndex + 1, state.legIndex + 1, state.setIndex + 1))
                ForEach(Array(state.players.enumerated()), id: \.element.playerId) { index, player in
                    HStack {
                        Text(L10n.format("common.playerOrdinal", index + 1))
                        Spacer()
                        Text("\(player.remainingScore)")
                        if index == state.currentPlayerIndex && session.runtime.status == .inProgress {
                            Text(L10n.active).font(.caption).foregroundStyle(DS.ColorRole.textSecondary)
                        }
                    }
                }
            }
            ScoringInputPad(
                modeOptions: [.totalEntry, .dartEntry],
                mode: $viewModel.inputMode,
                selectedMultiplier: $viewModel.selectedMultiplier,
                enteredDarts: $viewModel.enteredDarts,
                totalEntryText: $viewModel.totalEntryText,
                canSubmit: viewModel.canSubmit,
                onSubmit: { viewModel.submitTurn() },
                onUndo: { viewModel.undoLastTurn() }
            )
            stateBanner
        }
        .padding(DS.Spacing.s4)
        .navigationTitle("play.x01.navTitle")
        .navigationBarTitleDisplayMode(.inline)
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
            Text(key).foregroundStyle(DS.ColorRole.danger)
        case .matchCompleted:
            Text(L10n.matchCompleteRoute)
        }
    }
}

private struct CricketMatchScreen: View {
    @ObservedObject var viewModel: CricketMatchViewModel
    let onShowSummary: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showExitConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.cricketTitle)
                .font(.title2).bold()
            if let session = viewModel.session, let state = session.runtime.cricketState {
                Text(L10n.format("play.cricket.roundTurn", state.roundIndex + 1, state.currentPlayerIndex + 1))
                ForEach(Array(state.players.enumerated()), id: \.element.playerId) { index, player in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(L10n.format("common.playerOrdinal", index + 1))
                            Spacer()
                            Text(L10n.format("play.cricket.pointsFormat", player.score))
                            if index == state.currentPlayerIndex && session.runtime.status == .inProgress {
                                Text(L10n.active).font(.caption).foregroundStyle(DS.ColorRole.textSecondary)
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
            }
            ScoringInputPad(
                modeOptions: [.dartEntry],
                mode: .constant(.dartEntry),
                selectedMultiplier: $viewModel.selectedMultiplier,
                enteredDarts: $viewModel.enteredDarts,
                totalEntryText: .constant(""),
                canSubmit: viewModel.canSubmit,
                onSubmit: { viewModel.submitTurn() },
                onUndo: { viewModel.undoLastTurn() }
            )
            stateBanner
        }
        .padding(DS.Spacing.s4)
        .navigationTitle("play.cricket.navTitle")
        .navigationBarTitleDisplayMode(.inline)
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
            Text(key).foregroundStyle(DS.ColorRole.danger)
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
    }
}

private struct MatchHistoryDetailScreen: View {
    let matchId: UUID
    let statsRepository: any StatsRepository
    @State private var rows: [String] = []
    @State private var state = "loading"

    var body: some View {
        List {
            Section(L10n.historyHeaderSection) {
                Text(L10n.format("history.detail.matchFormat", String(matchId.uuidString.prefix(8))))
            }
            Section(L10n.historyTimelineSection) {
                if rows.isEmpty, state == "loading" {
                    ProgressView(L10n.loading)
                } else if rows.isEmpty {
                    Text("history.timeline.empty")
                        .foregroundStyle(DS.ColorRole.textSecondary)
                } else {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        Text(row)
                    }
                }
            }
        }
        .navigationTitle(L10n.historyDetailTitle)
        .task {
            await load()
        }
    }

    private func load() async {
        state = "loading"
        do {
            let events = try await statsRepository.fetchEvents(matchId: matchId)
            rows = try events.map { event in
                let envelope = try CodablePayloadCoder.decode(MatchEventEnvelope.self, from: event.eventPayload)
                switch envelope.payload {
                case let .x01Turn(turn):
                    return "Turn \(turn.turnIndex + 1): \(turn.playerId.uuidString.prefix(6)) +\(turn.appliedTotal)"
                case let .cricketTurn(turn):
                    return "Turn \(turn.turnIndex + 1): \(turn.playerId.uuidString.prefix(6)) +\(turn.totalPointsAdded)"
                }
            }
            state = "ready"
        } catch {
            rows = []
            state = "error"
        }
    }
}
