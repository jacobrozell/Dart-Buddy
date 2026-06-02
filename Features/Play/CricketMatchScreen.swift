import SwiftUI

struct CricketMatchScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: CricketMatchViewModel
    let onShowSummary: () -> Void
    let audio: any AudioFeedbackService
    let haptics: any HapticsService
    let turnTotalCaller: any TurnTotalCallerService
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
        .onChange(of: viewModel.turnTotalCallerSignal) { _, signal in
            guard let signal else { return }
            turnTotalCaller.announceTurnTotal(signal.total)
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
                Text(L10n.botThrowing).foregroundStyle(Brand.amber)
            } else {
                EmptyView()
            }
        case .submittingTurn:
            Text(L10n.submittingTurn).foregroundStyle(.white)
        case .closureTransition:
            Text(L10n.boardUpdated).foregroundStyle(Brand.textSecondary)
        case let .entryInvalid(key), let .error(key):
            playLocalizedText(key).foregroundStyle(DS.ColorRole.danger)
        case .matchCompleted:
            Text(L10n.matchCompleteRoute).foregroundStyle(.white)
        }
    }
}
