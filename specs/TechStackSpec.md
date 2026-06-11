# Tech Stack and Dependencies Specification

## 1. Purpose
Define the concrete technical stack for 1.0.0, including which Swift Package Manager dependencies are required vs optional.

---

## 2. Core Stack (MVP)
- Language: `Swift 5.10+`
- UI: `SwiftUI`
- Persistence: `SwiftData` + `VersionedSchema` migration plan
- Charts (future-facing): `Swift Charts` (Apple framework, no external package)
- Testing:
  - Primary: `Swift Testing` (`Testing` module) for unit/integration
  - Legacy/interoperability: `XCTest` where needed
  - UI automation: `XCUITest` (CI smoke + WCAG + localization launch suites; broader matrix post-1.0)
- Future companion target: `watchOS` app using `WatchConnectivity`

All of the above are Apple-native and require no external SPM packages.

---

## 3. SPM Dependency Policy

## Required External SPM Packages (1.0.0)
- **None required** for app functionality.

Rationale:
- Faster build times
- Smaller security surface
- Lower maintenance burden
- Easier App Store long-term reliability

## Approved Optional Packages (Only if clear value emerges)
- `pointfreeco/swift-snapshot-testing`
  - Use case: deterministic UI screenshot regression tests
  - Scope: test target only
- `nicklockwood/SwiftFormat` (or equivalent)
  - Use case: code style automation in CI/dev workflow
  - Scope: tooling only, not runtime

Hard rule:
- Do not add runtime packages unless there is a concrete gap not covered by Apple frameworks.

---

## 4. Architecture Libraries Decision
- Do not pull in a full external architecture framework in v1.
- Keep internal lightweight pattern:
  - feature `ViewModel`
  - pure domain services (`X01Engine`, `CricketEngine`, `StatsService`)
  - repository protocols + SwiftData implementations

This keeps the codebase simple while preserving testability.

---

## 5. Input/Keyboard Library Decision
- Do not use a third-party keyboard package.
- Build a native `ScoringInputPad` component in SwiftUI.
- Support both:
  - total-score entry (`0...180`)
  - dart-by-dart entry (`S`, `D`, `T` modifiers + segment value)

Example:
- User taps `T` then `20` -> records dart as triple 20 (60 points).

---

## 6. Project Configuration Notes
- Target iOS 18+ (required for SwiftData `#Index` on `SchemaV2.2.0`; aligns with `PlayerSpec.md`).
- Keep all external dependency declarations in one place (`Package.swift` or Xcode package list) and review quarterly.
- Add dependency approval checklist before introducing any new package:
  - maintenance health
  - security/license
  - replacement plan
  - measurable need

---

## 7. Future Dependencies (Post-1.0.0, if needed)
- Networking/sync SDK only when cloud sync scope is approved
- Crash/observability tools only with explicit privacy policy updates
- Never add ad/attribution SDKs for this product line
- Apple Watch connectivity should use Apple-native `WatchConnectivity` (no third-party runtime package)
- Camera auto-scoring R&D should start with Apple-native `AVFoundation` + `Vision` before any third-party CV tooling
- Firebase roadmap integration is defined in `specs/FirebaseBackendAnalyticsSpec.md`
