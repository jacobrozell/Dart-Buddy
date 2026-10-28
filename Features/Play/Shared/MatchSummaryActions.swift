import SwiftUI

struct MatchSummaryActions: View {
    @ObservedObject var viewModel: MatchSummaryViewModel
    let compact: Bool
    let isRematching: Bool
    let rematchErrorKey: String?
    let onRematch: () -> Void
    let onDone: () -> Void
    let onViewStatistics: () -> Void
    let onUndoLastThrow: () -> Void

    var body: some View {
        if compact {
            landscapeActions
        } else {
            VStack(spacing: DS.Spacing.s3) {
                portraitActionButtons
            }
            .padding(.top, DS.Spacing.s2)
        }
    }

    private var rematchButton: some View {
        PrimaryActionButton(
            title: LocalizedStringKey(viewModel.rematchTitleKey),
            accent: .green,
            isEnabled: viewModel.canRematch,
            isLoading: isRematching,
            accessibilityIdentifier: "matchSummaryRematch",
            action: onRematch
        )
    }

    private var doneButton: some View {
        PrimaryActionButton(
            title: L10n.summaryDone,
            accent: .green,
            accessibilityIdentifier: "matchSummaryDone",
            action: onDone
        )
    }

    private var landscapeActions: some View {
        VStack(spacing: DS.Spacing.s2) {
            HStack(spacing: DS.Spacing.s3) {
                rematchButton
                doneButton
                MatchSummarySecondaryButton(
                    title: L10n.summaryViewGameStatistics,
                    action: onViewStatistics,
                    compact: true
                )
            }
            if let rematchErrorKey {
                ErrorBanner(messageKey: rematchErrorKey)
            }
            if let undoErrorKey = viewModel.undoErrorKey {
                ErrorBanner(messageKey: undoErrorKey)
            }
            if viewModel.canUndoLastThrow {
                undoLastThrowSection(compact: true)
            }
        }
        .padding(.top, DS.Spacing.s1)
    }

    @ViewBuilder
    private var portraitActionButtons: some View {
        if let rematchErrorKey {
            ErrorBanner(messageKey: rematchErrorKey)
        }
        rematchButton
        doneButton
        Button(action: onViewStatistics) {
            Text(L10n.summaryViewGameStatistics)
                .font(.headline).foregroundStyle(Brand.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
        }
        .buttonStyle(.plain)
        if let undoErrorKey = viewModel.undoErrorKey {
            ErrorBanner(messageKey: undoErrorKey)
        }
        if viewModel.canUndoLastThrow {
            undoLastThrowSection(compact: false)
        }
    }

    private func undoLastThrowSection(compact: Bool) -> some View {
        VStack(spacing: DS.Spacing.s1) {
            MatchSummarySecondaryButton(
                title: L10n.summaryUndoLastThrow,
                action: onUndoLastThrow,
                isLoading: viewModel.isUndoing,
                identifier: "matchSummaryUndoLastThrow",
                hint: L10n.summaryUndoLastThrowHint,
                compact: compact
            )
            Text(L10n.summaryUndoLastThrowWarning)
                .font(compact ? .caption2 : .caption)
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityIdentifier("matchSummaryUndoLastThrowWarning")
        }
    }
}

private struct MatchSummarySecondaryButton: View {
    let title: LocalizedStringKey
    let action: () -> Void
    var isLoading = false
    var identifier: String?
    var hint: LocalizedStringKey?
    var compact = false

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(Brand.textPrimary)
                        .accessibilityLabel(L10n.loading)
                } else {
                    Text(title)
                        .font(compact ? .subheadline.weight(.semibold) : .headline)
                        .foregroundStyle(Brand.textPrimary)
                        .lineLimit(compact ? 2 : 1)
                        .minimumScaleFactor(compact ? 0.85 : 1)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, minHeight: compact ? 48 : 52)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .modifier(SummarySecondaryButtonAccessibility(identifier: identifier, hint: hint))
    }
}

private struct SummarySecondaryButtonAccessibility: ViewModifier {
    let identifier: String?
    let hint: LocalizedStringKey?

    func body(content: Content) -> some View {
        if let identifier, let hint {
            content
                .accessibilityIdentifier(identifier)
                .accessibilityHint(hint)
        } else if let identifier {
            content.accessibilityIdentifier(identifier)
        } else if let hint {
            content.accessibilityHint(hint)
        } else {
            content
        }
    }
}
