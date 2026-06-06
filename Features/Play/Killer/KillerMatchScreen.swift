import SwiftUI

struct KillerMatchScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: KillerMatchViewModel
    let onShowSummary: () -> Void
    let audio: any AudioFeedbackService
    let haptics: any HapticsService
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
                ScrollView {
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
                    .padding(.horizontal, DS.Spacing.s4)
                    .padding(.bottom, DS.Spacing.s2)
                }

                VStack(spacing: DS.Spacing.s2) {
                    killerPad
                    submitButton
                }
                .padding(.horizontal, DS.Spacing.s4)
                .padding(.bottom, DS.Spacing.s2)
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
            case .becameKillerFeedback:
                haptics.playSuccess()
            default:
                break
            }
        }
        .task { await viewModel.onAppear() }
        .onDisappear { actionTask?.cancel() }
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
        .disabled(viewModel.state == .submittingTurn)
        .opacity(viewModel.state == .submittingTurn ? 0.55 : 1)
    }

    private var submitButton: some View {
        Button {
            actionTask?.cancel()
            actionTask = Task { await viewModel.submitTurn() }
        } label: {
            Text(submitButtonTitle)
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .tint(Brand.green)
        .disabled(!viewModel.canSubmit)
        .accessibilityIdentifier("killer_submit")
    }

    private var submitButtonTitle: String {
        if viewModel.isPickPhase {
            L10n.string("play.killer.submitPick")
        } else {
            L10n.string("scoring.submitTurn")
        }
    }
}
