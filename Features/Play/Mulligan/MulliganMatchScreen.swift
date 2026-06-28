import SwiftUI

struct MulliganMatchScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: MulliganMatchViewModel
    let onShowSummary: () -> Void
    let audio: any AudioFeedbackService
    let haptics: any HapticsService
    let feedbackPreferences: FeedbackPreferences
    let lifecycleDependencies: MatchLifecycleChromeDependencies
    @Environment(\.dismiss) private var dismiss
    @State private var showExitConfirmation = false
    @State private var actionTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            MatchGameplayHeader(onExit: { showExitConfirmation = true }) {
                VStack(alignment: .leading, spacing: 2) {
                    BrandMatchScreenTitle(title: "play.mulligan.navTitle")
                    if let target = viewModel.activeTarget {
                        Text(L10n.format("play.mulligan.activeTargetFormat", target.displayLabel))
                            .font(.caption)
                            .foregroundStyle(Brand.amber)
                            .accessibilityIdentifier("mulligan_active_target")
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(headerAccessibilityLabel)
                .accessibilityIdentifier("mulligan_match_header")
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
                .accessibilityIdentifier("mulligan_undo")
            }

            if let gameState = viewModel.mulliganState {
                SideBySideMatchBody(playerCount: gameState.players.count) {
                    VStack(spacing: DS.Spacing.s3) {
                        // Drawn target strip
                        VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                            Text(L10n.string("play.mulligan.drawnTargets.title"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Brand.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityIdentifier("mulligan_drawn_targets_title")
                            MulliganTargetStrip(
                                sequence: viewModel.targetSequence,
                                currentIndex: viewModel.currentTargetIndex,
                                isComplete: gameState.isComplete
                            )
                            .accessibilityIdentifier("mulligan_target_strip")
                        }

                        MulliganScoreboardView(rows: viewModel.scoreboardRows)
                    }
                } padChrome: {
                    stateBanner
                } controls: {
                    mulliganPad
                }
                .onChange(of: viewModel.enteredDarts) { old, darts in
                    guard viewModel.canHumanInput else { return }
                    if darts.count > old.count, let dart = darts.last { playDartFeedback(dart) }
                    if darts.count == 3 { submitTurn() }
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
        .matchLifecycleChrome(
            host: viewModel,
            showExitConfirmation: $showExitConfirmation,
            onShowSummary: onShowSummary,
            onDismiss: { dismiss() },
            dependencies: lifecycleDependencies
        )
        .onChange(of: viewModel.state) { _, newValue in
            switch newValue {
            case .matchCompleted:
                audio.playMatchFinished()
                onShowSummary()
            case .targetAdvanced:
                haptics.playSuccess()
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

    // MARK: - Subviews

    @ViewBuilder
    private var stateBanner: some View {
        switch viewModel.state {
        case let .entryInvalid(messageKey), let .error(messageKey):
            ErrorBanner(messageKey: messageKey)
        case .targetAdvanced:
            if let target = viewModel.activeTarget {
                MatchFeedbackBanner(
                    text: LocalizedStringKey(L10n.format("play.mulligan.targetAdvanced", target.displayLabel)),
                    style: .legWin
                )
                .accessibilityHidden(true)
                .accessibilityIdentifier("mulligan_target_advanced_banner")
            }
        default:
            EmptyView()
        }
    }

    private var mulliganPad: some View {
        DartNumberPad(
            enteredDarts: $viewModel.enteredDarts,
            selectedMultiplier: $viewModel.selectedMultiplier,
            lockedSegment: viewModel.lockedSegmentNumber,
            showsBull: viewModel.isLockedToBull,
            onUndoTurn: {
                actionTask?.cancel()
                actionTask = Task { await viewModel.undoLastDart() }
            }
        )
        .disabled(!viewModel.canHumanInput)
        .opacity(viewModel.canHumanInput ? 1 : 0.55)
        .accessibilityHint(
            viewModel.canHumanInput
                ? (lockedPadHint ?? "")
                : L10n.string("play.mulligan.pad.disabledWhileBot")
        )
    }

    private var lockedPadHint: String? {
        guard let target = viewModel.activeTarget else { return nil }
        return L10n.format("play.mulligan.pad.lockedTargetHint", target.displayLabel)
    }

    private var headerAccessibilityLabel: String {
        var parts = [L10n.string("play.mulligan.navTitle")]
        if let target = viewModel.activeTarget {
            parts.append(L10n.format("play.mulligan.activeTargetFormat", target.displayLabel))
        }
        return parts.joined(separator: ", ")
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
