# Release and Operations Specification

## 1. Purpose
Define release workflow, quality gates, and operational readiness for MVP and subsequent versions.

---

## 2. Versioning
- App versioning: semantic (`major.minor.patch`)
- Persistence schema versioning per `specs/SwiftData.md`
- Every schema change requires migration tests before release

---

## 3. Release Pipeline
1. Feature freeze
2. Full CI pass (unit/integration/UI)
3. Migration smoke tests
4. Manual QA checklist pass
5. App Store metadata and privacy verification
6. Staged rollout decision

---

## 4. Release Gates
- No critical crashes in test cycle
- X01 and Cricket core flows verified
- Undo and resume paths verified
- Data reset flow verified
- Accessibility smoke pass complete

---

## 5. Operational Diagnostics
- Structured local logging categories:
  - persistence
  - scoring engine
  - migration
  - settings/reset
- User-facing safe recovery paths for migration issues
- Logging implementation and schema are defined in `specs/LoggingSpec.md`

---

## 6. Incident Playbook (Future Online)
- Detect incident class (sync, integrity, outage)
- Disable affected feature path via config/flag
- Preserve event logs for audit
- Publish user status update and remediation ETA

---

## 7. Artifacts
- Release notes template
- QA sign-off template
- Migration report template
- Rollback and hotfix criteria
