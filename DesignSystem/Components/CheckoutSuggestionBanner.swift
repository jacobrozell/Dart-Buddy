import SwiftUI

/// Checkout route banner for X01 — one dart per pill, optional cycling when multiple
/// fewest-dart routes exist.
struct CheckoutSuggestionBanner: View {
    let routes: [[String]]
    @Binding var selectedIndex: Int

    private var clampedIndex: Int {
        guard routes.isEmpty == false else { return 0 }
        return min(max(selectedIndex, 0), routes.count - 1)
    }

    private var selectedRoute: [String]? {
        guard routes.isEmpty == false else { return nil }
        return routes[clampedIndex]
    }

    var body: some View {
        if let route = selectedRoute {
            let labels = CheckoutSuggester.localizedDisplayLabels(for: route)
            let optionCount = routes.count
            HStack(alignment: .center, spacing: DS.Spacing.s2) {
                checkoutContent(labels: labels, optionCount: optionCount)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if optionCount > 1 {
                    cycleButton
                }
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.vertical, DS.Spacing.s3)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        }
    }

    private func checkoutContent(labels: [String], optionCount: Int) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            titleRow
            routeRow(labels: labels)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(combinedAccessibilityLabel(labels: labels, optionCount: optionCount))
        .accessibilityIdentifier("checkoutSuggestion")
    }

    private var titleRow: some View {
        HStack(spacing: DS.Spacing.s2) {
            Image(systemName: "target")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Brand.green)
                .accessibilityHidden(true)

            Text(L10n.x01CheckoutTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
        }
    }

    private var cycleButton: some View {
        Button {
            selectedIndex = (clampedIndex + 1) % routes.count
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.body.weight(.semibold))
                .foregroundStyle(Brand.green)
                .frame(width: 36, height: 36)
                .background(Brand.cardElevated, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.x01CheckoutCycle)
        .accessibilityIdentifier("checkoutCycleButton")
    }

    @ViewBuilder
    private func routeRow(labels: [String]) -> some View {
        HStack(spacing: DS.Spacing.s2) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                if index > 0 {
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Brand.textSecondary.opacity(0.65))
                        .accessibilityHidden(true)
                }

                Text(label)
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(index == labels.count - 1 ? Brand.green : Brand.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, DS.Spacing.s3)
                    .padding(.vertical, DS.Spacing.s2)
                    .frame(minWidth: 52)
                    .background(
                        index == labels.count - 1
                            ? Brand.green.opacity(0.14)
                            : Brand.cardElevated,
                        in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                    )
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func combinedAccessibilityLabel(labels: [String], optionCount: Int) -> String {
        let spokenRoute = labels.joined(separator: ", ")
        let base = L10n.format("play.x01.checkout.accessibilityFormat", spokenRoute)
        guard optionCount > 1 else { return base }
        return "\(base). \(L10n.format("play.x01.checkout.optionTotalAccessibilityFormat", optionCount))."
    }
}
