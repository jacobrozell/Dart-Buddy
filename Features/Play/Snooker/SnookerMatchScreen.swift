import SwiftUI

struct SnookerMatchScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: SnookerMatchViewModel
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
                    BrandMatchScreenTitle(title: "play.snooker.navTitle")
                    Text(viewModel.phaseBannerText)
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(viewModel.headerAccessibilityLabel)
                .accessibilityIdentifier("snooker_match_header")
            } trailing: {
                Button {
                    actionTask?.cancel()
                    actionTask = Task { await viewModel.undoLastDart() }
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Brand.green)
                        .frame(width: 44, height: 44)
                        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                }
                .accessibilityLabel(L10n.scoringUndoLastTurn)
                .accessibilityIdentifier("snooker_undo")
            }

            if let gameState = viewModel.snookerState {
                SideBySideMatchBody(playerCount: 2) {
                    VStack(spacing: DS.Spacing.s3) {
                        SnookerRedsTableView(availableReds: gameState.availableReds)
                        SnookerScoreboardView(
                            rows: viewModel.scoreboardRows,
                            breakPoints: gameState.currentBreakPoints
                        )
                    }
                } padChrome: {
                    stateBanner
                    if viewModel.isAwaitingNomination {
                        SnookerColourNominationView(
                            selectedColour: viewModel.pendingNominatedColour,
                            onSelect: { viewModel.selectNominatedColour($0) }
                        )
                        .padding(.horizontal, DS.Spacing.s3)
                        .padding(.bottom, DS.Spacing.s2)
                    }
                } controls: {
                    snookerPad
                }
                .onChange(of: viewModel.enteredDarts) { old, darts in
                    guard viewModel.canEnterDart else { return }
                    if darts.count > old.count, let dart = darts.last { playDartFeedback(dart) }
                    if darts.count == 1 { submitDart() }
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
            if case .matchCompleted = newValue {
                audio.playMatchFinished()
                onShowSummary()
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
        case let .error(messageKey):
            ErrorBanner(messageKey: messageKey)
        case .breakEndedFeedback:
            Text(L10n.string("play.snooker.breakEnded"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.amber)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DS.Spacing.s3)
        default:
            EmptyView()
        }
    }

    private var snookerPad: some View {
        DartNumberPad(
            enteredDarts: $viewModel.enteredDarts,
            selectedMultiplier: $viewModel.selectedMultiplier,
            lockedSegment: viewModel.lockedSegment,
            showsBull: viewModel.showsBull,
            onUndoTurn: {
                actionTask?.cancel()
                actionTask = Task { await viewModel.undoLastDart() }
            }
        )
        .disabled(!viewModel.canEnterDart)
        .opacity(viewModel.canEnterDart ? 1 : 0.55)
        .accessibilityHint(
            viewModel.canEnterDart
                ? (padHint ?? "")
                : L10n.string("play.snooker.pad.disabledWhileBot")
        )
    }

    private var padHint: String? {
        if viewModel.isAwaitingNomination, viewModel.pendingNominatedColour == nil {
            return L10n.string("play.snooker.pad.nominationHint")
        }
        if let segment = viewModel.lockedSegment {
            return L10n.format("play.snooker.pad.lockedSegmentHint", segment)
        }
        return L10n.string("play.snooker.pad.redHint")
    }

    private func playDartFeedback(_ dart: DartInput) {
        if dart.isMiss { audio.playMiss() } else { audio.playHit() }
        haptics.playImpact()
    }

    private func submitDart() {
        actionTask?.cancel()
        actionTask = Task { await viewModel.submitDart() }
    }
}
