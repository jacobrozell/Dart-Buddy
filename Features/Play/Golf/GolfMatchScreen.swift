import SwiftUI

struct GolfMatchScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: GolfMatchViewModel
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
                    BrandMatchScreenTitle(title: "play.golf.navTitle")
                    Text(viewModel.headerText)
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                    Text(viewModel.lastDartHint)
                        .font(.caption2)
                        .foregroundStyle(Brand.amber)
                        .accessibilityIdentifier("golf_last_dart_hint")
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(viewModel.headerAccessibilityLabel)
                .accessibilityIdentifier("golf_match_header")
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
                .accessibilityIdentifier("golf_undo")
            }

            if let golfState = viewModel.golfState {
                SideBySideMatchBody(playerCount: viewModel.scorecardRows.count) {
                    VStack(spacing: DS.Spacing.s3) {
                        GolfScorecardView(
                            rows: viewModel.scorecardRows,
                            courseLength: viewModel.courseLength
                        )
                        HoleProgressStrip(
                            courseLength: golfState.config.courseLength.rawValue,
                            currentHole: golfState.currentHole
                        )
                        .accessibilityIdentifier("golf_hole_strip")
                    }
                } padChrome: {
                    stateBanner
                } controls: {
                    golfControls
                }
                .onChange(of: viewModel.enteredDarts) { old, darts in
                    guard viewModel.canHumanInput else { return }
                    if darts.count > old.count, let dart = darts.last { playDartFeedback(dart) }
                    if darts.count == 3 { submitFull() }
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
            case .holeCompleteFeedback:
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
        .onDisappear {
            actionTask?.cancel()
            guard !showExitConfirmation else { return }
            viewModel.onDisappear()
        }
    }

    // MARK: - State banner

    @ViewBuilder
    private var stateBanner: some View {
        switch viewModel.state {
        case let .entryInvalid(messageKey), let .error(messageKey):
            ErrorBanner(messageKey: messageKey)
        case .holeCompleteFeedback:
            if let strokes = viewModel.currentStrokePreview {
                MatchFeedbackBanner(
                    text: LocalizedStringKey(L10n.format("play.golf.announce.holeComplete", strokes)),
                    style: .legWin
                )
                .accessibilityHidden(true)
                .accessibilityIdentifier("golf_hole_complete_feedback")
            }
        default:
            EmptyView()
        }
    }

    // MARK: - Controls

    private var golfControls: some View {
        VStack(spacing: DS.Spacing.s3) {
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
                    : L10n.string("play.golf.pad.disabledWhileBot")
            )

            // End turn early button — visible only when 1–2 darts entered by human
            if viewModel.canSubmitEarly {
                Button {
                    submitEarly()
                } label: {
                    Label(L10n.string("play.golf.endTurnEarly"), systemImage: "flag.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.s3)
                        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                }
                .accessibilityIdentifier("golf_end_turn_early")
            }
        }
    }

    private var lockedSegmentHint: String? {
        guard let segment = viewModel.lockedSegment else { return nil }
        return L10n.format("play.golf.pad.lockedHoleHint", segment)
    }

    // MARK: - Actions

    private func playDartFeedback(_ dart: DartInput) {
        if dart.isMiss { audio.playMiss() } else { audio.playHit() }
        haptics.playImpact()
    }

    private func submitFull() {
        actionTask?.cancel()
        actionTask = Task { await viewModel.submitTurn(endedEarly: false) }
    }

    private func submitEarly() {
        actionTask?.cancel()
        actionTask = Task { await viewModel.submitTurn(endedEarly: true) }
    }
}
