import SwiftUI

struct LoopMatchScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: LoopMatchViewModel
    let onShowSummary: () -> Void
    let audio: any AudioFeedbackService
    let haptics: any HapticsService
    let feedbackPreferences: FeedbackPreferences
    @Environment(\.dismiss) private var dismiss
    @State private var showExitConfirmation = false
    @State private var actionTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            MatchGameplayHeader(onExit: { showExitConfirmation = true }) {
                VStack(alignment: .leading, spacing: 2) {
                    BrandMatchScreenTitle(title: "play.loop.navTitle")
                    Text(viewModel.headerText)
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                }
                .accessibilityIdentifier("loop_match_header")
            } trailing: {
                Button {
                    actionTask?.cancel()
                    actionTask = Task { await viewModel.undoLastTurn() }
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Brand.green)
                        .frame(width: 44, height: 44)
                        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                }
                .accessibilityLabel(L10n.scoringUndoLastTurn)
                .accessibilityIdentifier("loop_undo")
            }

            if let gameState = viewModel.loopState {
                SideBySideMatchBody(playerCount: gameState.players.count) {
                    VStack(spacing: DS.Spacing.s3) {
                        LoopTargetCardView(
                            target: gameState.target,
                            isOpening: gameState.needsOpeningTarget
                        )
                        LoopScoreboardView(rows: viewModel.scoreboardRows)
                        if viewModel.canPass {
                            Button {
                                actionTask?.cancel()
                                actionTask = Task { await viewModel.passTurn() }
                            } label: {
                                Text(L10n.string("play.loop.passTurn"))
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DS.Spacing.s2)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Brand.amber)
                        }
                    }
                } padChrome: {
                    stateBanner
                } controls: {
                    loopPad
                }
                .onChange(of: viewModel.enteredDarts) { old, darts in
                    guard viewModel.canHumanInput || viewModel.isBotPlaying else { return }
                    if darts.count > old.count, let dart = darts.last { playDartFeedback(dart) }
                    viewModel.processDartEntry(previousCount: old.count)
                }
            } else {
                Spacer()
                ProgressView().tint(Brand.textPrimary)
                    .accessibilityLabel(L10n.loading)
                Spacer()
            }
        }
        .frame(maxWidth: GameplayLayout.matchContentMaxWidth(horizontalSizeClass: horizontalSizeClass))
        .frame(maxWidth: .infinity)
        .background(Brand.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $viewModel.showWireTargetPicker) {
            if let dart = viewModel.pendingWireTargetDart {
                LoopWireTargetPickerView(
                    dart: dart,
                    options: viewModel.pendingWireTargetOptions,
                    onSelect: { viewModel.confirmWireTarget($0) }
                )
            }
        }
        .alert("play.match.exit.confirm.title", isPresented: $showExitConfirmation) {
            Button("common.stay", role: .cancel) {
                viewModel.recoverBotPlaybackIfNeeded()
            }
            Button("play.match.exit.saveAndExit") {
                showExitConfirmation = false
                viewModel.onDisappear()
                dismiss()
            }
            Button("play.match.exit.abandon", role: .destructive) {
                showExitConfirmation = false
                viewModel.onDisappear()
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
            case .matchCompleted:
                audio.playMatchFinished()
                onShowSummary()
            default:
                break
            }
        }
        .onChange(of: viewModel.enteredDarts) { old, darts in
            playBotDartEntryFeedback(
                darts: darts,
                previousCount: old.count,
                isBotPlaying: viewModel.isBotPlaying,
                audio: audio,
                haptics: haptics,
                feedbackPreferences: feedbackPreferences
            )
        }
        .task { await viewModel.onAppear() }
        .onDisappear {
            actionTask?.cancel()
            guard !showExitConfirmation else { return }
            viewModel.onDisappear()
        }
    }

    @ViewBuilder
    private var stateBanner: some View {
        switch viewModel.state {
        case let .entryInvalid(messageKey), let .error(messageKey):
            ErrorBanner(messageKey: messageKey)
        default:
            EmptyView()
        }
    }

    private var loopPad: some View {
        DartNumberPad(
            enteredDarts: $viewModel.enteredDarts,
            selectedMultiplier: $viewModel.selectedMultiplier,
            lockedSegment: nil,
            scoringSegmentsDisabled: false,
            showsBull: true,
            onUndoTurn: {
                actionTask?.cancel()
                actionTask = Task { await viewModel.undoLastDart() }
            }
        )
        .disabled(!viewModel.canHumanInput || viewModel.canPass)
        .opacity(viewModel.canHumanInput && !viewModel.canPass ? 1 : 0.55)
        .accessibilityHint(
            viewModel.canPass
                ? L10n.string("play.loop.pad.passOrThrowHint")
                : (viewModel.canHumanInput
                    ? L10n.string("play.loop.pad.hint")
                    : L10n.string("play.loop.pad.disabledWhileBot"))
        )
    }

    private func playDartFeedback(_ dart: DartInput) {
        if dart.isMiss { audio.playMiss() } else { audio.playHit() }
        haptics.playImpact()
    }
}
