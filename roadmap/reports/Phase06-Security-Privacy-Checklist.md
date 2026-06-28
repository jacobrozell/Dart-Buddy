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
- [x] Privacy disclosure text updated for 1.1 (`docs/privacy.html` — June 27, 2026: all shipped modes, `game_mode_*` events, anonymous User ID)

## Analytics ops (1.1 RC)
- [ ] GA4 custom dimensions registered — [`1.1.0-ga4-custom-dimensions.md`](../../docs/release/1.1.0-ga4-custom-dimensions.md) (audit 2026-06-27: **none registered yet**)
- [ ] TestFlight telemetry smoke after dimensions registered

## Outstanding Actions Before RC
- Validate release verbosity behavior (debug dropped in Release).
- Complete bootstrap store recovery validation on device (corrupt store → relaunch).
- Complete **1.0 → 1.1** SwiftData upgrade smoke on physical device.

**Last updated:** 2026-06-27
