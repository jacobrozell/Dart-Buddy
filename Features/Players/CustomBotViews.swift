import SwiftUI

struct CustomBotBadge: View {
    let metrics: CustomBotMetrics
    var prominence: BotDifficultyBadge.Prominence = .standard

    private var accent: Color { Brand.proBot.opacity(0.85) }

    var body: some View {
        HStack(spacing: prominence == .compact ? 4 : 6) {
            Image(systemName: "slider.horizontal.3")
                .font(prominence == .compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
            Text(L10n.format("customBot.badge.format", metrics.x01Average, metrics.cricketMPR))
                .font(prominence == .compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
        }
        .foregroundStyle(accent)
        .padding(.horizontal, prominence == .compact ? DS.Spacing.s2 : DS.Spacing.s3)
        .padding(.vertical, prominence == .compact ? 4 : 6)
        .background(accent.opacity(0.15), in: Capsule())
        .overlay(Capsule().strokeBorder(accent.opacity(0.35), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("customBot.badge.accessibilityFormat", metrics.x01Average, metrics.cricketMPR))
    }
}

struct CustomBotMetricsEditor: View {
    @Binding var x01Average: Double
    @Binding var cricketMPR: Double

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            metricSlider(
                title: L10n.customBotX01AverageLabel,
                hint: L10n.customBotX01AverageHint,
                value: $x01Average,
                range: CustomBotMetrics.x01AverageRange,
                step: 1
            ) { String(format: "%.0f", $0) }

            metricSlider(
                title: L10n.customBotCricketMPRLabel,
                hint: L10n.customBotCricketMPRHint,
                value: $cricketMPR,
                range: CustomBotMetrics.cricketMPRRange,
                step: 0.05
            ) { String(format: "%.2f", $0) }
        }
    }

    private func metricSlider(
        title: LocalizedStringKey,
        hint: LocalizedStringKey,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: (Double) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
                Spacer()
                Text(format(value.wrappedValue))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Brand.green)
            }
            Slider(
                value: value,
                in: range,
                step: step
            )
            .tint(Brand.green)
            Text(hint)
                .font(.caption)
                .foregroundStyle(Brand.textSecondary)
        }
    }
}

struct CustomBotCreationSheet: View {
    let onCreate: (String, CustomBotMetrics) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var x01Average = CustomBotMetrics.defaultX01Average
    @State private var cricketMPR = CustomBotMetrics.defaultCricketMPR

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.customBotCreateSectionIdentity) {
                    TextField(L10n.customBotNamePlaceholder, text: $name)
                }
                Section {
                    CustomBotMetricsEditor(x01Average: $x01Average, cricketMPR: $cricketMPR)
                } header: {
                    Text(L10n.customBotCreateSectionStats)
                } footer: {
                    Text(L10n.customBotCreateFooter)
                }
            }
            .navigationTitle(L10n.customBotCreateTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.customBotCreateAction) {
                        let metrics = CustomBotMetrics(x01Average: x01Average, cricketMPR: cricketMPR)
                        onCreate(name, metrics)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CustomBotDetailView: View {
    let player: EditablePlayer
    let existingNames: [String]
    let onSave: (EditablePlayer) -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @StateObject private var editViewModel: PlayerEditViewModel
    @State private var x01Average: Double
    @State private var cricketMPR: Double
    @StateObject private var statsViewModel: PlayerDetailViewModel

    init(
        player: EditablePlayer,
        existingNames: [String],
        dependencies: AppDependencies,
        onSave: @escaping (EditablePlayer) -> Void
    ) {
        self.player = player
        self.existingNames = existingNames
        self.onSave = onSave
        _editViewModel = StateObject(wrappedValue: PlayerEditViewModel(existingNames: existingNames, editing: player))
        _x01Average = State(initialValue: player.customX01Average)
        _cricketMPR = State(initialValue: player.customCricketMPR)
        _statsViewModel = StateObject(wrappedValue: PlayerDetailViewModel(
            playerId: player.id,
            playerName: player.name,
            playerRepository: dependencies.playerRepository,
            matchRepository: dependencies.matchRepository,
            statsRepository: dependencies.statsRepository
        ))
    }

    private var metrics: CustomBotMetrics {
        CustomBotMetrics(x01Average: x01Average, cricketMPR: cricketMPR)
    }

    private var displayProfile: BotDifficultyDisplayProfile {
        CustomBotSkillResolver.combinedDisplayProfile(metrics: metrics)
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

                VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                    Text(L10n.customBotStatsSection)
                        .font(.headline)
                        .foregroundStyle(Brand.textPrimary)
                    CustomBotMetricsEditor(x01Average: $x01Average, cricketMPR: $cricketMPR)
                    Text(L10n.customBotStatsFooter)
                        .font(.footnote)
                        .foregroundStyle(Brand.textSecondary)
                }
                .padding(DS.Spacing.s4)
                .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))

                BotDifficultyStatsSection(profile: displayProfile)

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
                    var saved = editViewModel.buildPlayer(from: player)
                    saved.customX01Average = x01Average
                    saved.customCricketMPR = cricketMPR
                    onSave(saved)
                }
                .disabled(!editViewModel.canSave)
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
