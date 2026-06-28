import SwiftUI

struct SetupHomeChrome<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @Binding var startTask: Task<Void, Never>?
    let onStart: () -> Void
    var onShowCustomBot: (() -> Void)?
    var onShowAddPlayer: (() -> Void)?
    @ViewBuilder let content: () -> Content

    private var setupStickyShadowColor: Color {
        colorScheme == .light ? .black.opacity(0.08) : .black.opacity(0.25)
    }

    private var setupFooterMaxWidth: CGFloat {
        if GameplayLayout.usesIPadMainShell() { return .infinity }
        return GameplayLayout.contentMaxWidth(horizontalSizeClass: horizontalSizeClass)
    }

    private var usesWideLayout: Bool {
        GameplayLayout.usesWideSetupHomeLayout(
            horizontalSizeClass: horizontalSizeClass,
            dynamicTypeSize: dynamicTypeSize
        )
    }

    var body: some View {
        ScrollView(.vertical) {
            content()
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .background(Brand.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SetupHomeStartFooter(
                setupViewModel: setupViewModel,
                startTask: $startTask,
                onStart: onStart,
                onShowCustomBot: usesWideLayout ? onShowCustomBot : nil,
                onShowAddPlayer: usesWideLayout ? onShowAddPlayer : nil
            )
            .frame(maxWidth: setupFooterMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.top, DS.Spacing.s3)
            .padding(.bottom, DS.Spacing.s2)
            .background {
                Brand.background
                    .shadow(color: setupStickyShadowColor, radius: 10, y: -4)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}
