import SwiftUI

struct BotDetailView: View {
    let player: EditablePlayer
    let difficulty: BotDifficulty
    let existingNames: [String]
    let dependencies: AppDependencies
    let onSave: (EditablePlayer) -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @StateObject private var editViewModel: PlayerEditViewModel
    @StateObject private var statsViewModel: PlayerDetailViewModel

    init(
        player: EditablePlayer,
        difficulty: BotDifficulty,
        existingNames: [String],
        dependencies: AppDependencies,
        onSave: @escaping (EditablePlayer) -> Void
    ) {
        self.player = player
        self.difficulty = difficulty
        self.existingNames = existingNames
        self.dependencies = dependencies
        self.onSave = onSave
        _editViewModel = StateObject(wrappedValue: PlayerEditViewModel(existingNames: existingNames, editing: player))
        _statsViewModel = StateObject(wrappedValue: PlayerDetailViewModel(
            playerId: player.id,
            playerName: player.name,
            playerRepository: dependencies.playerRepository,
            matchRepository: dependencies.matchRepository,
            statsRepository: dependencies.statsRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                BotIdentityCard(
                    name: editViewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? player.name : editViewModel.name,
                    avatarStyle: editViewModel.avatarStyle,
                    colorToken: editViewModel.colorToken,
                    difficulty: difficulty,
                    notes: editViewModel.notes
                )

                BotDifficultyStatsSection(profile: difficulty.displayProfile)

                customizationSection

                PlayerDetailStatsContent(viewModel: statsViewModel)
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s6)
            .readableRootContentWidth(horizontalSizeClass)
        }
        .background(Brand.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.save) {
                    onSave(editViewModel.buildPlayer(from: player))
                }
                .disabled(!editViewModel.canSave)
                .accessibilityLabel(L10n.string("players.bots.save.accessibility"))
                .accessibilityIdentifier("botDetail_save")
            }
        }
        .task { await statsViewModel.load() }
    }

    private var customizationSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text(L10n.botCustomizationSection)
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)

            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                TextField("players.edit.name", text: $editViewModel.name)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(L10n.string("players.edit.name.accessibility"))
                    .accessibilityIdentifier("botDetail_name")
                    .onChange(of: editViewModel.name) { _, _ in editViewModel.validate() }

                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    Text(L10n.playersEditAvatar)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.textSecondary)
                    AvatarStylePicker(selection: $editViewModel.avatarStyle)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    Text(L10n.playersEditColor)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.textSecondary)
                    PlayerColorTokenPicker(selection: $editViewModel.colorToken)
                }

                TextField("players.edit.notes", text: $editViewModel.notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(L10n.string("players.edit.notes.accessibility"))

                if let message = editViewModel.validationMessage {
                    Text(message).foregroundStyle(.red).font(.footnote)
                }
            }
            .padding(DS.Spacing.s4)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        }
    }
}

struct TrainingBotDetailView: View {
    let player: EditablePlayer
    let existingNames: [String]
    let dependencies: AppDependencies
    let onSave: (EditablePlayer) -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @StateObject private var editViewModel: PlayerEditViewModel
    @StateObject private var statsViewModel: PlayerDetailViewModel
    @State private var linkedHumanName = ""

    init(
        player: EditablePlayer,
        existingNames: [String],
        dependencies: AppDependencies,
        onSave: @escaping (EditablePlayer) -> Void
    ) {
        self.player = player
        self.existingNames = existingNames
        self.dependencies = dependencies
        self.onSave = onSave
        _editViewModel = StateObject(wrappedValue: PlayerEditViewModel(existingNames: existingNames, editing: player))
        _statsViewModel = StateObject(wrappedValue: PlayerDetailViewModel(
            playerId: player.id,
            playerName: player.name,
            playerRepository: dependencies.playerRepository,
            matchRepository: dependencies.matchRepository,
            statsRepository: dependencies.statsRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                BotIdentityCard(
                    name: editViewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? player.name : editViewModel.name,
                    avatarStyle: editViewModel.avatarStyle,
                    colorToken: editViewModel.colorToken,
                    difficulty: nil,
                    notes: editViewModel.notes
                )

                if let profile = resolvedProfile {
                    BotDifficultyStatsSection(profile: profile.displayProfile)
                    Text(L10n.format("trainingBot.calibrated.footer", linkedHumanName))
                        .font(.footnote)
                        .foregroundStyle(Brand.textSecondary)
                }

                customizationSection
                PlayerDetailStatsContent(viewModel: statsViewModel)
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s6)
            .readableRootContentWidth(horizontalSizeClass)
        }
        .background(Brand.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.save) {
                    onSave(editViewModel.buildPlayer(from: player))
                }
                .disabled(!editViewModel.canSave)
            }
        }
        .task {
            await statsViewModel.load()
            await loadLinkedHumanName()
        }
    }

    private func loadLinkedHumanName() async {
        guard let linkedId = player.linkedPlayerId else { return }
        guard let players = try? await dependencies.playerRepository.fetchPlayers(includeArchived: true),
              let linked = players.first(where: { $0.id == linkedId }) else { return }
        linkedHumanName = linked.name
    }

    private var resolvedProfile: BotSkillProfile? {
        guard player.linkedPlayerId != nil else { return nil }
        let breakdown = statsViewModel.x01 ?? statsViewModel.cricket
        guard let breakdown else { return BotDifficulty.easy.skillProfile }
        return TrainingBotSkillResolver.resolve(breakdown: breakdown, mode: .x01)
    }

    private var customizationSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text(L10n.botCustomizationSection)
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
            TextField("players.edit.name", text: $editViewModel.name)
                .textFieldStyle(.roundedBorder)
        }
        .padding(DS.Spacing.s4)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }
}
