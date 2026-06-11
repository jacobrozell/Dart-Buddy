# Migration Recovery Specification

## 1. Purpose
Define user-facing behavior when SwiftData store migration or container bootstrap fails at launch. Schema versioning policy lives in [`SwiftData.md`](SwiftData.md); shell routing is summarized in [`AppShellSpec.md`](AppShellSpec.md).

---

## 2. MVP Scope

### In Scope (1.0.0)
- Full-screen recovery UI blocking main tabs until bootstrap succeeds
- **Retry migration** — re-run `AppBootstrapper.bootstrap()`
- **Export diagnostics** — shareable diagnostic bundle path surfaced to user
- **Reset local data** — destructive SQLite store delete + re-bootstrap (same end state as Settings reset; see [`DeleteAllDataSpec.md`](DeleteAllDataSpec.md))
- Localized error key footnote for support
- Never silent data wipe on first failure

### Out of Scope
- Partial repair / field-level fix
- Cloud backup restore
- In-app migration progress percentage

---

## 3. Bootstrap Flow

```
DartBuddyApp
  └─ AppBootstrapper.bootstrap()
       ├─ .ready(dependencies) → MainTabView
       └─ .migrationRecovery(context) → MigrationRecoveryView
```

`MigrationRecoveryContext` carries:
- `error: AppError` (e.g. `migrationFailed`)
- `options: MigrationRecoveryOptions` (`canRetry`, `canExportDiagnostics`, `canResetData`)

Handlers are injected from `DartBuddyApp`:
- **Retry:** `refreshBootstrapResult()` — returns success when state becomes `.ready`
- **Reset:** `AppStoreReset.deleteSQLiteStore()` then refresh bootstrap

---

## 4. UI Specification (`MigrationRecoveryView`)

Brand scoreboard chrome (`Brand.background`, `Brand.textPrimary/Secondary`).

| Control | Identifier | Role |
|---------|------------|------|
| Title | — | Header — `migration.title` |
| Message | — | Body — `migration.message` |
| Retry | `migration_retry` | Primary recovery |
| Export | `migration_export` | Secondary — shows exported path in footnote |
| Reset | `migration_reset` | Destructive — full local wipe |

Footnotes:
- Error key: `migration.errorKeyFormat`
- State / export path when applicable

No tab bar; user cannot access Play/History until recovery succeeds.

---

## 5. View Model States

`MigrationRecoveryViewModel` tracks async actions:
- Idle, retry in progress, export completed (path), reset in progress, failure keys

Export uses diagnostics service (implementation in `Support/` / bootstrap layer); path displayed for manual share.

---

## 6. Data Safety Rules

- Reset is explicit user action on destructive button
- Retry does not delete store
- Completed match history is lost only after reset (same as Settings reset policy)
- Post-reset: fresh schema at current version, default settings seed

---

## 7. Error Model

Maps to [`ErrorModelSpec.md`](ErrorModelSpec.md):
- `migrationFailed` → recovery screen (not toast)
- Logger: `fault` level for boot blockers per logging policy

---

## 8. Testing

## Unit
- `MigrationRecoveryViewModelTests` — retry/reset/export state transitions

## Manual / RC
- Forced migration failure fixture or incompatible store bump
- Verify retry, export file exists, reset → main tabs load
- Tracked: `docs/release/todo.md` § Migration recovery smoke

---

## 9. Accessibility verification
- Manual: [`migration-recovery.md`](../accessibility/wcag-2.1-aa/screens/migration-recovery.md)
- Identifiers: `migration_retry`, `migration_export`, `migration_reset`

## 10. Analytics
§12 — `app_bootstrap_migration_failure` (Analytics + Crashlytics).

## 11. Verification
| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-04 |
| **Commit** | `0c25396` |
| **Code** | `MigrationRecoveryView.swift`, `AppBootstrapper.swift` |

---

## 12. Future Improvements
- Optional CSV export of match data before reset (`FutureIdeas/backlog.md`)
- Retry with backup copy of SQLite file
