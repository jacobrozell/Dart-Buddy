import SwiftUI

func playLocalizedText(_ key: String) -> Text {
    Text(LocalizedStringKey(key))
}

/// Shared top chrome for in-progress match screens (exit, title, optional trailing action).
struct MatchGameplayHeader<Title: View, Trailing: View>: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    let onExit: () -> Void
    let exitAccessibilityLabel: LocalizedStringKey
    @ViewBuilder let title: () -> Title
    @ViewBuilder let trailing: () -> Trailing

    private var usesCompactHeight: Bool { verticalSizeClass == .compact }

    init(
        onExit: @escaping () -> Void,
        exitAccessibilityLabel: LocalizedStringKey = L10n.x01LeaveMatchAccessibility,
        @ViewBuilder title: @escaping () -> Title,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.onExit = onExit
        self.exitAccessibilityLabel = exitAccessibilityLabel
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack {
            Button(action: onExit) {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Brand.green)
                    .frame(width: 44, height: 44)
                    .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
            }
            .accessibilityLabel(exitAccessibilityLabel)
            .accessibilityIdentifier("match_exit")
            Spacer()
            title()
            Spacer()
            trailing()
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.top, usesCompactHeight ? DS.Spacing.s1 : DS.Spacing.s2)
        .padding(.bottom, usesCompactHeight ? DS.Spacing.s1 : DS.Spacing.s2)
        .layoutPriority(1)
    }
}
