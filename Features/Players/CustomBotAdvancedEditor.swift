import SwiftUI

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
