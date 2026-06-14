import SwiftUI

struct MatchLifecycleChromeDependencies {
    let store: ActiveMatchStore
    let matchRepository: any MatchRepository
    let logger: any AppLogger
}

struct MatchExitConfirmationModifier: ViewModifier {
    @Binding var isPresented: Bool
    let canForfeit: Bool
    let isBotTurnBlocking: Bool
    let onStay: () -> Void
    let onSaveAndExit: () -> Void
    let onSaveAndForfeit: () -> Void
    let onAbandon: () -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            "play.match.exit.confirm.title",
            isPresented: $isPresented,
            titleVisibility: .visible
        ) {
            Button("play.match.exit.saveAndExit") {
                onSaveAndExit()
            }
            .accessibilityIdentifier("match_exit_save_and_exit")
            if canForfeit {
                Button("play.match.exit.saveAndForfeit", role: .destructive) {
                    onSaveAndForfeit()
                }
                .disabled(isBotTurnBlocking)
                .accessibilityIdentifier("match_exit_save_and_forfeit")
                .accessibilityLabel("play.match.exit.saveAndForfeit.accessibility")
                .accessibilityHint(isBotTurnBlocking ? "play.match.exit.disabledWhileBot" : "")
            }
            Button("play.match.exit.abandon", role: .destructive) {
                onAbandon()
            }
            .disabled(isBotTurnBlocking)
            .accessibilityIdentifier("match_exit_abandon")
            .accessibilityHint(isBotTurnBlocking ? "play.match.exit.disabledWhileBot" : "")
            Button("common.stay", role: .cancel) {
                onStay()
            }
            .accessibilityIdentifier("match_exit_stay")
        } message: {
            Text("play.match.exit.confirm.message")
        }
    }
}

private struct MatchLifecycleChromeModifier<Host: MatchPlaySessionHost>: ViewModifier {
    @ObservedObject var host: Host
    @Binding var showExitConfirmation: Bool
    @State private var forfeitCoordinator: MatchForfeitCoordinator
    @State private var skipDisappearAbandon = false
    @State private var abandonTask: Task<Void, Never>?

    let onShowSummary: () -> Void
    let onDismiss: () -> Void

    init(
        host: Host,
        showExitConfirmation: Binding<Bool>,
        dependencies: MatchLifecycleChromeDependencies,
        onShowSummary: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.host = host
        _showExitConfirmation = showExitConfirmation
        _forfeitCoordinator = State(initialValue: MatchForfeitCoordinator(
            store: dependencies.store,
            matchRepository: dependencies.matchRepository,
            logger: dependencies.logger
        ))
        self.onShowSummary = onShowSummary
        self.onDismiss = onDismiss
    }

    func body(content: Content) -> some View {
        content
            .modifier(MatchExitConfirmationModifier(
                isPresented: $showExitConfirmation,
                canForfeit: forfeitCoordinator.canForfeit,
                isBotTurnBlocking: host.isBotTurnBlocking,
                onStay: { host.recoverBotPlaybackIfNeeded() },
                onSaveAndExit: {
                    showExitConfirmation = false
                    host.onDisappear()
                    onDismiss()
                },
                onSaveAndForfeit: {
                    showExitConfirmation = false
                    forfeitCoordinator.beginForfeitFlow()
                },
                onAbandon: {
                    showExitConfirmation = false
                    host.onDisappear()
                    abandonTask?.cancel()
                    abandonTask = Task {
                        await host.abandonMatch()
                        onDismiss()
                    }
                }
            ))
            .sheet(isPresented: pickPlayerBinding) {
                ForfeitPlayerPickerSheet(host: host, coordinator: forfeitCoordinator)
            }
            .sheet(isPresented: pickWinnerBinding) {
                ForfeitWinnerPickerSheet(coordinator: forfeitCoordinator)
            }
            .sheet(isPresented: confirmBinding) {
                ForfeitFinalConfirmSheet(host: host, coordinator: forfeitCoordinator) {
                    skipDisappearAbandon = true
                    Task {
                        await forfeitCoordinator.confirmForfeit()
                        onShowSummary()
                    }
                }
            }
            .onAppear {
                forfeitCoordinator.configure(host: host) {
                    skipDisappearAbandon = true
                }
            }
            .onDisappear {
                abandonTask?.cancel()
                if skipDisappearAbandon { return }
            }
    }

    private var pickPlayerBinding: Binding<Bool> {
        Binding(
            get: { forfeitCoordinator.flowState == .pickPlayer },
            set: { if !$0 { forfeitCoordinator.cancelFlow() } }
        )
    }

    private var pickWinnerBinding: Binding<Bool> {
        Binding(
            get: { forfeitCoordinator.flowState == .pickWinner },
            set: { if !$0 { forfeitCoordinator.cancelFlow() } }
        )
    }

