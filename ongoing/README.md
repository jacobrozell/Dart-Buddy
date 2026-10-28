# Ongoing work

Plans and projects **in implementation** — approved, specced, and actively being built (not shipped yet).

| Stage | Where it lives |
|-------|----------------|
| Idea / not specced | [`FutureIdeas/`](../FutureIdeas/) |
| **In implementation** | **This folder** + [`docs/plans/`](../docs/plans/) |
| Ship blockers / release train | [`docs/release/`](../docs/release/) |
| Shipped behavior | [`specs/`](../specs/) + [`docs/feature-inventory.md`](../docs/feature-inventory.md) |

**Last updated:** 2026-10-27

## Active

| Plan | Doc | Status | Notes |
|------|-----|--------|-------|
| Solo companion | [`roadmap/solo-companion.md`](../roadmap/solo-companion.md) | Draft | Record + solo/friends. Copy in 1.2; bot stats in 1.2.1; Solo shelf with the catalog. Does not reopen 1.2 features |
| Duo + dynamic layout | [`docs/plans/duo-dynamic-layout-release-plan.md`](../docs/plans/duo-dynamic-layout-release-plan.md) | Draft | Proposed **1.3** after 1.2. Window width, not iPad idiom |
| SwiftUI view extraction | [`docs/plans/swiftui-view-extraction-master-plan.md`](../docs/plans/swiftui-view-extraction-master-plan.md) | In progress | Phases 0–7 done (routes, Activity, summary, setup roster, Players, Settings). Match screens batch + history/stats open |
| Accessibility layout fixes (AXXXL) | [`accessibility/wcag-2.1-aa/SUMMARY.md`](../accessibility/wcag-2.1-aa/SUMMARY.md) | Code done | AXXXL re-capture + screen tracker updates remaining |
| UI screenshot iteration | [`docs/plans/ui-screenshot-iteration-plan.md`](../docs/plans/ui-screenshot-iteration-plan.md) | In progress | Code done; Phase 4 re-capture remaining |
| Co-op mode grouping | [`docs/plans/coop-mode-grouping.md`](../docs/plans/coop-mode-grouping.md) | Partial | Phase 0 done; Raid ships in 1.1 |
| Co-op PvE modes | [`specs/CoopPvEModesSpec.md`](../specs/CoopPvEModesSpec.md) | In progress | Raid ships in 1.1; Fleet/Cerberus/Vault post-1.1 |
| Custom bot architecture | [`docs/plans/custom-bot-architecture-ui-plan.md`](../docs/plans/custom-bot-architecture-ui-plan.md) | Partial | Lean 1.0 ships simple custom bots only |
| Game mode families | [`docs/plans/game-mode-families.md`](../docs/plans/game-mode-families.md) | Approved — not started | Cricket family card + variant sheet |
| Auto scorer | [`docs/plans/auto-scorer-plan.md`](../docs/plans/auto-scorer-plan.md) | Future · not started | Single-phone tip scoring. Not in the 1.2 train. Agent prompt is in the plan |

## See also

- Release train: [`docs/release/ongoing-release-plan.md`](../docs/release/ongoing-release-plan.md)
- Ship blockers: [`docs/release/todo.md`](../docs/release/todo.md)
- Engineering plans index: [`docs/plans/README.md`](../docs/plans/README.md)

## Finished (archive)

| Plan | Shipped | Notes |
|------|---------|-------|
| Lean 1.0 implementation | 1.0.0 | [`docs/release/lean-1.0-implementation-plan.md`](../docs/release/lean-1.0-implementation-plan.md) — implemented |
| App review hardening + 1.0 ship | 1.0.0 (7) | [`docs/release/lean-1.0-app-review-hardening-plan.md`](../docs/release/lean-1.0-app-review-hardening-plan.md) — App Store live 2026-06-22; tag `1.0.0` on `7df4358` |
| Baseball mode | 1.1.0 | [`specs/game-modes/implemented/BaseballGameSpec.md`](../specs/game-modes/implemented/BaseballGameSpec.md) — engine, setup, play, history line score, stats |
| Player export (DBPE v1) | 1.0.0 | [`specs/PlayerExportImportSpec.md`](../specs/PlayerExportImportSpec.md) — export + share sheet; import deferred |
| iPad unified tab bar | 1.0.0 | Sidebar shell removed; dead `usesIPadMainShell` flag deleted 2026-10-27. Window-width layout continues in the Duo plan |
| Release build view decomposition | 2026-06-14 | [`docs/plans/release-build-view-decomposition-plan.md`](../docs/plans/release-build-view-decomposition-plan.md) — implemented |
