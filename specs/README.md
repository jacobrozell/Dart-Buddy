# Specs Index

Catalog of all product and system specifications. For **audit coverage** (spec + code paths + Verification dates), see [`SpecGovernance.md`](SpecGovernance.md) §5. For **shipped vs planned** status, see [`docs/feature-inventory.md`](../docs/feature-inventory.md).

## MVP Baselines (Locked)
- Landscape and portrait are both required in MVP.
- Accessibility target is WCAG 2.1 AA.
- UI strings ship in `en`, `de`, `es`, and `nl` (system locale; see `LocalizationSpec.md`).
- CI runs unit + accessibility via `DartBuddyCI` on PR; UI smoke runs nightly (`nightly-ui.yml`) and locally via `DartBuddy` scheme.
- App naming direction avoids "Lite" branding.

## Product and System Specs
- `specs/AppShellSpec.md`
- `specs/ArchitectureSpec.md`
- `specs/NavigationSpec.md`
- `specs/TechStackSpec.md`
- `specs/SwiftData.md`
- `specs/DataSchemaSpec.md`
- `specs/RepositorySpec.md`
- `specs/DesignSystemSpec.md`
- `specs/UIBlueprintSpec.md`
- `specs/UIImplementationSpec.md`
- `specs/UIReviewChecklist.md`
- `specs/TestPlanSpec.md`
- `specs/SecurityPrivacySpec.md`
- `specs/PerformanceSpec.md`
- `specs/ReleaseOpsSpec.md`
- `specs/SpecGovernance.md`
- `specs/AccessibilitySpec.md`
- `specs/LocalizationSpec.md`
- `specs/FirebaseBackendAnalyticsSpec.md`
- `specs/LoggingSpec.md`
- `specs/SwiftTestingTagsSpec.md`
- `specs/AppStoreConnectSpec.md`
- `specs/FeatureFlagConfigSpec.md`
- `specs/DeepLinkSpec.md`
- `specs/AppIntentsSpec.md`
- `specs/ErrorModelSpec.md`

## Feature Specs

### Play & matches (shared)
| Spec | Covers |
|------|--------|
| [`PlayHomeSpec.md`](PlayHomeSpec.md) | Play tab home, resume banner, recent games, navigation |
| [`SetupFlowSpec.md`](SetupFlowSpec.md) | New-match setup, roster, mode options, start/conflict |
| [`QuickAddPlayerSpec.md`](QuickAddPlayerSpec.md) | Fast player create from Play setup |
| [`MatchSpec.md`](MatchSpec.md) | Lifecycle, resume, abandon, persistence |
| [`MatchSummarySpec.md`](MatchSummarySpec.md) | Post-match screen, undo last throw |
| [`ScoringInputSpec.md`](ScoringInputSpec.md) | Shared dart-entry pad, undo, submit |
| [`ModesTabSpec.md`](ModesTabSpec.md) | Modes catalog tab, search, coming soon |

### Game modes — [`game-modes/`](game-modes/)

Split by **implementation status** (not moved to `docs/` — specs remain authoritative per [`SpecGovernance.md`](SpecGovernance.md)).

| Folder | Modes |
|--------|-------|
| **[`game-modes/implemented/`](game-modes/implemented/)** | X01, Cricket, Baseball, Killer, Shanghai |
| **[`game-modes/planned/`](game-modes/planned/)** | 24 catalog stubs |

| Implemented spec | Covers |
|------------------|--------|
| [`game-modes/implemented/X01GameSpec.md`](game-modes/implemented/X01GameSpec.md) | X01 rules, board UI, checkout suggester |
| [`game-modes/implemented/CricketSpec.md`](game-modes/implemented/CricketSpec.md) | Cricket rules, board UI, normal / cut throat |
| [`BaseballGameSpec.md`](game-modes/implemented/BaseballGameSpec.md) | Baseball party mode |
| [`KillerGameSpec.md`](game-modes/implemented/KillerGameSpec.md) | Killer elimination |
| [`game-modes/implemented/ShanghaiGameSpec.md`](game-modes/implemented/ShanghaiGameSpec.md) | Shanghai rounds + bonus |
| [`BaseballModeDeferredWorkPlan.md`](game-modes/implemented/BaseballModeDeferredWorkPlan.md) | Post-MVP baseball follow-ups |

