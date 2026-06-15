import SwiftUI

struct HareAndHoundsMatchScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: HareAndHoundsMatchViewModel
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
                    BrandMatchScreenTitle(title: "play.hareAndHounds.navTitle")
                    Text(viewModel.headerText)
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(viewModel.headerAccessibilityLabel)
                .accessibilityIdentifier("hareAndHounds_match_header")
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
                .accessibilityIdentifier("hareAndHounds_undo")
            }

            if viewModel.hareAndHoundsState != nil {
                SideBySideMatchBody(playerCount: viewModel.hareAndHoundsState?.players.count ?? 2) {
                    VStack(spacing: DS.Spacing.s3) {
                        HareAndHoundsDualTrackView(rows: viewModel.trackRows)
                            .accessibilityIdentifier("hareAndHounds_dual_track")
                    }
                } padChrome: {
                    stateBanner
                } controls: {
                    hareAndHoundsPad
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
            case .positionAdvancedFeedback:
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

    @ViewBuilder
    private var stateBanner: some View {
        switch viewModel.state {
        case let .entryInvalid(messageKey), let .error(messageKey):
            ErrorBanner(messageKey: messageKey)
        case .positionAdvancedFeedback:
            MatchFeedbackBanner(text: "play.hareAndHounds.positionAdvanced", style: .legWin)
                .accessibilityHidden(true)
                .accessibilityIdentifier("hareAndHounds_position_advanced_feedback")
        default:
            EmptyView()
        }
    }

    private var hareAndHoundsPad: some View {
        DartNumberPad(
            enteredDarts: $viewModel.enteredDarts,
            selectedMultiplier: $viewModel.selectedMultiplier,
            lockedSegment: viewModel.lockedSegment,
            scoringSegmentsDisabled: viewModel.scoringSegmentsDisabled,
            showsBull: false,
            onUndoTurn: {
                actionTask?.cancel()
                actionTask = Task { await viewModel.undoLastDart() }
            }
        )
        .disabled(!viewModel.canHumanInput)
        .opacity(viewModel.canHumanInput ? 1 : 0.55)
        .accessibilityHint(
            viewModel.canHumanInput
                ? (lockedSegmentHint ?? "")
                : L10n.string("play.hareAndHounds.pad.disabledWhileBot")
        )
    }

    private var lockedSegmentHint: String? {
        guard let segment = viewModel.lockedSegment else { return nil }
        return L10n.format("play.hareAndHounds.pad.lockedSegmentHint", segment)
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
