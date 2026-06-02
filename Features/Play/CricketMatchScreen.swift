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
        VStack(spacing: 0) {
            MatchGameplayHeader(onExit: { showExitConfirmation = true }) {
                Text(L10n.cricketTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }

            if let state = viewModel.cricketState {
                Text(L10n.format("play.cricket.roundTurn", state.roundIndex + 1, state.currentPlayerIndex + 1))
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DS.Spacing.s4)
                    .padding(.bottom, DS.Spacing.s2)

                CricketBoardPlayerHeaderRow(columns: viewModel.boardColumns)
                    .padding(.horizontal, DS.Spacing.s4)

                ScrollView {
                    CricketBoardMarksGrid(columns: viewModel.boardColumns)
                        .padding(.horizontal, DS.Spacing.s4)
                }

                VStack(spacing: DS.Spacing.s2) {
                    stateBanner
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
                    .accessibilityElement(children: .contain)
                    .modifier(
                        OptionalAccessibilityHint(
                            hint: viewModel.canHumanInput ? nil : L10n.string("play.cricket.pad.disabledWhileBot")
                        )
                    )
                    .onChange(of: viewModel.enteredDarts) { old, darts in
                        guard viewModel.canHumanInput else { return }
                        if darts.count > old.count, let dart = darts.last { playDartFeedback(dart) }
                        if darts.count == 3 { submit() }
                    }
                }
                .padding(.horizontal, DS.Spacing.s4)
                .padding(.top, DS.Spacing.s2)
                .padding(.bottom, DS.Spacing.s2)
            } else {
                Spacer()
                ProgressView().tint(.white)
                Spacer()
            }
        }
        .frame(maxWidth: contentMaxWidth)
        .frame(maxWidth: .infinity)
        .background(Brand.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
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
            switch newValue {
            case .closureTransition:
                postAccessibilityAnnouncement(L10n.string("play.cricket.boardUpdated"))
            case .matchCompleted:
                audio.playMatchFinished()
                onShowSummary()
            default:
                break
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

    private func postAccessibilityAnnouncement(_ text: String) {
        guard !text.isEmpty else { return }
        AccessibilityNotification.Announcement(text).post()
    }

    @ViewBuilder
    private var stateBanner: some View {
        switch viewModel.state {
        case .readyTurn:
            if viewModel.isBotPlaying {
                Text(L10n.botThrowing)
                    .foregroundStyle(Brand.amber)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(L10n.string("play.match.botThrowing"))
            } else {
                EmptyView()
            }
        case .submittingTurn:
            Text(L10n.submittingTurn).foregroundStyle(.white)
        case .closureTransition:
            Text(L10n.boardUpdated)
                .foregroundStyle(Brand.textSecondary)
                .accessibilityIdentifier("cricketBoardUpdatedBanner")
        case let .entryInvalid(key), let .error(key):
            playLocalizedText(key).foregroundStyle(DS.ColorRole.danger)
        case .matchCompleted:
            Text(L10n.matchCompleteRoute).foregroundStyle(.white)
        }
    }
}
