import SwiftUI

/// Promo sheet shown once after upgrading to a new release slice (Party Pack 1.1).
struct ReleaseHighlightsSheet: View {
    let highlight: ReleaseHighlight
    let onTryNewModes: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.s5) {
                    header
                    featureList
                }
                .padding(.horizontal, DS.Spacing.s4)
                .padding(.top, DS.Spacing.s2)
                .padding(.bottom, DS.Spacing.s6)
            }
            .background(Brand.background)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.releaseHighlightsGotIt) {
                        onDismiss()
                    }
                    .accessibilityIdentifier("release_highlights_gotIt")
                }
            }
            .safeAreaInset(edge: .bottom) {
                OnboardingPrimaryButton(
                    title: L10n.releaseHighlightsTryModes,
                    accessibilityIdentifier: "release_highlights_tryModes"
                ) {
                    onTryNewModes()
                }
                .padding(.horizontal, DS.Spacing.s4)
                .padding(.vertical, DS.Spacing.s3)
                .background(Brand.background)
            }
        }
        .accessibilityIdentifier("release_highlights_sheet")
        .accessibilityLabel(L10n.string("release.highlights.accessibility"))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text(L10n.releaseHighlightsBadge)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.green)
                .padding(.horizontal, DS.Spacing.s2)
                .padding(.vertical, DS.Spacing.s1)
                .background(Brand.green.opacity(0.14), in: Capsule())

            Text(L10n.releaseHighlightsPartyPackTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.textPrimary)

            Text(L10n.releaseHighlightsPartyPackSubtitle)
                .font(.body)
                .foregroundStyle(Brand.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var featureList: some View {
        VStack(spacing: DS.Spacing.s3) {
            ForEach(Array(highlight.features.enumerated()), id: \.offset) { _, feature in
                featureRow(feature)
            }
        }
    }

    private func featureRow(_ feature: ReleaseHighlight.Feature) -> some View {
        let entry = GameModeCatalog.entry(for: feature.catalogID)
        let title = entry?.localizedName ?? L10n.string("modes.catalog.\(feature.catalogID).name")
        let blurb = entry?.localizedBlurb ?? L10n.string("modes.catalog.\(feature.catalogID).blurb")

        return HStack(alignment: .top, spacing: DS.Spacing.s3) {
            GameModeBadge(type: feature.matchType, size: 36)
            VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                Text(blurb)
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(DS.Spacing.s3)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(blurb)")
    }
}
