# Phase 06 Security and Privacy Checklist

## MVP Baseline
- [x] Local-first data model
- [x] Firebase Analytics + Crashlytics in Release only (gated; no telemetry from Debug/CI/UI tests/placeholder plist)
- [x] No ad SDKs
- [x] No third-party tracking identifiers
- [x] Minimal PII scope (display names)

## Logging and Diagnostics
- [x] App uses `AppLogger` abstraction
- [x] Console sink in place
- [x] Redaction policy exists
- [x] No scattered `print` usage detected

## Data Controls
- [x] Settings reset flow exists with destructive confirmation
- [ ] Full transactional wipe behavior verified on device
- [ ] Privacy disclosure text validated for store submission

## Outstanding Actions Before RC
- Run full on-device privacy and reset validation pass.
- Validate release verbosity behavior (debug dropped in Release).
- Complete migration recovery action implementations (retry/export/reset execution paths).
