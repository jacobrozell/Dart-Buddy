import SwiftUI

enum BadgeMedalState {
    case locked
    case inProgress(percent: Int)
    case unlocked
}

struct BadgeMedal: View {
    let state: BadgeMedalState
    let isHiddenAchievement: Bool

    @ScaledMetric(relativeTo: .title3) private var medalSize: CGFloat = 52

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundFill)
                .overlay {
                    Circle()
                        .strokeBorder(borderColor, lineWidth: 2)
                }
            Image(systemName: iconName)
                .font(.system(size: medalSize * 0.38, weight: .semibold))
                .foregroundStyle(iconColor)
            if case let .inProgress(percent) = state, percent > 0, percent < 100 {
                Text("\(percent)%")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Brand.textPrimary)
                    .padding(4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .offset(y: medalSize * 0.42)
            }
        }
        .frame(width: medalSize, height: medalSize)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var iconName: String {
        switch state {
        case .locked:
            isHiddenAchievement ? "questionmark" : "lock.fill"
        case .inProgress, .unlocked:
            "medal.fill"
        }
    }

    private var backgroundFill: some ShapeStyle {
        switch state {
        case .locked:
            Brand.cardElevated
        case .inProgress:
            Brand.card
        case .unlocked:
            Brand.green.opacity(0.18)
        }
    }

    private var borderColor: Color {
        switch state {
        case .locked:
            Brand.key
        case .inProgress:
            Brand.orange
        case .unlocked:
            Brand.green
        }
    }

    private var iconColor: Color {
        switch state {
        case .locked:
            Brand.textSecondary
        case .inProgress:
            Brand.orange
        case .unlocked:
            Brand.green
        }
    }

    private var accessibilityLabel: String {
        switch state {
        case .locked:
            isHiddenAchievement ? L10n.string("achievements.hidden.accessibility") : L10n.string("achievements.locked.accessibility")
        case let .inProgress(percent):
            L10n.string("achievements.inProgress.accessibility", percent)
        case .unlocked:
            L10n.string("achievements.unlocked.accessibility")
        }
    }
}

struct AchievementUnlockRow: View {
    let presentation: AchievementUnlockPresentation

    var body: some View {
        HStack(spacing: DS.Spacing.s3) {
            BadgeMedal(state: .unlocked, isHiddenAchievement: false)
            VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                Text(L10n.achievementName(presentation.achievementId))
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                Text(L10n.achievementDescription(presentation.achievementId))
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let percent = presentation.progressPercent, !presentation.isNewUnlock, percent < 100 {
                    Text(L10n.string("achievements.progressFormat", percent))
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

struct PlayerAchievementGallerySection: View {
    let progress: [PlayerAchievementProgress]

    private var unlockedCount: Int {
        progress.filter(\.isUnlocked).count
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 72), spacing: DS.Spacing.s3)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                Text(L10n.string("achievements.section.title"))
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                Text(L10n.string("achievements.section.subtitle", unlockedCount, AchievementCatalog.phase1.count))
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
            }

            if progress.isEmpty {
                Text(L10n.string("achievements.empty"))
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: DS.Spacing.s3) {
                    ForEach(sortedDefinitions, id: \.id) { definition in
                        achievementTile(for: definition)
                    }
                }
            }
        }
        .accessibilityIdentifier("playerAchievements_section")
    }

    private var sortedDefinitions: [AchievementDefinition] {
        AchievementCatalog.phase1.sorted { lhs, rhs in
            let left = progress.first { $0.achievementId == lhs.id }
            let right = progress.first { $0.achievementId == rhs.id }
            switch (left?.isUnlocked, right?.isUnlocked) {
            case (true, false): return true
            case (false, true): return false
            default: return lhs.id < rhs.id
            }
        }
    }

    @ViewBuilder
    private func achievementTile(for definition: AchievementDefinition) -> some View {
        let record = progress.first { $0.achievementId == definition.id }
        let state: BadgeMedalState = {
            if record?.isUnlocked == true { return .unlocked }
            if definition.isIncremental, let percent = record?.progressPercent, percent > 0 {
                return .inProgress(percent: percent)
            }
            return .locked
        }()

        VStack(spacing: DS.Spacing.s2) {
            BadgeMedal(state: state, isHiddenAchievement: definition.isHidden)
            Text(record?.isUnlocked == true || !definition.isHidden ? L10n.achievementName(definition.id) : L10n.string("achievements.hidden.title"))
                .font(.caption)
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}
