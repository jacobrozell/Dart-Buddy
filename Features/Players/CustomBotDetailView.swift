import SwiftUI

enum CustomBotEditorMode: String, CaseIterable, Identifiable {
    case simple
    case advanced

    var id: String { rawValue }
}

struct CustomBotDetailView: View {
    let player: EditablePlayer
    let existingNames: [String]
    let onSave: (EditablePlayer) -> Void
    let onSelectRecentMatch: (UUID) -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @StateObject private var editViewModel: PlayerEditViewModel
    @State private var editorMode: CustomBotEditorMode = .simple
    @State private var configuration: CustomBotConfiguration
    @StateObject private var statsViewModel: PlayerDetailViewModel

    init(
        player: EditablePlayer,
        existingNames: [String],
        dependencies: AppDependencies,
        onSave: @escaping (EditablePlayer) -> Void,
        onSelectRecentMatch: @escaping (UUID) -> Void = { _ in }
    ) {
        self.player = player
        self.existingNames = existingNames
        self.onSave = onSave
        self.onSelectRecentMatch = onSelectRecentMatch
        _editViewModel = StateObject(wrappedValue: PlayerEditViewModel(existingNames: existingNames, editing: player))
        let initialConfiguration = player.customBotConfiguration ?? CustomBotConfiguration.from(
            metrics: CustomBotMetrics(
                x01Average: player.customX01Average,
                cricketMPR: player.customCricketMPR
            )
        )
        _configuration = State(initialValue: initialConfiguration)
        _editorMode = State(initialValue: initialConfiguration.isAdvanced ? .advanced : .simple)
        _statsViewModel = StateObject(wrappedValue: PlayerDetailViewModel(
            playerId: player.id,
            playerName: player.name,
            playerRepository: dependencies.playerRepository,
            matchRepository: dependencies.matchRepository,
            statsRepository: dependencies.statsRepository
        ))
    }

    private var metrics: CustomBotMetrics {
        configuration.metrics
    }

    private var displayProfile: BotDifficultyDisplayProfile {
        configuration.resolvedCanonicalProfile().displayProfile(
            summary: .custom(configuration.metrics)
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                BotIdentityCard(
                    name: editViewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? player.name : editViewModel.name,
                    avatarStyle: editViewModel.avatarStyle,
                    colorToken: editViewModel.colorToken,
                    difficulty: nil,
                    customMetrics: metrics,
                    notes: editViewModel.notes
                )

                Picker("Editor mode", selection: $editorMode) {
                    Text(L10n.customBotEditorSimple).tag(CustomBotEditorMode.simple)
                    Text(L10n.customBotEditorAdvanced).tag(CustomBotEditorMode.advanced)
                }
                .pickerStyle(.segmented)

                Group {
                    switch editorMode {
                    case .simple:
                        simpleEditorSection
                    case .advanced:
                        CustomBotAdvancedEditor(configuration: $configuration)
                    }
                }

                BotDifficultyStatsSection(profile: displayProfile)

                CustomBotCompatibleTemplatesSection()

                customizationSection
                PlayerDetailStatsContent(
                    viewModel: statsViewModel,
                    onSelectRecentMatch: onSelectRecentMatch
                )
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s6)
            .readableRootContentWidth(horizontalSizeClass)
        }
        .background(Brand.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.save) {
                    var saved = editViewModel.buildPlayer(from: player)
                    saved.customX01Average = configuration.x01Average
                    saved.customCricketMPR = configuration.cricketMPR
                    saved.customBotConfiguration = configuration
                    onSave(saved)
                }
                .disabled(!editViewModel.canSave)
            }
        }
        .task { await statsViewModel.load() }
    }

    private var simpleEditorSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text(L10n.customBotStatsSection)
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
            CustomBotMetricsEditor(
                x01Average: Binding(
                    get: { configuration.x01Average },
                    set: { newValue in
                        configuration.x01Average = newValue
                        if editorMode == .simple {
                            configuration = configuration.resetToSimpleTargets()
                        }
                    }
                ),
                cricketMPR: Binding(
                    get: { configuration.cricketMPR },
                    set: { newValue in
                        configuration.cricketMPR = newValue
                        if editorMode == .simple {
                            configuration = configuration.resetToSimpleTargets()
                        }
                    }
                )
            )
            Text(L10n.customBotStatsFooter)
                .font(.footnote)
                .foregroundStyle(Brand.textSecondary)
        }
        .padding(DS.Spacing.s4)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private var customizationSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text(L10n.botCustomizationSection)
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)

            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                TextField("players.edit.name", text: $editViewModel.name)
                    .textFieldStyle(.roundedBorder)
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

                if let message = editViewModel.validationMessage {
                    Text(message).foregroundStyle(.red).font(.footnote)
                }
            }
            .padding(DS.Spacing.s4)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        }
    }
}

struct CustomBotCompatibleTemplatesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text(L10n.customBotCompatibleTemplatesTitle)
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
            Text(L10n.customBotCompatibleTemplatesFooter)
                .font(.footnote)
                .foregroundStyle(Brand.textSecondary)

            VStack(spacing: DS.Spacing.s2) {
                ForEach(BotSkillProfileResolver.compatibleTemplates(), id: \.self) { template in
                    HStack(alignment: .top, spacing: DS.Spacing.s3) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.string(template.displayTitleKey))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Brand.textPrimary)
                            Text(L10n.string(template.customBotPrimaryMetricKey))
                                .font(.caption)
                                .foregroundStyle(Brand.textSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, DS.Spacing.s3)
                    .padding(.vertical, DS.Spacing.s2)
                    .background(Brand.background, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                }
            }
        }
        .padding(DS.Spacing.s4)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }
}
