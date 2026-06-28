import SwiftUI

private enum SetupHomeSheet: Identifiable {
    case gameRules(MatchType)
    case customBot
    case modePicker
    case addPlayer

    var id: String {
        switch self {
        case let .gameRules(matchType):
            return "gameRules-\(matchType.rawValue)"
        case .customBot:
            return "customBot"
        case .modePicker:
            return "modePicker"
        case .addPlayer:
            return "addPlayer"
        }
    }
}

struct SetupHomeSheetHost: View {
    @ObservedObject var homeViewModel: PlayHomeViewModel
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @ObservedObject var pendingMatchPlayerSelections: PendingMatchPlayerSelections
    let onResumeMatch: (MatchSummary) -> Void
    let onStartRoute: (PlayRoute) -> Void
    let onChangeMode: () -> Void

    @State private var activeSheet: SetupHomeSheet?
    @State private var showsEditOptions = false
    @State private var startTask: Task<Void, Never>?

    var body: some View {
        SetupHomeChrome(
            setupViewModel: setupViewModel,
            startTask: $startTask,
            onStart: startMatchTapped,
            onShowCustomBot: { activeSheet = .customBot },
            onShowAddPlayer: { activeSheet = .addPlayer }
        ) {
            SetupHomeScrollContent(
                homeViewModel: homeViewModel,
                setupViewModel: setupViewModel,
                showsEditOptions: $showsEditOptions,
                startTask: $startTask,
                onResumeMatch: onResumeMatch,
                onLearnToPlay: presentLearnToPlay,
                onChangeMode: onChangeMode,
                onShowModePicker: { activeSheet = .modePicker },
                onShowCustomBot: { activeSheet = .customBot },
                onShowAddPlayer: { activeSheet = .addPlayer }
            )
        }
        .onAppear {
            Task {
                if let selection = pendingMatchPlayerSelections.consumeModeSelection() {
                    setupViewModel.applyPendingModeSelection(selection)
                }
                await setupViewModel.onAppear()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .settingsDidUpdate)) { _ in
            Task { await setupViewModel.onAppear() }
        }
        .onChange(of: pendingMatchPlayerSelections.changeCount) { _, _ in
            if let selection = pendingMatchPlayerSelections.consumeModeSelection() {
                setupViewModel.applyPendingModeSelection(selection)
            }
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
        .sheet(item: $activeSheet) { sheet in
            sheetContent(for: sheet)
        }
        .onDisappear {
            startTask?.cancel()
        }
    }

    private func presentLearnToPlay() {
        if let matchType = SetupHomeModeContext.learnToPlayMatchType(for: setupViewModel) {
            activeSheet = .gameRules(matchType)
        }
    }

    private func startMatchTapped() {
        startTask?.cancel()
        startTask = Task {
            if let route = await setupViewModel.startMatchRoute() {
                onStartRoute(route)
            }
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: SetupHomeSheet) -> some View {
        switch sheet {
        case let .gameRules(matchType):
            GameRulesGuideView(initialMode: matchType)
        case .customBot:
            CustomBotCreationSheet { name, metrics in
                startTask?.cancel()
                startTask = Task { await setupViewModel.addCustomBot(name: name, metrics: metrics) }
            }
        case .modePicker:
            ModePickerSheet(
                selectedEntryId: SetupHomeModeContext.selectedCatalogEntry(for: setupViewModel)?.id
            ) { entry in
                if let selection = entry.pendingModeSelection {
                    setupViewModel.applyPendingModeSelection(selection)
                }
                activeSheet = nil
            }
        case .addPlayer:
            PlayerEditSheet(
                viewModel: PlayerEditViewModel(
                    existingNames: setupViewModel.availableHumans.map(\.name),
                    editing: nil
                ),
                existing: nil,
                onSave: { player in
                    await setupViewModel.createHumanPlayer(player)
                }
            )
        }
    }
}
