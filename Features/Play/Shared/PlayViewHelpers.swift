import SwiftUI

func playLocalizedText(_ key: String) -> Text {
    Text(LocalizedStringKey(key))
}

/// Posts a VoiceOver announcement for gameplay events; no-op for empty strings.
func postAccessibilityAnnouncement(_ text: String) {
    guard !text.isEmpty else { return }
    AccessibilityNotification.Announcement(text).post()
}

/// Hit/miss audio and optional haptics when a bot appends a dart to the visit preview.
func playBotDartEntryFeedback(
    darts: [DartInput],
    previousCount: Int,
    isBotPlaying: Bool,
    audio: any AudioFeedbackService,
    haptics: any HapticsService,
    feedbackPreferences: FeedbackPreferences
) {
    guard isBotPlaying, darts.count > previousCount, let dart = darts.last else { return }
    guard !BotPlaybackPolicy.instantBotTurnsActive(
        instantBotTurnsEnabled: feedbackPreferences.instantBotTurnsEnabled
    ) else { return }
    if dart.isMiss {
        audio.playMiss()
    } else {
        audio.playHit()
    }
    if feedbackPreferences.botDartHapticsEnabled {
        haptics.playImpact()
    }
}

private struct MatchHeaderChromeButtonSizeKey: EnvironmentKey {
    static let defaultValue: CGFloat = 44
}

extension EnvironmentValues {
    /// Square size for buttons docked in the match header trailing slot (40pt in compact height).
    var matchHeaderChromeButtonSize: CGFloat {
        get { self[MatchHeaderChromeButtonSizeKey.self] }
        set { self[MatchHeaderChromeButtonSizeKey.self] = newValue }
    }
}

/// Shared top chrome for in-progress match screens (exit, title, optional trailing action).
struct MatchGameplayHeader<Title: View, Trailing: View>: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    let onExit: () -> Void
    let exitAccessibilityLabel: LocalizedStringKey
    @ViewBuilder let title: () -> Title
    @ViewBuilder let trailing: () -> Trailing

    private var usesCompactHeight: Bool { verticalSizeClass == .compact }

    private var chromeButtonSize: CGFloat { usesCompactHeight ? 40 : 44 }

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
        HStack(alignment: .center, spacing: usesCompactHeight ? DS.Spacing.s2 : DS.Spacing.s3) {
            Button(action: onExit) {
                Image(systemName: "chevron.left")
                    .font((usesCompactHeight ? Font.subheadline : Font.headline).weight(.bold))
                    .foregroundStyle(Brand.green)
                    .frame(width: chromeButtonSize, height: chromeButtonSize)
                    .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
            }
            .accessibilityLabel(exitAccessibilityLabel)
            .accessibilityIdentifier("match_exit")
            Spacer(minLength: DS.Spacing.s2)
            title()
            Spacer(minLength: DS.Spacing.s2)
            trailing()
                // Min bounds (not fixed) so screens can dock more than one chrome button.
                .frame(minWidth: chromeButtonSize, minHeight: chromeButtonSize)
                .environment(\.matchHeaderChromeButtonSize, chromeButtonSize)
        }
        .padding(.horizontal, usesCompactHeight ? DS.Spacing.s3 : DS.Spacing.s4)
        .padding(.top, usesCompactHeight ? 0 : DS.Spacing.s2)
        .padding(.bottom, usesCompactHeight ? DS.Spacing.s1 : DS.Spacing.s2)
        .layoutPriority(2)
    }
}