    private var confirmBinding: Binding<Bool> {
        Binding(
            get: { forfeitCoordinator.flowState == .confirm || forfeitCoordinator.flowState == .persisting },
            set: { if !$0, forfeitCoordinator.flowState != .persisting { forfeitCoordinator.cancelFlow() } }
        )
    }
}

extension View {
    func matchLifecycleChrome<Host: MatchPlaySessionHost>(
        host: Host,
        showExitConfirmation: Binding<Bool>,
        onShowSummary: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        dependencies: MatchLifecycleChromeDependencies
    ) -> some View {
        modifier(MatchLifecycleChromeModifier(
            host: host,
            showExitConfirmation: showExitConfirmation,
            dependencies: dependencies,
            onShowSummary: onShowSummary,
            onDismiss: onDismiss
        ))
    }
}

private struct ForfeitPlayerPickerSheet<Host: MatchPlaySessionHost>: View {
    @ObservedObject var host: Host
    @Bindable var coordinator: MatchForfeitCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let session = host.session {
                    ForEach(MatchForfeitParticipantSupport.humanParticipantIds(in: session), id: \.self) { playerId in
                        let name = MatchForfeitParticipantSupport.displayName(for: playerId, in: session)
                        Button {
                            coordinator.selectForfeitingPlayer(playerId)
                            dismiss()
                        } label: {
                            Text(name)
                                .foregroundStyle(Brand.textPrimary)
                        }
                        .accessibilityIdentifier("forfeit_pick_\(MatchForfeitParticipantSupport.sanitizedPickerIdentifier(for: name))")
                    }
                }
            }
            .navigationTitle("play.match.forfeit.pickPlayer.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { coordinator.cancelFlow() }
                }
            }
            .accessibilityIdentifier("forfeit_player_picker")
        }
        .presentationDetents([.medium, .large])
    }
}

private struct ForfeitWinnerPickerSheet: View {
    @Bindable var coordinator: MatchForfeitCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(coordinator.tiedCandidates) { candidate in
                    Button {
                        coordinator.selectWinner(candidate.playerId)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(candidate.displayName)
                                .foregroundStyle(Brand.textPrimary)
                            Text(candidate.standingSummary)
                                .font(.caption)
                                .foregroundStyle(Brand.textSecondary)
                        }
                    }
                    .accessibilityIdentifier("forfeit_pick_\(MatchForfeitParticipantSupport.sanitizedPickerIdentifier(for: candidate.displayName))")
                }
            }
            .navigationTitle("play.match.forfeit.pickWinner.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { coordinator.cancelFlow() }
                }
            }
            .accessibilityIdentifier("forfeit_winner_picker")
        }
        .presentationDetents([.medium, .large])
    }
}

private struct ForfeitFinalConfirmSheet<Host: MatchPlaySessionHost>: View {
    @ObservedObject var host: Host
    @Bindable var coordinator: MatchForfeitCoordinator
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                Text(confirmMessage)
                    .font(.body)
                    .foregroundStyle(Brand.textPrimary)
                    .accessibilityIdentifier("forfeit_final_confirm")
                Spacer()
                Button {
                    onConfirm()
                } label: {
                    Text("play.match.forfeit.confirm.action")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Brand.amber)
                .disabled(coordinator.flowState == .persisting)
                .accessibilityIdentifier("forfeit_confirm_action")
                .accessibilityLabel(confirmAccessibilityLabel)

                Button("play.match.forfeit.confirm.cancel") {
                    coordinator.cancelFlow()
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("forfeit_confirm_cancel")
            }
            .padding(DS.Spacing.s4)
            .navigationTitle("play.match.forfeit.confirm.title")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    private var confirmMessage: String {
        guard let session = host.session, let forfeitingPlayerId = coordinator.forfeitingPlayerId else {
            return L10n.string("play.match.forfeit.confirm.solo.message")
        }
        if session.runtime.participants.count == 1 {
            return L10n.string("play.match.forfeit.confirm.solo.message")
        }
        let forfeiter = MatchForfeitParticipantSupport.displayName(for: forfeitingPlayerId, in: session)
        let winner = coordinator.winnerPlayerId.map {
            MatchForfeitParticipantSupport.displayName(for: $0, in: session)
        } ?? "—"
        return L10n.format("play.match.forfeit.confirm.message", forfeiter, winner)
    }

    private var confirmAccessibilityLabel: String {
        guard let session = host.session, let forfeitingPlayerId = coordinator.forfeitingPlayerId else {
            return L10n.string("play.match.forfeit.confirm.solo.message")
        }
        let forfeiter = MatchForfeitParticipantSupport.displayName(for: forfeitingPlayerId, in: session)
        let winner = coordinator.winnerPlayerId.map {
            MatchForfeitParticipantSupport.displayName(for: $0, in: session)
        } ?? "—"
        return L10n.format("play.match.forfeit.confirm.accessibility", forfeiter, winner)
    }
}