Each game spec includes **§ Player count**, **§ How to Play**, and **§ Localization**. Promote `planned/` → `implemented/` when the engine ships — see [`game-modes/README.md`](game-modes/README.md).

### Opponents
| Spec | Covers |
|------|--------|
| [`BotOpponentSpec.md`](BotOpponentSpec.md) | Preset difficulty bots, `DartBotEngine`, pacing |
| [`TrainingBotSpec.md`](TrainingBotSpec.md) | Training Partner bots, eligibility, skill calibration |
| [`CustomBotSpec.md`](CustomBotSpec.md) | User-defined custom bots, configuration, template resolution, UI phases |

### Players, history, stats, settings
| Spec | Covers |
|------|--------|
| [`PlayerSpec.md`](PlayerSpec.md) | CRUD, archive, identity, player detail |
| [`PlayerExportImportSpec.md`](PlayerExportImportSpec.md) | DBPE v1 export bundle (import deferred) |
| [`HistorySpec.md`](HistorySpec.md) | Activity tab History segment — list, filters, detail |
| [`StatsSpec.md`](StatsSpec.md) | Formulas, aggregates, recompute policy |
| [`StatisticsTabSpec.md`](StatisticsTabSpec.md) | Activity tab Statistics segment — charts, filters |
| [`SettingsSpec.md`](SettingsSpec.md) | Preferences, defaults, data reset entry point |
| [`DeleteAllDataSpec.md`](DeleteAllDataSpec.md) | Reset inventory, scaling checklist, regression tests |

### Gamification (post-1.0 R&D)
| Spec | Covers |
|------|--------|
| [`AchievementsSpec.md`](AchievementsSpec.md) | Local profile achievements, evaluator hooks, undo/revoke, future Game Center bridge |
| [`BadgesSpec.md`](BadgesSpec.md) | Profile medal/gallery UI for achievements |
| [`CampaignSpec.md`](CampaignSpec.md) | Journey tab, stage JSON, stars, primary player, separate stats |
| [`DailyChallengeSpec.md`](DailyChallengeSpec.md) | Once-per-day challenge, push integration with play reminders |

### App health
| Spec | Covers |
|------|--------|
| [`MigrationRecoverySpec.md`](MigrationRecoverySpec.md) | Migration failure recovery UI |
| [`DeepLinkSpec.md`](DeepLinkSpec.md) | Versioned `dartbuddy://v1/…` URLs, parser, router, deferred delivery |
| [`AppIntentsSpec.md`](AppIntentsSpec.md) | Siri/Shortcuts/Apple Intelligence — Phase 1 intents, entities roadmap, `IndexedEntity`, on-screen context, testing ladder |

## Post-1.0 / Assessment / Archive
- `specs/AppleWatchCompanionSpec.md` + `specs/AppleWatchCompanionAssessment.md`
- `specs/OnlinePlaySpec.md`, `specs/AutoScoringVisionSpec.md`
- `specs/archive/FigmaBuildPlan.md` — historical Figma handoff (UI complete for 1.0)
- `FutureIdeas/backlog.md` — Post-1.0 product backlog (linked from `docs/release/todo.md`)
- `FutureIdeas/additional-game-modes.md` — delivery index (rules live in `game-modes/planned/`)
- `FutureIdeas/party-practice-modes.md` — effort notes (superseded for rules by planned specs)
- `FutureIdeas/achievements.md` — Game Center catalog assessment (IDs reused by [`AchievementsSpec.md`](AchievementsSpec.md); GC reporting deferred)
- `FutureIdeas/campaign-mode.md` — R&D brief (superseded for behavior by [`CampaignSpec.md`](CampaignSpec.md))
- `FutureIdeas/play-reminders.md` — Play reminder notifications (scheduling patterns shared with [`DailyChallengeSpec.md`](DailyChallengeSpec.md))

Active work and deferrals: [`docs/release/todo.md`](../docs/release/todo.md). Do not duplicate backlog items here.

## Feature inventory
- [`docs/feature-inventory.md`](../docs/feature-inventory.md) — living register of shipped, partial, and planned features (game modes, localization, intents, CI, Firebase, platforms, etc.)
