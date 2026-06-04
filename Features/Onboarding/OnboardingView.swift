import SwiftUI

struct OnboardingView: View {
    private struct PageModel: Identifiable {
        let id: Int
        let symbolName: String
        let titleKey: String
        let bodyKey: String
    }

    let mode: OnboardingPresentationMode
    var store: OnboardingStore = OnboardingStore()
    var logger: (any AppLogger)?
    var preferredColorScheme: ColorScheme?
    let onFinished: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var pageIndex = 0

    private var pageContentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? 560 : .infinity
    }

    private var pageIconSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 44 : 56
    }

    private static let pages: [PageModel] = [
        PageModel(id: 0, symbolName: "target", titleKey: "onboarding.welcome.title", bodyKey: "onboarding.welcome.body"),
        PageModel(id: 1, symbolName: "house.fill", titleKey: "onboarding.play.title", bodyKey: "onboarding.play.body"),
        PageModel(id: 2, symbolName: "person.2.fill", titleKey: "onboarding.players.title", bodyKey: "onboarding.players.body"),
        PageModel(id: 3, symbolName: "clock.arrow.circlepath", titleKey: "onboarding.history.title", bodyKey: "onboarding.history.body"),
        PageModel(id: 4, symbolName: "checkmark.circle.fill", titleKey: "onboarding.ready.title", bodyKey: "onboarding.ready.body")
    ]

    private var isLastPage: Bool {
        pageIndex >= Self.pages.count - 1
    }

    var body: some View {
        NavigationStack {
            onboardingContent
        }
    }

    private var onboardingContent: some View {
        ZStack {
            Brand.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $pageIndex) {
                    ForEach(Self.pages) { page in
                        pageContent(page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageIndicator
                    .padding(.top, DS.Spacing.s4)

                footer
                    .padding(.horizontal, DS.Spacing.s4)
                    .padding(.top, DS.Spacing.s4)
                    .padding(.bottom, DS.Spacing.s6)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.onboardingSkip) {
                    finish(skipped: true)
                }
                .foregroundStyle(Brand.textSecondary)
                .accessibilityIdentifier("onboarding_skip")
            }
        }
        .preferredColorScheme(preferredColorScheme)
        .interactiveDismissDisabled(mode == .firstLaunch)
    }

    private func pageContent(_ page: PageModel) -> some View {
        ScrollView {
            VStack(spacing: DS.Spacing.s4) {
                Image(systemName: page.symbolName)
                    .font(.system(size: pageIconSize, weight: .medium))
                    .foregroundStyle(Brand.green)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)
                    .padding(.top, DS.Spacing.s6)

                Text(LocalizedStringKey(page.titleKey))
                    .font(.title.bold())
                    .foregroundStyle(Brand.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text(LocalizedStringKey(page.bodyKey))
                    .font(.body)
                    .foregroundStyle(Brand.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: pageContentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s6)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var pageIndicator: some View {
        HStack(spacing: DS.Spacing.s2) {
            ForEach(Self.pages) { page in
                Circle()
                    .fill(page.id == pageIndex ? Brand.green : Brand.cardElevated)
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            L10n.format("onboarding.pageIndicator.accessibility", pageIndex + 1, Self.pages.count)
        )
        .id(pageIndex)
    }

    private var footer: some View {
        VStack(spacing: DS.Spacing.s3) {
            if isLastPage {
                Button(L10n.onboardingGetStarted) {
                    finish(skipped: false)
                }
                .buttonStyle(.borderedProminent)
                .tint(Brand.green)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("onboarding_get_started")
            } else {
                Button(L10n.onboardingNext) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pageIndex += 1
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Brand.green)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("onboarding_next")
            }
        }
    }

    private func finish(skipped: Bool) {
        if mode == .firstLaunch {
            store.markCompleted()
            logger?.debug(
                .ui,
                eventName: "onboarding_completed",
                message: "First-launch onboarding finished.",
                metadata: ["skipped": skipped ? "true" : "false"]
            )
        }
        onFinished()
    }
}
