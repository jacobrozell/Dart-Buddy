import SwiftUI

enum OnboardingStep: Equatable {
    case welcome
    case rosterSetup
    case preferences
    case learnToPlay
    case appTour
    case support
    case ready

    static let progressTotal = 6

    var progressIndex: Int {
        switch self {
        case .welcome: 1
        case .rosterSetup: 2
        case .preferences, .learnToPlay: 3
        case .appTour: 4
        case .support: 5
        case .ready: 6
        }
    }

    func backStep(showsRulesIntro: Bool?, skipsRosterSetup: Bool = false) -> OnboardingStep? {
        switch self {
        case .welcome: nil
        case .rosterSetup: .welcome
        case .preferences, .learnToPlay: skipsRosterSetup ? .welcome : .rosterSetup
        case .appTour:
            showsRulesIntro == true ? .learnToPlay : .preferences
        case .support: .appTour
        case .ready: .support
        }
    }
}

struct OnboardingStepChrome<Content: View, Footer: View>: View {
    let showsSkip: Bool
    let onSkip: () -> Void
    var progressIndex: Int? = nil
    var progressTotal: Int = OnboardingStep.progressTotal
    var showsBack: Bool = false
    var onBack: () -> Void = {}
    @ViewBuilder let content: () -> Content
    @ViewBuilder let footer: () -> Footer

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? 560 : .infinity
    }

    private var scrollBottomPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 120 : DS.Spacing.s4
    }

    private var footerReservedHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 148 : 120
    }

    var body: some View {
        ZStack {
            Brand.background.ignoresSafeArea()

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    ScrollView {
                        content()
                            .frame(maxWidth: contentMaxWidth)
                            .frame(maxWidth: .infinity)
                            .frame(
                                minHeight: max(0, geometry.size.height - footerReservedHeight),
                                alignment: .center
                            )
                            .padding(.horizontal, DS.Spacing.s4)
                            .padding(.top, DS.Spacing.s6)
                            .padding(.bottom, scrollBottomPadding)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .scrollIndicators(.hidden)

                    footer()
                        .frame(maxWidth: contentMaxWidth)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, DS.Spacing.s4)
                        .padding(.top, DS.Spacing.s4)
                        .padding(.bottom, DS.Spacing.s6)
                }
            }
        }
        .toolbar {
            if let progressIndex {
                ToolbarItem(placement: .principal) {
                    Text(L10n.format("onboarding.stepProgress", progressIndex, progressTotal))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.textSecondary)
                        .accessibilityLabel(
                            L10n.format("onboarding.stepProgress", progressIndex, progressTotal)
                        )
                        .accessibilityIdentifier("onboarding_step_progress")
                }
            }

            if showsBack {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Brand.textPrimary)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel(L10n.string("common.back"))
                    .accessibilityIdentifier("onboarding_back")
                }
            }

            if showsSkip {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.onboardingSkip) {
                        onSkip()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary.opacity(0.72))
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("onboarding_skip")
                }
            }
        }
    }
}

struct OnboardingPrimaryButton: View {
    let title: LocalizedStringKey
    var accessibilityIdentifier: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(isEnabled ? Brand.inkOnBright : Brand.textDisabled)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(
                    isEnabled ? Brand.green : Brand.cardElevated,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .modifier(OptionalAccessibilityIdentifier(identifier: accessibilityIdentifier))
    }
}

struct OnboardingChoiceButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    var accessibilityIdentifier: String? = nil
    var accessibilityLabel: LocalizedStringKey? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.s3) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.medium))
                    .foregroundStyle(Brand.green)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 44, height: 44)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(DS.Spacing.s4)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        }
        .buttonStyle(.plain)
        .modifier(OptionalAccessibilityIdentifier(identifier: accessibilityIdentifier))
        .accessibilityLabel(accessibilityLabel ?? title)
    }
}

struct OnboardingHeroStepContent: View {
    let symbolName: String
    let titleKey: String
    let bodyKey: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var pageIconSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 44 : 56
    }

    var body: some View {
        VStack(spacing: DS.Spacing.s4) {
            Image(systemName: symbolName)
                .font(.system(size: pageIconSize, weight: .medium))
                .foregroundStyle(Brand.green)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)

            Text(LocalizedStringKey(titleKey))
                .font(.title.bold())
                .foregroundStyle(Brand.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityAddTraits(.isHeader)

            Text(LocalizedStringKey(bodyKey))
                .font(.body)
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
