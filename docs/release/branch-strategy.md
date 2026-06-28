# Branch strategy — dev vs release

How Dart Buddy separates **full integration** on `dev` from **trimmed App Store builds** on release branches.

---

## Branches

| Branch | Product surface | Purpose |
|--------|-----------------|---------|
| **`dev`** | Full (`ProductSurface.full` or `-enable_full_product_surface` not required) | Daily integration: all 22 shipped modes, 5 tabs, all bundled locales, feature flags per Debug defaults |
| **`release/1.0`** | Lean 1.0 (`ProductSurface.lean1_0`) | App Store 1.0 — X01 + Cricket picker, 4 tabs, English bundle policy |
| **`release/1.1.0`** | Party Pack + Raid (`ProductSurface.party1_1`) | App Store 1.1 — shipped on `master` (tag `1.1.0`) |
| **`release/1.2.0`** | Smart Opponents (`ProductSurface.smart1_2`) | App Store 1.2 — Training Partner, export, de/es/nl/fr |

**Rule:** Never delete shipped code to “trim” a release. Release branches change **reachability** via `ProductSurface` (and optionally `project.yml` locale lists), not engine removal.

---

## `ProductSurface` on `dev`

On `dev`, engineers dogfood the full catalog:

- Modes tab visible
- All shipped `MatchType` values reachable from setup and resume
- `de` / `es` / `nl` / `fr` bundled in `project.yml`
- UI tests run without `-enable_full_product_surface` unless testing lean regressions

`Support/Release/ProductSurface.swift` defaults to lean 1.0 in **Release configuration**. On `dev`, Debug builds and the main `DartBuddy` scheme use full-surface launch args where needed. Release-branch archives flip `ProductSurface` defaults on that branch.

---

## Release branch workflow

1. Cut `release/X.Y` from `dev` (or merge `dev` → `release/X.Y` for a RC).
2. Set `ProductSurface` default to the slice for that version (see [`lean-1.0-implementation-plan.md`](lean-1.0-implementation-plan.md)).
3. Adjust `project.yml` locale resources if the release is English-only.
4. Run **`DartBuddyUILean`** UI suite on the release branch (see [`specs/TestPlanSpec.md`](../specs/TestPlanSpec.md) § UI suites).
5. Device QA + App Store ops per [`1.0.0-ship-checklist.md`](1.0.0-ship-checklist.md).
6. Tag, submit, then merge release branch → `main` / `dev` as appropriate.

---

## CI implications

| Suite | `dev` / PR | `release/*` |
|-------|------------|-------------|
| `DartBuddyCI` (unit + accessibility) | Every PR | Every PR |
| Nightly UI matrix (smoke, gameplay, a11y, l10n, landscape, chrome) | Yes | Yes |
| `DartBuddyUILean` | Skipped | **Required** |

---

## Launch arguments (reference)

| Argument | Use |
|----------|-----|
| `-enable_full_product_surface` | CI UI tests on lean-default Release builds; dogfood full catalog |
| `-enable_lean_product_surface` | Force lean surface on Debug / internal builds |
| `-enable_achievements` | Debug / UI tests for achievement hooks |
| `-ui_test_reset` | Clean in-memory store for UI tests |

**Internal TestFlight (`dev` branch):** Release archives set `DART_BUDDY_INTERNAL_BUILD` in `project.yml` — full `ProductSurface`, achievements, App Intents, and visual dartboard on by default. Runbook: [`dev-internal-testflight-runbook.md`](dev-internal-testflight-runbook.md). Store release branches omit this flag.

Do **not** ship App Store builds with `-enable_full_product_surface` or `DART_BUDDY_INTERNAL_BUILD`.

---

## Related docs

- [`ongoing-release-plan.md`](ongoing-release-plan.md) — version slices
- [`release-tagging.md`](release-tagging.md) — **Estimated release** tags on specs
- [`estimated-release-registry.md`](estimated-release-registry.md) — per-feature store train
- [`lean-1.0-implementation-plan.md`](lean-1.0-implementation-plan.md) — 1.0 `ProductSurface` fields
- [`lean-1.0-app-review-hardening-plan.md`](lean-1.0-app-review-hardening-plan.md) — reachability audit
- [`docs/feature-inventory.md`](../feature-inventory.md) — shipped vs planned features
