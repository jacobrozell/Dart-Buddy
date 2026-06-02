# Migration Recovery

| Field | Value |
|-------|-------|
| Screen ID | `migration-recovery` |
| Primary source | `App/MigrationRecoveryView.swift` |
| Core flow | No (global error) |
| Last verified | 2026-06-02 |
| Screen status | `Partial` |

## Criterion checklist

| ID | Status | Implementation notes | Evidence |
|----|--------|----------------------|----------|
| P-1.1.1 | Pass | Actions are text buttons | |
| P-1.3.1 | Pass | Linear VStack | |
| P-1.3.2 | Partial | Retry → export → reset order in code | |
| P-1.3.4 | Untested | | |
| P-1.4.1 | Pass | Text explains failure | |
| P-1.4.3 | Untested | | |
| P-1.4.4 | Untested | | |
| P-1.4.10 | Untested | | |
| P-1.4.11 | Untested | | |
| O-2.4.3 | Partial | Manual VO pending | |
| O-2.4.4 | Pass | Retry, export, reset labels + IDs | |
| O-2.5.3 | Pass | Button labels match visible text | |
| DBX-TARGET-44 | Pass | System button sizing | |
| U-3.1.1 | Pass | L10n | |
| U-3.3.1 | Pass | Error key + message text | |
| U-3.3.2 | N/A | | |
| R-4.1.2 | Pass | `migration_retry`, `migration_export`, `migration_reset` | |
| DBX-CONTRAST-MODES | Untested | | |

## Open work

- [x] Recovery CTAs: labels and identifiers
- [ ] Manual VoiceOver pass on recovery / reset paths

## Verification log

| Date | Tester | Result | Notes |
|------|--------|--------|-------|
| 2026-06-02 | Agent | Partial | Code complete; screen hard to trigger in sim |
