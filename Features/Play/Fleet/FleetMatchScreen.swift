import SwiftUI

struct FleetMatchScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var viewModel: FleetMatchViewModel
    let onShowSummary: () -> Void
    let audio: any AudioFeedbackService
    let haptics: any HapticsService
    let feedbackPreferences: FeedbackPreferences
    let lifecycleDependencies: MatchLifecycleChromeDependencies
    @Environment(\.dismiss) private var dismiss
    @State private var showExitConfirmation = false
    @State private var actionTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                MatchGameplayHeader(onExit: { showExitConfirmation = true }) {
                    BrandMatchScreenTitle(title: "play.fleet.navTitle")
                } trailing: {
                    if viewModel.isHuntPhase {
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
                        .accessibilityIdentifier("fleet_undo")
                    }
                }

                if let fleetState = viewModel.fleetState {
                    switch fleetState.phase {
                    case .placement:
                        placementContent(fleetState: fleetState)
                    case .hunt:
                        huntContent(fleetState: fleetState)
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

            if viewModel.showPrivacyShield {
                privacyShield
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .matchLifecycleChrome(
            host: viewModel,
            showExitConfirmation: $showExitConfirmation,
            onShowSummary: onShowSummary,
            onDismiss: { dismiss() },
            dependencies: lifecycleDependencies
        )
        .confirmationDialog(
            "play.fleet.placement.lockConfirmTitle",
            isPresented: $viewModel.showLockConfirm,
            titleVisibility: .visible
        ) {
            Button("play.fleet.placement.lock", role: .destructive) {
                actionTask = Task { await viewModel.lockFleet() }
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("play.fleet.placement.lockConfirmBody")
        }
        .alert("play.fleet.handoff.wrongPlayerWarning", isPresented: $viewModel.showWrongPlayerAlert) {
            Button("common.ok", role: .cancel) {}
        }
        .onChange(of: viewModel.state) { _, newValue in
            if case .matchCompleted = newValue {
                audio.playMatchFinished()
                onShowSummary()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            viewModel.onScenePhaseChanged(phase)
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
    private func placementContent(fleetState: FleetState) -> some View {
        switch fleetState.placementUIStep {
        case let .handoff(playerId):
            handoffGate(playerId: playerId)
        case let .placing(playerId) where viewModel.canViewPlacement:
            placementGrid(playerId: playerId, fleetState: fleetState)
        case let .passDevice(playerId):
            passDeviceCurtain(nextPlayerId: playerId)
        case .placing, .placementComplete:
            ProgressView().tint(Brand.textPrimary)
                .accessibilityLabel(L10n.loading)
        }
    }

    private func handoffGate(playerId: UUID) -> some View {
        VStack(spacing: DS.Spacing.s4) {
            Spacer()
            Text(L10n.format("play.fleet.handoff.titleFormat", viewModel.playerName(for: playerId)))
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.textPrimary)
                .multilineTextAlignment(.center)
            Text("play.fleet.handoff.body")
                .font(.body)
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)
            Button("play.fleet.handoff.confirmIdentity") {
                actionTask = Task { await viewModel.confirmHandoff(for: playerId) }
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("fleet_handoff_confirm")
            Spacer()
        }
        .padding(DS.Spacing.s4)
    }

    private func passDeviceCurtain(nextPlayerId: UUID) -> some View {
        VStack(spacing: DS.Spacing.s4) {
            Spacer()
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 44))
                .foregroundStyle(Brand.textSecondary)
            Text("play.fleet.passDevice.title")
                .font(.title2.weight(.bold))
            Text(L10n.format("play.fleet.passDevice.bodyFormat", viewModel.playerName(for: nextPlayerId)))
                .font(.body)
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)
            Button(L10n.format("play.fleet.passDevice.confirmIdentity", viewModel.playerName(for: nextPlayerId))) {
                actionTask = Task { await viewModel.confirmPassDevice(for: nextPlayerId) }
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("fleet_pass_device_confirm")
            Spacer()
        }
        .padding(DS.Spacing.s4)
    }

    private func placementGrid(playerId: UUID, fleetState: FleetState) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                Text(L10n.format(
                    "play.fleet.placement.shipsPlacedFormat",
                    viewModel.shipsPlacedCount,
                    viewModel.requiredShipCount
                ))
                .font(.headline)
                Text("play.fleet.placement.hint")
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)

                if let model = viewModel.placementModel(for: playerId) {
                    FleetBoardGridView(
                        mode: model,
                        bullAllowed: fleetState.config.bullAllowed,
                        onCellTap: { cell in
                            actionTask = Task { await viewModel.togglePlacementCell(cell) }
                        }
                    )
                }

                HStack(spacing: DS.Spacing.s3) {
                    Button("play.fleet.placement.clearAll") {
                        actionTask = Task { await viewModel.clearPlacement() }
                    }
                    .buttonStyle(.bordered)
                    Button("play.fleet.placement.lock") {
                        viewModel.showLockConfirm = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canLockFleet)
                }
            }
            .padding(DS.Spacing.s4)
        }
    }

    private func huntContent(fleetState: FleetState) -> some View {
        let hunterId = fleetState.currentPlayerId
        return VStack(spacing: DS.Spacing.s3) {
            Text(L10n.format("play.fleet.hunt.turnFormat", viewModel.playerName(for: hunterId)))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DS.Spacing.s4)

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                    Text("play.fleet.hunt.yourWaters")
                        .font(.subheadline.weight(.semibold))
                    if let own = viewModel.ownBoardModel(for: hunterId) {
                        FleetBoardGridView(mode: own, bullAllowed: fleetState.config.bullAllowed)
                    }

                    Text("play.fleet.hunt.enemyWaters")
                        .font(.subheadline.weight(.semibold))
                    if let fog = viewModel.enemyFogModel(for: hunterId) {
                        FleetBoardGridView(
                            mode: fog,
                            bullAllowed: fleetState.config.bullAllowed,
                            onCellTap: viewModel.canHumanInput ? { viewModel.selectCall($0) } : nil
                        )
                    }

                    if let call = viewModel.selectedCall {
                        Text(L10n.format("play.fleet.callFormat", callLabel(call)))
                            .font(.caption.weight(.semibold))
                    }
                    Text("play.fleet.damageLegend")
                        .font(.caption2)
                        .foregroundStyle(Brand.textSecondary)

                    if let sonar = viewModel.sonarResult {
                        Text(sonar ? "play.fleet.sonar.resultYes" : "play.fleet.sonar.resultNo")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Brand.amber)
                    }
                }
                .padding(.horizontal, DS.Spacing.s4)
            }

            DartNumberPad(
                enteredDarts: $viewModel.enteredDarts,
                selectedMultiplier: $viewModel.selectedMultiplier,
                lockedSegment: lockedSegment(for: viewModel.selectedCall),
                showsBull: fleetState.config.bullAllowed,
                onUndoTurn: {
                    actionTask?.cancel()
                    actionTask = Task { await viewModel.undoLastDart() }
                }
            )
            .disabled(!viewModel.canHumanInput || viewModel.selectedCall == nil)
            .opacity(viewModel.canHumanInput ? 1 : 0.55)
            .onChange(of: viewModel.enteredDarts) { old, darts in
                guard viewModel.canHumanInput else { return }
                if darts.count > old.count, let dart = darts.last {
                    if dart.isMiss { audio.playMiss() } else { audio.playHit() }
                    haptics.playImpact()
                }
                if darts.count == 1 {
                    actionTask = Task { await viewModel.submitDart() }
                }
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s3)
        }
    }

    private var privacyShield: some View {
        ZStack {
            LinearGradient(colors: [Brand.proBot, Brand.background], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: DS.Spacing.s3) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 36))
                Text("play.fleet.privacyShield.label")
                    .font(.headline)
            }
            .foregroundStyle(Brand.textOnAccent)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.string("play.fleet.privacyShield.label"))
    }

    private func callLabel(_ cell: FleetBoardCell) -> String {
        switch cell {
        case let .segment(value): return "\(value)"
        case .bull: return L10n.string("scoring.segment.bull")
        }
    }

    private func lockedSegment(for call: FleetBoardCell?) -> Int? {
        guard let call else { return nil }
        if case let .segment(value) = call { return value }
        return nil
    }
}
