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

enum CustomBotEditorMode: String, CaseIterable, Identifiable {
    case simple
    case advanced

    var id: String { rawValue }
}

struct CustomBotDetailView: View {
    let player: EditablePlayer
    let existingNames: [String]
    let onSave: (EditablePlayer) -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @StateObject private var editViewModel: PlayerEditViewModel
    @State private var editorMode: CustomBotEditorMode = .simple
    @State private var configuration: CustomBotConfiguration
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
        configuration.resolvedCanonicalProfile().displayProfile
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

struct CustomBotAdvancedEditor: View {
    @Binding var configuration: CustomBotConfiguration

    @State private var x01Facet: X01SkillFacet
    @State private var cricketFacet: CricketSkillFacet
    @State private var aimFacet: AimSkillFacet
    @State private var presetAnchor: BotDifficulty
    @State private var suppressPresetAnchorChange = false

    init(configuration: Binding<CustomBotConfiguration>) {
        _configuration = configuration
        let profile = configuration.wrappedValue.resolvedCanonicalProfile()
        let facets = configuration.wrappedValue.facetOverrides ?? CustomBotFacetOverrides.extract(from: profile)
        _x01Facet = State(initialValue: facets.x01 ?? X01SkillFacet.extract(from: profile))
        _cricketFacet = State(initialValue: facets.cricket ?? CricketSkillFacet.extract(from: profile))
        _aimFacet = State(initialValue: facets.aim ?? AimSkillFacet.extract(from: profile))
        _presetAnchor = State(initialValue: configuration.wrappedValue.scoringBehaviorTier ?? profile.x01.scoringBehaviorTier)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                Picker(L10n.customBotAdvancedPresetAnchor, selection: $presetAnchor) {
                    ForEach(BotDifficulty.allCases, id: \.self) { difficulty in
                        Text(difficulty.displayName).tag(difficulty)
                    }
                }
                .onChange(of: presetAnchor) { _, newValue in
                    guard !suppressPresetAnchorChange else { return }
                    configuration.scoringBehaviorTier = newValue
                    applyFacetsToConfiguration()
                }

                HStack(spacing: DS.Spacing.s3) {
                    Button(L10n.customBotAdvancedResetSimple) {
                        configuration = configuration.resetToSimpleTargets()
                        reloadFacetsFromConfiguration()
                    }
                    .buttonStyle(.bordered)

                    Button(L10n.customBotAdvancedResetPreset) {
                        configuration = configuration.resetToPreset(presetAnchor)
                        reloadFacetsFromConfiguration()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(DS.Spacing.s4)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))

            facetSection(title: L10n.customBotAdvancedX01Section) {
                visitRangeEditors
                probabilitySlider(title: "players.bots.stats.hitSingle", value: x01Binding(\.singleHitChance))
                probabilitySlider(title: "players.bots.stats.hitDouble", value: x01Binding(\.doubleHitChance))
                probabilitySlider(title: "players.bots.stats.hitTriple", value: x01Binding(\.tripleHitChance))
                probabilitySlider(title: "players.bots.stats.checkoutAttemptRate", value: x01Binding(\.checkoutAttemptChance))
                probabilitySlider(title: "players.bots.stats.offBoardMiss", value: x01Binding(\.offBoardMissChance))
                probabilitySlider(title: "players.bots.stats.bustRisk", value: x01Binding(\.riskyBustChance))
                probabilitySlider(title: "players.bots.stats.triplePreference", value: x01Binding(\.triplePreference))
            }

            facetSection(title: L10n.customBotAdvancedCricketSection) {
                probabilitySlider(title: "players.bots.stats.hitSingle", value: cricketBinding(\.singleHitChance))
                probabilitySlider(title: "players.bots.stats.hitDouble", value: cricketBinding(\.doubleHitChance))
                probabilitySlider(title: "players.bots.stats.hitTriple", value: cricketBinding(\.tripleHitChance))
                probabilitySlider(title: "players.bots.stats.offBoardMiss", value: cricketBinding(\.offBoardMissChance))
                probabilitySlider(title: "players.bots.stats.wrongBed", value: cricketBinding(\.wrongBedChance))
            }

            facetSection(title: L10n.customBotAdvancedAimSection) {
                Picker(L10n.customBotAdvancedPresetAnchor, selection: Binding(
                    get: { aimFacet.scoringBehaviorTier ?? presetAnchor },
                    set: { aimFacet.scoringBehaviorTier = $0; applyFacetsToConfiguration() }
                )) {
                    ForEach(BotDifficulty.allCases, id: \.self) { difficulty in
                        Text(difficulty.displayName).tag(difficulty)
                    }
                }
                probabilitySlider(title: "players.bots.stats.triplePreference", value: aimBinding(\.tripleOnOpenChance))
                probabilitySlider(title: "players.bots.stats.hitDouble", value: aimBinding(\.doubleOnOpenChance))
            }

            Text(L10n.customBotAdvancedFooter)
                .font(.footnote)
                .foregroundStyle(Brand.textSecondary)
        }
    }

