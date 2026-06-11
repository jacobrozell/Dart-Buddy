import SwiftUI

struct BaseballMatchScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject var viewModel: BaseballMatchViewModel
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
                    BrandMatchScreenTitle(title: "play.baseball.title")
                    HStack(spacing: DS.Spacing.s2) {
                        Text(viewModel.headerText)
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                        if viewModel.showsExtraInningBadge {
                            Text(L10n.string("play.baseball.extraInning"))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Brand.amber)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(viewModel.headerAccessibilityLabel)
                    .accessibilityIdentifier("baseball_match_header")
                }
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
                .accessibilityIdentifier("baseball_undo")
            }

            if let state = viewModel.baseballState {
                SideBySideMatchBody {
                    scoreboardSection(state: state, includesBanner: false)
                } padChrome: {
                    stateBanner
                } controls: {
                    baseballPad
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
            case .perfectInningFeedback:
                haptics.playSuccess()
                // Match X01/Cricket: the visual banner is also announced to VoiceOver.
                AccessibilityNotification.Announcement(L10n.string("play.baseball.perfectInning")).post()
            default:
                break
            }
        }
        .onChange(of: viewModel.enteredDarts.count) { oldCount, newCount in
            guard viewModel.isBotPlaying, newCount > oldCount else { return }
            guard feedbackPreferences.botDartHapticsEnabled else { return }
            haptics.playImpact()
        }
        .task { await viewModel.onAppear() }
        .onDisappear {
            actionTask?.cancel()
            guard !showExitConfirmation else { return }
            viewModel.onDisappear()
        }
    }

    @ViewBuilder
    private func scoreboardSection(state: BaseballState, includesBanner: Bool = true) -> some View {
        VStack(spacing: DS.Spacing.s3) {
            BaseballScoreboardView(
                rows: viewModel.scoreboardRows,
                showsVisitRunsColumn: viewModel.showsVisitRunsColumn
            )
            if viewModel.showsInningProgressStrip {
                InningProgressStrip(
                    inningCount: state.config.inningCount,
                    currentInning: state.currentInning,
                    isExtraInning: state.isExtraInning
                )
                .accessibilityIdentifier("baseball_inning_strip")
            } else if state.phase == .bullPlayoff {
                Text(L10n.string("play.baseball.playoffStrip.label"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("baseball_playoff_strip")
            }
            if includesBanner {
                stateBanner
            }
        }
    }

    @ViewBuilder
    private var stateBanner: some View {
        switch viewModel.state {
        case let .entryInvalid(messageKey), let .error(messageKey):
            ErrorBanner(messageKey: messageKey)
        case .stretchGateHint:
            MatchFeedbackBanner(text: "play.baseball.stretchGateOpened", style: .cricketClosure)
        case .perfectInningFeedback:
            MatchFeedbackBanner(text: "play.baseball.perfectInning", style: .legWin)
                .accessibilityHidden(true)
        default:
            if let hint = viewModel.stretchGateHint {
                MatchFeedbackBanner(text: LocalizedStringKey(hint), style: .cricketClosure)
            }
        }
    }

    private var baseballPad: some View {
        DartNumberPad(
            enteredDarts: $viewModel.enteredDarts,
            selectedMultiplier: $viewModel.selectedMultiplier,
            lockedSegment: viewModel.lockedSegment,
            showsBull: viewModel.showsBullOnPad,
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
                : L10n.string("play.baseball.pad.disabledWhileBot")
        )
    }

    private var lockedSegmentHint: String? {
        guard viewModel.baseballState != nil else { return nil }
        if viewModel.baseballState?.phase == .bullPlayoff {
            return L10n.string("play.baseball.pad.lockedBullHint")
        }
        guard let segment = viewModel.lockedSegment else { return nil }
        return L10n.format("play.baseball.pad.lockedSegmentHint", segment)
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
