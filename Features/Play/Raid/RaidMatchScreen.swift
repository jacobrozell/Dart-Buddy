import SwiftUI

struct RaidMatchScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: RaidMatchViewModel
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
                    BrandMatchScreenTitle(title: "play.raid.navTitle")
                    Text(viewModel.headerText)
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L10n.string("play.raid.navTitle") + ", " + viewModel.headerText)
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
                .accessibilityIdentifier("match_undo")
            }

            if let raidState = viewModel.raidState {
                ScrollView {
                    VStack(spacing: DS.Spacing.s3) {
                        CoopBossChromeView(
                            bossHP: raidState.bossHP,
                            bossMaxHP: raidState.bossMaxHP,
                            phase: raidState.phase,
                            enrageActive: raidState.enrageActive,
                            heroes: viewModel.coopChromeHeroes
                        )
                        if raidState.phase == .shield {
                            raidShieldLegend
                        } else {
                            raidExposeLegend
                        }
                        DartNumberPad(
                            enteredDarts: $viewModel.enteredDarts,
                            selectedMultiplier: $viewModel.selectedMultiplier,
                            showsBull: true,
                            onUndoTurn: {
                                actionTask?.cancel()
                                actionTask = Task { await viewModel.undoLastDart() }
                            }
                        )
                        .disabled(!viewModel.canHumanInput)
                        .opacity(viewModel.canHumanInput ? 1 : 0.55)
                    }
                    .padding(.horizontal, DS.Spacing.s4)
                    .padding(.vertical, DS.Spacing.s3)
                }
                .onChange(of: viewModel.enteredDarts) { old, darts in
                    guard viewModel.canHumanInput else { return }
                    if darts.count > old.count, let dart = darts.last {
                        if feedbackPreferences.hapticsEnabled { haptics.playImpact() }
                        if dart.isMiss { audio.playMiss() } else { audio.playHit() }
                    }
                    if darts.count == 3 {
                        actionTask?.cancel()
                        actionTask = Task { await viewModel.submitTurn() }
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
        .matchLifecycleChrome(
            host: viewModel,
            showExitConfirmation: $showExitConfirmation,
            onShowSummary: onShowSummary,
            onDismiss: { dismiss() },
            dependencies: lifecycleDependencies
        )
        .onChange(of: viewModel.state) { _, newValue in
            if case .matchCompleted = newValue {
                audio.playMatchFinished()
                onShowSummary()
            }
        }
        .task { await viewModel.onAppear() }
        .onDisappear {
            actionTask?.cancel()
            guard !showExitConfirmation else { return }
            viewModel.onDisappear()
        }
    }

    private var raidShieldLegend: some View {
        Text(L10n.string("play.raid.legend.shield"))
            .font(.caption)
            .foregroundStyle(Brand.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var raidExposeLegend: some View {
        Text(L10n.string("play.raid.legend.expose"))
            .font(.caption)
            .foregroundStyle(Brand.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
