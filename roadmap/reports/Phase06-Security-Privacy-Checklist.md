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
- [x] Full transactional wipe behavior verified on device
- [ ] Privacy disclosure text validated for store submission (`docs/privacy.html` updated 2026-06-11 for `client_environment_changed` + reset failure telemetry)

## Outstanding Actions Before RC
- Validate release verbosity behavior (debug dropped in Release).
- Complete bootstrap store recovery validation on device (corrupt store → relaunch).
