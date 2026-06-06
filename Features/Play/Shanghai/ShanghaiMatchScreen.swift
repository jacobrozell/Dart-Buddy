import SwiftUI

struct ShanghaiMatchScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: ShanghaiMatchViewModel
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
                    BrandMatchScreenTitle(title: "play.shanghai.title")
                    HStack(spacing: DS.Spacing.s2) {
                        Text(viewModel.headerText)
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                        if viewModel.showsExtraRoundBadge {
                            Text(L10n.string("play.shanghai.extraRound"))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Brand.amber)
                        }
                    }
                    if let scoringHint = viewModel.scoringHint {
                        Text(scoringHint)
                            .font(.caption2)
                            .foregroundStyle(Brand.amber)
                            .accessibilityIdentifier("shanghai_scoring_hint")
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(viewModel.headerAccessibilityLabel)
                .accessibilityIdentifier("shanghai_match_header")
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
                .accessibilityIdentifier("shanghai_undo")
            }

            if let state = viewModel.shanghaiState {
                ScrollView {
                    VStack(spacing: DS.Spacing.s3) {
                        Text(viewModel.goalReminder)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Brand.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("shanghai_goal_reminder")
                        ShanghaiScoreboardView(
                            rows: viewModel.scoreboardRows,
                            showsRoundPointsColumn: viewModel.showsRoundPointsColumn
                        )
                        RoundProgressStrip(
                            roundCount: state.config.roundCount,
                            currentRound: state.currentRound,
                            isExtraRound: state.isExtraRound
                        )
                        .accessibilityIdentifier("shanghai_round_strip")
                        stateBanner
                    }
                    .padding(.horizontal, DS.Spacing.s4)
                    .padding(.bottom, DS.Spacing.s2)
                }

                VStack(spacing: DS.Spacing.s2) {
                    shanghaiPad
                    submitButton
                }
                .padding(.horizontal, DS.Spacing.s4)
                .padding(.bottom, DS.Spacing.s2)
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
            case .matchCompleted:
                audio.playMatchFinished()
                onShowSummary()
            case .shanghaiFeedback:
                haptics.playSuccess()
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
        .onDisappear { actionTask?.cancel() }
    }

    @ViewBuilder
    private var stateBanner: some View {
        switch viewModel.state {
        case let .entryInvalid(messageKey), let .error(messageKey):
            ErrorBanner(messageKey: messageKey)
        case .shanghaiFeedback:
            MatchFeedbackBanner(text: "play.shanghai.achieved", style: .legWin)
                .accessibilityIdentifier("shanghai_shanghai_feedback")
        default:
            EmptyView()
        }
    }

    private var shanghaiPad: some View {
        DartNumberPad(
            enteredDarts: $viewModel.enteredDarts,
            selectedMultiplier: $viewModel.selectedMultiplier,
            lockedSegment: viewModel.lockedSegment,
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
                : L10n.string("play.shanghai.pad.disabledWhileBot")
        )
    }

    private var lockedSegmentHint: String? {
        guard let segment = viewModel.lockedSegment else { return nil }
        return L10n.format("play.shanghai.pad.lockedSegmentHint", segment)
    }

    private var submitButton: some View {
        Button(action: submitTurn) {
            Text(L10n.string("scoring.submitTurn"))
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .tint(Brand.green)
        .disabled(!viewModel.canSubmit)
        .accessibilityLabel(L10n.string("scoring.submitTurn"))
        .accessibilityIdentifier("shanghai_submit")
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
