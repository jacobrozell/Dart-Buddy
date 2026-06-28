import SwiftUI

/// Unified empty state presentation for Brand-themed screens.
struct BrandEmptyState<Actions: View>: View {
    let title: LocalizedStringKey
    let systemImage: String
    let description: LocalizedStringKey?
    @ViewBuilder let actions: () -> Actions

    init(
        _ title: LocalizedStringKey,
        systemImage: String,
        description: LocalizedStringKey? = nil,
        @ViewBuilder actions: @escaping () -> Actions = { EmptyView() }
    ) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
        self.actions = actions
    }

    var body: some View {
        VStack(spacing: DS.Spacing.s3) {
            Image(systemName: systemImage)
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(Brand.textSecondary)
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
                .multilineTextAlignment(.center)
            if let description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .multilineTextAlignment(.center)
            }
            actions()
        }
        .padding(.vertical, DS.Spacing.s6)
        .frame(maxWidth: .infinity)
    }
}

/// Inline hint for empty sections within a larger view.
struct BrandEmptyHint: View {
    let message: LocalizedStringKey
    var icon: String? = nil

    var body: some View {
        HStack(spacing: DS.Spacing.s2) {
            if let icon {
                Image(systemName: icon)
                    .font(.footnote)
                    .foregroundStyle(Brand.textSecondary.opacity(0.7))
                    .accessibilityHidden(true)
            }
            Text(message)
                .font(.footnote)
                .foregroundStyle(Brand.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Helper text with subtle visual treatment for contextual guidance.
struct BrandHelperText: View {
    let message: LocalizedStringKey
    var icon: String = "info.circle"

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.s2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Brand.textSecondary.opacity(0.7))
                .accessibilityHidden(true)
            Text(message)
                .font(.footnote)
                .foregroundStyle(Brand.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, DS.Spacing.s3)
        .padding(.vertical, DS.Spacing.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.cardElevated.opacity(0.5), in: RoundedRectangle(cornerRadius: DS.Radius.sm))
    }
}
