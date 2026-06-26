import SwiftUI

enum BadgeMedalState {
    case locked
    case inProgress(percent: Int)
    case unlocked
}

struct BadgeMedal: View {
    let state: BadgeMedalState
    let isHiddenAchievement: Bool
    var iconSystemName: String = "medal.fill"
    var size: BadgeMedalSize = .gallery

    @ScaledMetric(relativeTo: .title3) private var gallerySize: CGFloat = 52
    @ScaledMetric(relativeTo: .body) private var summarySize: CGFloat = 44
    @ScaledMetric(relativeTo: .largeTitle) private var detailSize: CGFloat = 88

    private var medalSize: CGFloat {
        switch size {
        case .gallery: gallerySize
        case .summary: summarySize
        case .detail: detailSize
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundFill)
                .overlay {
                    Circle()
                        .strokeBorder(borderColor, lineWidth: size == .detail ? 3 : 2)
                }
            Image(systemName: displayIconName)
                .font(.system(size: medalSize * 0.38, weight: .semibold))
                .foregroundStyle(iconColor)
            if case let .inProgress(percent) = state, percent > 0, percent < 100, size != .detail {
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

    private var displayIconName: String {
        switch state {
        case .locked:
            isHiddenAchievement ? "questionmark" : "lock.fill"
        case .inProgress, .unlocked:
            iconSystemName
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
            L10n.format("achievements.inProgress.accessibility", percent)
        case .unlocked:
            L10n.string("achievements.unlocked.accessibility")
        }
    }
}

enum BadgeMedalSize {
    case summary
    case gallery
    case detail
}

struct AchievementUnlockRow: View {
    let presentation: AchievementUnlockPresentation

    private var definition: AchievementDefinition? {
        AchievementCatalog.definition(for: presentation.achievementId)
    }

    var body: some View {
        HStack(spacing: DS.Spacing.s3) {
            BadgeMedal(
                state: .unlocked,
                isHiddenAchievement: definition?.isHidden == true,
                iconSystemName: definition?.iconSystemName ?? "medal.fill",
                size: .summary
            )
            VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                HStack(spacing: DS.Spacing.s2) {
                    Text(L10n.achievementName(presentation.achievementId))
                        .font(.headline)
                        .foregroundStyle(Brand.textPrimary)
                    if presentation.isNewUnlock {
                        Text(L10n.string("achievements.newBadge"))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Brand.textPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Brand.green.opacity(0.25), in: Capsule())
                    }
                }
                Text(L10n.achievementDescription(presentation.achievementId))
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let progressText = progressSubtitle {
                    Text(progressText)
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var progressSubtitle: String? {
        guard let percent = presentation.progressPercent,
              let definition,
              let counts = definition.progressCount(from: percent),
              !presentation.isNewUnlock,
              percent < 100 else {
            return nil
        }
        return L10n.format("achievements.progressCountFormat", counts.current, counts.threshold)
    }
}

struct PlayerAchievementGallerySection: View {
    let progress: [PlayerAchievementProgress]
    @State private var selectedAchievementId: String?

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
                Text(L10n.format("achievements.section.subtitle", unlockedCount, AchievementCatalog.phase1.count))
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
            }

            if unlockedCount == 0 {
                Text(L10n.string("achievements.empty"))
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: DS.Spacing.s3) {
                ForEach(sortedDefinitions, id: \.id) { definition in
                    achievementTile(for: definition)
                }
            }
        }
        .accessibilityIdentifier("playerAchievements_section")
        .sheet(item: Binding(
            get: { selectedAchievementId.map { AchievementGallerySelection(id: $0) } },
            set: { selectedAchievementId = $0?.id }
        )) { selection in
            AchievementDetailSheet(
                achievementId: selection.id,
                progress: progress.first { $0.achievementId == selection.id }
            )
        }
    }

    private var sortedDefinitions: [AchievementDefinition] {
        AchievementCatalog.phase1.sorted { lhs, rhs in
            let leftRank = sortRank(for: lhs)
            let rightRank = sortRank(for: rhs)
            if leftRank.tier != rightRank.tier { return leftRank.tier < rightRank.tier }
            if leftRank.secondary != rightRank.secondary { return leftRank.secondary > rightRank.secondary }
            return lhs.id < rhs.id
        }
    }

    private func sortRank(for definition: AchievementDefinition) -> (tier: Int, secondary: TimeInterval) {
        let record = progress.first { $0.achievementId == definition.id }
        if record?.isUnlocked == true {
            return (0, record?.unlockedAt?.timeIntervalSince1970 ?? 0)
        }
        if definition.isIncremental, let percent = record?.progressPercent, percent > 0 {
            return (1, TimeInterval(percent))
        }
        return (2, 0)
    }

    @ViewBuilder
    private func achievementTile(for definition: AchievementDefinition) -> some View {
        let record = progress.first { $0.achievementId == definition.id }
        let state = medalState(for: definition, record: record)
        let showsName = record?.isUnlocked == true || !definition.isHidden

        Button {
            selectedAchievementId = definition.id
        } label: {
            VStack(spacing: DS.Spacing.s2) {
                BadgeMedal(
                    state: state,
                    isHiddenAchievement: definition.isHidden,
                    iconSystemName: definition.iconSystemName,
                    size: .gallery
                )
                Text(showsName ? L10n.achievementName(definition.id) : L10n.string("achievements.hidden.title"))
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                if let progressCaption = progressCaption(for: definition, record: record) {
                    Text(progressCaption)
                        .font(.caption2)
                        .foregroundStyle(Brand.orange)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("playerAchievement_\(definition.id.replacingOccurrences(of: ".", with: "_"))")
    }

    private func medalState(for definition: AchievementDefinition, record: PlayerAchievementProgress?) -> BadgeMedalState {
        if record?.isUnlocked == true { return .unlocked }
        if definition.isIncremental, let percent = record?.progressPercent, percent > 0 {
            return .inProgress(percent: percent)
        }
        return .locked
    }

    private func progressCaption(for definition: AchievementDefinition, record: PlayerAchievementProgress?) -> String? {
        guard definition.isIncremental,
              let percent = record?.progressPercent,
              percent > 0,
              record?.isUnlocked != true,
              let counts = definition.progressCount(from: percent) else {
            return nil
        }
        return L10n.format("achievements.progressCountFormat", counts.current, counts.threshold)
    }
}

private struct AchievementGallerySelection: Identifiable {
    let id: String
}

private struct AchievementDetailSheet: View {
    let achievementId: String
    let progress: PlayerAchievementProgress?
    @Environment(\.dismiss) private var dismiss

    private var definition: AchievementDefinition? {
        AchievementCatalog.definition(for: achievementId)
    }

    private var state: BadgeMedalState {
        if progress?.isUnlocked == true { return .unlocked }
        if let definition, definition.isIncremental, let percent = progress?.progressPercent, percent > 0 {
            return .inProgress(percent: percent)
        }
        return .locked
    }

    private var showsDetails: Bool {
        progress?.isUnlocked == true || definition?.isHidden != true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.s4) {
                    BadgeMedal(
                        state: state,
                        isHiddenAchievement: definition?.isHidden == true,
                        iconSystemName: definition?.iconSystemName ?? "medal.fill",
                        size: .detail
                    )
                    .padding(.top, DS.Spacing.s4)

                    Text(showsDetails ? L10n.achievementName(achievementId) : L10n.string("achievements.hidden.title"))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Brand.textPrimary)
                        .multilineTextAlignment(.center)

                    if showsDetails {
                        Text(L10n.achievementDescription(achievementId))
                            .font(.body)
                            .foregroundStyle(Brand.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    statusSection
                }
                .padding(.horizontal, DS.Spacing.s4)
                .padding(.bottom, DS.Spacing.s6)
                .readableRootContentWidth(nil)
            }
            .background(Brand.background.ignoresSafeArea())
            .navigationTitle(L10n.string("achievements.detail.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.summaryDone) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var statusSection: some View {
        if progress?.isUnlocked == true, let unlockedAt = progress?.unlockedAt {
            Text(L10n.format("achievements.detail.unlockedOn", formattedDate(unlockedAt)))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.green)
        } else if let definition, let percent = progress?.progressPercent, percent > 0,
                  let counts = definition.progressCount(from: percent) {
            VStack(spacing: DS.Spacing.s2) {
                Text(L10n.format("achievements.progressCountFormat", counts.current, counts.threshold))
                    .font(.headline)
                    .foregroundStyle(Brand.orange)
                Text(L10n.format("achievements.progressFormat", percent))
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
            }
        } else {
            Text(L10n.string("achievements.detail.lockedHint"))
                .font(.subheadline)
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
    }
}
