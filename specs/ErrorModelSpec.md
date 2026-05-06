# Error Model Specification

## 1. Purpose
Define a canonical error taxonomy and handling model across domain, data, and UI layers so failures are predictable, testable, and user-safe.

---

## 2. Design Principles
- Typed errors over stringly-typed failures
- User-facing messages must be mapped from error codes, not raw exception text
- Logging severity aligns with error class
- Recoverable paths should be explicit in UI state

---

## 3. Error Taxonomy

## Domain Errors
- `validationFailed`
- `invalidGameState`
- `ruleViolation` (e.g., invalid checkout in `doubleOut`)
- `unsupportedOperation`

## Data/Persistence Errors
- `notFound`
- `conflict`
- `serializationFailed`
- `migrationFailed`
- `storageUnavailable`

## Integration/Network Errors (future)
- `unreachable`
- `timeout`
- `unauthorized`
- `rateLimited`
- `serverRejected`

## System Errors
- `unknown`
- `cancelled`

---

## 4. Canonical Error Shape
- `code: ErrorCode`
- `layer: ErrorLayer` (`domain`, `data`, `integration`, `system`)
- `severity: ErrorSeverity` (`info`, `warning`, `error`, `fault`)
- `isRecoverable: Bool`
- `userMessageKey: String` (localization key)
- `debugContext: [String: String]` (non-PII)
- `underlyingError: Error?` (internal only)

---

## 5. Mapping Rules
- Domain/data layers throw typed errors.
- ViewModels map typed errors into UI states (`inlineValidation`, `toast`, `blockingError`, `recoveryScreen`).
- Raw underlying errors never surface directly to users.
- All user messages must be localization keys (see `specs/LocalizationSpec.md`).

---

## 6. Logging Rules
- `warning`: recoverable expected failures (validation, temporary IO)
- `error`: unexpected but non-fatal functional failures
- `fault`: crash-risk, corruption, migration boot blockers
- Include `errorCode`, `layer`, and correlation IDs in logs

Logging implementation references:
- `specs/LoggingSpec.md`

---

## 7. UI Recovery Patterns
- Validation errors -> inline field messaging
- Recoverable operation failures -> retry affordance
- Migration/storage boot failures -> dedicated recovery screen
- Unknown fatal states -> safe fallback + diagnostics capture path

---

## 8. Testing Requirements
- Unit tests for error code mapping per layer
- Integration tests for recovery behavior
- Ensure all surfaced `userMessageKey` values exist in English strings baseline
- Verify no raw exception text appears in user-visible UI

---

## 9. Future Extensions
- Remote error grouping codes for backend observability
- Correlation between client error IDs and server trace IDs
- Error budget tracking for online match reliability
