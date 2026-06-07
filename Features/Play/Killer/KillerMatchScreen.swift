import SwiftUI

struct KillerMatchScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: KillerMatchViewModel
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
                    BrandMatchScreenTitle(title: "play.killer.title")
                    Text(viewModel.headerText)
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                        .accessibilityIdentifier("killer_match_header")
                    if let hint = viewModel.targetHint {
                        Text(hint)
                            .font(.caption2)
                            .foregroundStyle(Brand.amber)
                    }
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
                .accessibilityIdentifier("killer_undo")
            }

            if viewModel.killerState != nil {
                SideBySideMatchBody {
                    VStack(spacing: DS.Spacing.s3) {
                        KillerScoreboardView(rows: viewModel.scoreboardRows)
                        if viewModel.isPickPhase {
                            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                                Text(L10n.string("play.killer.pickReminder"))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Brand.textSecondary)
                                KillerNumberGridView(assignments: viewModel.numberGridAssignments)
                            }
                        }
                        stateBanner
                    }
                } controls: {
                    killerPad
                    if showsPartialTurnSubmit {
                        submitButton
                    }
                }
                .onChange(of: viewModel.enteredDarts) { old, darts in
                    guard viewModel.canHumanInput else { return }
                    let threshold = viewModel.maxDartsPerSubmission
                    if darts.count > old.count, darts.count == threshold {
                        submitTurn()
                    }
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
            case .becameKillerFeedback:
                haptics.playSuccess()
                // Match X01/Cricket: the visual banner is also announced to VoiceOver.
                AccessibilityNotification.Announcement(L10n.string("play.killer.becameKiller")).post()
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
    private var stateBanner: some View {
        switch viewModel.state {
        case let .entryInvalid(messageKey), let .error(messageKey):
            ErrorBanner(messageKey: messageKey)
        case .becameKillerFeedback:
            MatchFeedbackBanner(text: "play.killer.becameKiller", style: .legWin)
        default:
            EmptyView()
        }
    }

    private var killerPad: some View {
        DartNumberPad(
            enteredDarts: $viewModel.enteredDarts,
            selectedMultiplier: $viewModel.selectedMultiplier,
            lockedSegment: nil,
            showsBull: viewModel.isPickPhase,
            maxDarts: viewModel.maxDartsPerSubmission,
            onUndoTurn: {
                actionTask?.cancel()
                actionTask = Task { await viewModel.undoLastDart() }
            }
        )
        .disabled(!viewModel.canHumanInput || viewModel.state == .submittingTurn)
        .opacity(viewModel.canHumanInput && viewModel.state != .submittingTurn ? 1 : 0.55)
        .accessibilityHint(
            viewModel.canHumanInput
                ? ""
                : L10n.string("play.killer.pad.disabledWhileBot")
        )
    }

    private var showsPartialTurnSubmit: Bool {
        !viewModel.isPickPhase
            && (1 ... 2).contains(viewModel.enteredDarts.count)
            && viewModel.canHumanInput
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
        .accessibilityIdentifier("killer_submit")
    }

    private func submitTurn() {
        actionTask?.cancel()
        actionTask = Task { await viewModel.submitTurn() }
    }
}
