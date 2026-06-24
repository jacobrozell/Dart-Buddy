import SwiftUI

struct SetupHomeModeSection: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @Binding var showsEditOptions: Bool
    let onLearnToPlay: () -> Void
    let onChangeMode: () -> Void
    let onShowModePicker: () -> Void

    private var selectedCatalogEntry: GameModeCatalogEntry? {
        SetupHomeModeContext.selectedCatalogEntry(for: setupViewModel)
    }

    private var learnToPlayMatchType: MatchType? {
        SetupHomeModeContext.learnToPlayMatchType(for: setupViewModel)
    }

    private var hasModeOptionChips: Bool {
        SetupHomeModeContext.hasModeOptionChips(for: setupViewModel)
    }

    private var modeConfigSummary: String {
        selectedCatalogEntry?.blurb ?? ""
    }

    private var selectedModeAccessibilityLabel: String {
        let name = selectedCatalogEntry?.localizedName ?? L10n.string("play.x01.title")
        return L10n.format("play.setup.selectedMode.accessibilityFormat", name, modeConfigSummary)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.string("play.setup.selectedMode"))
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                    .accessibilityHidden(true)
                Spacer(minLength: DS.Spacing.s2)
                if learnToPlayMatchType != nil {
                    learnToPlayButton
                }
            }

            if GameplayLayout.usesAccessibilitySetupHomeLayout(dynamicTypeSize: dynamicTypeSize) {
                accessibilitySelectedModeCard
            } else {
                compactSelectedModeCard
            }
        }
    }

    @ViewBuilder
    private var editOptionsButton: some View {
        if hasModeOptionChips {
            Button {
                showsEditOptions.toggle()
            } label: {
                HStack(spacing: 4) {
                    Text(L10n.string(showsEditOptions ? "play.setup.hideOptions" : "play.setup.editOptions"))
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: showsEditOptions ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .accessibilityHidden(true)
                }
                .foregroundStyle(Brand.green)
                .padding(.horizontal, DS.Spacing.s2)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("setup_editOptionsButton")
        }
    }

    private var learnToPlayButton: some View {
        Button(action: onLearnToPlay) {
            HStack(spacing: 6) {
                Image(systemName: "book.pages")
                Text(L10n.gameRulesLearnButton)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(Brand.green)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.gameRulesLearnButton)
        .accessibilityIdentifier("setup_learnToPlayButton")
    }

    private var selectedModeSummaryBlock: some View {
        HStack(alignment: .top, spacing: DS.Spacing.s3) {
            if let entry = selectedCatalogEntry, let matchType = entry.matchType {
                GameModeBadge(type: matchType, size: 36)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedCatalogEntry?.localizedName ?? L10n.string("play.x01.title"))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Brand.textPrimary)
                Text(modeConfigSummary)
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(selectedModeAccessibilityLabel)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("setup_selectedModeName")
    }

    private var changeModeButton: some View {
        Button(action: changeModeTapped) {
            Text(L10n.string("play.setup.changeMode"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.green)
                .padding(.horizontal, DS.Spacing.s2)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("setup_changeModeButton")
    }

    private var compactSelectedModeCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            HStack(alignment: .top, spacing: DS.Spacing.s3) {
                selectedModeSummaryBlock
                Spacer(minLength: DS.Spacing.s2)
                changeModeButton
            }
            if hasModeOptionChips {
                HStack {
                    Spacer(minLength: 0)
                    editOptionsButton
                }
            }
        }
        .padding(DS.Spacing.s3)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private var accessibilitySelectedModeCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            selectedModeSummaryBlock
            HStack {
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: DS.Spacing.s1) {
                    changeModeButton
                    editOptionsButton
                }
            }
        }
        .padding(DS.Spacing.s3)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private func changeModeTapped() {
        if ProductSurface.showsModesTab {
            onChangeMode()
        } else {
            onShowModePicker()
        }
    }
}