    @ViewBuilder
    private var visitRangeEditors: some View {
        HStack(spacing: DS.Spacing.s3) {
            Stepper(
                value: Binding(
                    get: { x01Facet.scoringVisitMin ?? 0 },
                    set: {
                        x01Facet.scoringVisitMin = $0
                        applyFacetsToConfiguration()
                    }
                ),
                in: 0 ... 180
            ) {
                Text(L10n.format("customBot.advanced.visitMinFormat", Double(x01Facet.scoringVisitMin ?? 0)))
            }
            Stepper(
                value: Binding(
                    get: { x01Facet.scoringVisitMax ?? 0 },
                    set: {
                        x01Facet.scoringVisitMax = $0
                        applyFacetsToConfiguration()
                    }
                ),
                in: 0 ... 180
            ) {
                Text(L10n.format("customBot.advanced.visitMaxFormat", Double(x01Facet.scoringVisitMax ?? 0)))
            }
        }
    }

    private func facetSection(title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                content()
            }
            .padding(DS.Spacing.s4)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        }
    }

    private func probabilitySlider(
        title: LocalizedStringKey,
        value: Binding<Double>
    ) -> some View {
        BotStatSliderRow(
            title: title,
            value: value,
            range: 0 ... 1,
            step: 0.01
        )
    }

    private func x01Binding(_ keyPath: WritableKeyPath<X01SkillFacet, Double?>) -> Binding<Double> {
        Binding(
            get: { x01Facet[keyPath: keyPath] ?? 0 },
            set: {
                x01Facet[keyPath: keyPath] = $0
                applyFacetsToConfiguration()
            }
        )
    }

    private func cricketBinding(_ keyPath: WritableKeyPath<CricketSkillFacet, Double?>) -> Binding<Double> {
        Binding(
            get: { cricketFacet[keyPath: keyPath] ?? 0 },
            set: {
                cricketFacet[keyPath: keyPath] = $0
                applyFacetsToConfiguration()
            }
        )
    }

    private func aimBinding(_ keyPath: WritableKeyPath<AimSkillFacet, Double?>) -> Binding<Double> {
        Binding(
            get: { aimFacet[keyPath: keyPath] ?? 0 },
            set: {
                aimFacet[keyPath: keyPath] = $0
                applyFacetsToConfiguration()
            }
        )
    }

    private func applyFacetsToConfiguration() {
        configuration.schemaVersion = CustomBotConfiguration.currentSchemaVersion
        configuration.facetOverrides = CustomBotFacetOverrides(
            x01: x01Facet,
            cricket: cricketFacet,
            aim: aimFacet
        )
        configuration.syncExplicitProfileFromFacets()
    }

    private func reloadFacetsFromConfiguration() {
        let profile = configuration.resolvedCanonicalProfile()
        let facets = configuration.facetOverrides ?? CustomBotFacetOverrides.extract(from: profile)
        x01Facet = facets.x01 ?? X01SkillFacet.extract(from: profile)
        cricketFacet = facets.cricket ?? CricketSkillFacet.extract(from: profile)
        aimFacet = facets.aim ?? AimSkillFacet.extract(from: profile)
        suppressPresetAnchorChange = true
        presetAnchor = configuration.scoringBehaviorTier ?? profile.x01.scoringBehaviorTier
        Task { @MainActor in
            suppressPresetAnchorChange = false
        }
    }
}
