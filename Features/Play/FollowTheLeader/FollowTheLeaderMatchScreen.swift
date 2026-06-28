import SwiftUI

struct FollowTheLeaderMatchScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: FollowTheLeaderMatchViewModel
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
                    BrandMatchScreenTitle(title: "play.followTheLeader.navTitle")
                    Text(viewModel.headerText)
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                }
                .accessibilityIdentifier("followTheLeader_match_header")
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
                .accessibilityIdentifier("followTheLeader_undo")
            }

            if let gameState = viewModel.followTheLeaderState {
                SideBySideMatchBody(playerCount: gameState.players.count) {
                    VStack(spacing: DS.Spacing.s3) {
                        FollowTheLeaderTargetCardView(
                            target: gameState.target,
                            isOpening: gameState.needsOpeningTarget
                        )
                        FollowTheLeaderScoreboardView(rows: viewModel.scoreboardRows)
                        if viewModel.canPass {
                            Button {
                                actionTask?.cancel()
                                actionTask = Task { await viewModel.passTurn() }
                            } label: {
                                Text(L10n.string("play.followTheLeader.passTurn"))
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
                    followTheLeaderPad
                }
                .onChange(of: viewModel.enteredDarts) { old, darts in
                    guard viewModel.canHumanInput else { return }
                    if darts.count > old.count, let dart = darts.last { playDartFeedback(dart) }
                    let maxDarts = viewModel.maxDartsPerSubmission
                    if darts.count == maxDarts { submitTurn() }
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

    private var followTheLeaderPad: some View {
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
                ? L10n.string("play.followTheLeader.pad.passOrThrowHint")
                : (viewModel.canHumanInput
                    ? L10n.string("play.followTheLeader.pad.hint")
                    : L10n.string("play.followTheLeader.pad.disabledWhileBot"))
        )
    }

    private func playDartFeedback(_ dart: DartInput) {
        if dart.isMiss { audio.playMiss() } else { audio.playHit() }
        haptics.playImpact()
    }

    private func submitTurn() {
        actionTask?.cancel()
        actionTask = Task { await viewModel.submitTurn() }
    }
}
