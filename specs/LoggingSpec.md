# Logging Specification

## 1. Purpose
Define a day-1 custom logging system that is console-first in 1.0.0 and easily adaptable to future crash/bug analytics integrations.

---

## 2. Product Constraints
- 1.0.0 ships Firebase Analytics and Crashlytics in **Release** only (gated by real `GoogleService-Info.plist` and feature flags; Debug/CI/UI tests off).
- Logging must be useful in local dev/test and safe for production builds.
- Analytics/crash providers plug in via sinks without rewriting call sites.

---

## 3. Design Goals
- Single logger API used across app layers
- Structured logs (category + event + metadata), not arbitrary print spam
- Compile/runtime control over verbosity by build configuration
- Redaction support for sensitive values

---

## 4. Architecture

## Core Protocols
- `AppLogger`
  - `log(level: LogLevel, category: LogCategory, message: String, metadata: [String: String]?)`
  - convenience helpers: `debug`, `info`, `warning`, `error`, `fault`

- `LogSink`
  - `write(_ entry: LogEntry)`

## Day-1 Sink
- `ConsoleLogSink` only
  - backed by `OSLog`/`Logger` where appropriate
  - developer-readable format in debug

## Future Sinks
- `CrashAnalyticsSink` adapter (alternate providers)
- `FirebaseCrashlyticsLogSink` / `FirebaseAnalyticsLogSink` (implemented; adapter layer only imports Firebase SDKs)

Critical rule:
- App code depends only on `AppLogger`, never on concrete sink SDKs.

---

## 5. Log Schema
- `timestamp`
- `level`
- `category`
- `eventName` (short stable token)
- `message`
- `metadata` (string map, curated keys only)
- `correlationId` (optional, for session/match tracing)

Recommended categories:
- `ui`
- `scoring`
- `persistence`
- `migration`
- `network` (future)
- `vision` (future)
- `watch` (future)
- `security`

---

## 6. Privacy and Redaction
- No PII in logs by default.
- Never log raw player notes, tokens, credentials, or full payload blobs.
- Metadata must be allowlisted.
- Add `RedactionPolicy` for known sensitive fields.

---

## 7. Build Configuration Behavior
- Debug:
  - verbose logs enabled
  - includes debug context metadata
- Release:
  - info/warning/error/fault only
  - debug logs dropped
  - no sensitive diagnostics output to user-accessible channels

---

## 8. Integration Points
- App startup and dependency container boot
- Match lifecycle transitions
- Turn submit/undo outcomes
- Persistence failures and migration results
- Settings reset flow

---

## 9. Testing
- Unit tests for level filtering and metadata redaction
- Sink contract tests (entry forwarding and formatting safety)
- Verify no fatal path logs are swallowed

---

## 10. Future Firebase Integration
- Add Firebase sink adapter behind feature flag.
- Keep existing `AppLogger` API unchanged.
- Map selected `error`/`fault` entries to Crashlytics and selected event telemetry.
- Maintain local console sink for dev even after Firebase adoption.
