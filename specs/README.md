# Specs Index

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

### Play & matches
| Spec | Covers |
|------|--------|
| [`PlayHomeSpec.md`](PlayHomeSpec.md) | Play tab home, resume banner, recent games, navigation |
| [`SetupFlowSpec.md`](SetupFlowSpec.md) | New-match setup, roster, mode options, start/conflict |
| [`QuickAddPlayerSpec.md`](QuickAddPlayerSpec.md) | Fast player create from Play setup |
| [`MatchSpec.md`](MatchSpec.md) | Lifecycle, resume, abandon, persistence |
| [`MatchSummarySpec.md`](MatchSummarySpec.md) | Post-match screen, undo last throw |
| [`X01GameSpec.md`](X01GameSpec.md) | X01 rules, board UI, checkout suggester |
| [`CricketSpec.md`](CricketSpec.md) | Cricket rules, board UI, normal / cut throat |
| [`BaseballGameSpec.md`](BaseballGameSpec.md) | Baseball party mode rules, play UI, history line score |
| [`KillerGameSpec.md`](KillerGameSpec.md) | Killer elimination party mode rules, pick phase, play UI |
| [`BaseballModeDeferredWorkPlan.md`](BaseballModeDeferredWorkPlan.md) | Post-MVP follow-ups (specs, line score, tests, WCAG, demo) |
| [`ScoringInputSpec.md`](ScoringInputSpec.md) | Shared dart-entry pad, undo, submit |

### Opponents
| Spec | Covers |
|------|--------|
| [`BotOpponentSpec.md`](BotOpponentSpec.md) | Preset difficulty bots, `DartBotEngine`, pacing |
| [`TrainingBotSpec.md`](TrainingBotSpec.md) | Training Partner bots, eligibility, skill calibration |

### Players, history, stats, settings
| Spec | Covers |
|------|--------|
| [`PlayerSpec.md`](PlayerSpec.md) | CRUD, archive, identity, player detail |
| [`HistorySpec.md`](HistorySpec.md) | Completed match list, filters, detail |
| [`StatsSpec.md`](StatsSpec.md) | Formulas, aggregates, recompute policy |
| [`StatisticsTabSpec.md`](StatisticsTabSpec.md) | Statistics tab UI, charts, filters |
| [`SettingsSpec.md`](SettingsSpec.md) | Preferences, defaults, data reset |

### App health
| Spec | Covers |
|------|--------|
| [`MigrationRecoverySpec.md`](MigrationRecoverySpec.md) | Migration failure recovery UI |
| [`DeepLinkSpec.md`](DeepLinkSpec.md) | Versioned `dartbuddy://v1/…` URLs, parser, router, deferred delivery |
| [`AppIntentsSpec.md`](AppIntentsSpec.md) | Siri/Shortcuts intents, `IntentRoutingBridge`, feature flag, QA checklist |

## Post-1.0 / Assessment / Archive
- `specs/AppleWatchCompanionSpec.md` + `specs/AppleWatchCompanionAssessment.md`
- `specs/OnlinePlaySpec.md`, `specs/AutoScoringVisionSpec.md`
- `specs/archive/FigmaBuildPlan.md` — historical Figma handoff (UI complete for 1.0)
- `FutureIdeas/backlog.md` — Post-1.0 product backlog (linked from `docs/release/todo.md`)
- `FutureIdeas/additional-game-modes.md` — R&D index for Target-style game modes (Killer, Baseball, etc.)
- `FutureIdeas/killer-darts.md`, `FutureIdeas/baseball-darts.md` — Deep R&D specs (party modes)
- `FutureIdeas/party-practice-modes.md` — Brief R&D for Bob's 27, Around the Clock, Shanghai, Halve-It
- `FutureIdeas/achievements.md` — Game Center assessment (linked from `docs/release/todo.md`)
- `FutureIdeas/play-reminders.md` — Play reminder notifications (linked from `docs/release/todo.md`)

Active work and deferrals: [`docs/release/todo.md`](../docs/release/todo.md). Do not duplicate backlog items here.
