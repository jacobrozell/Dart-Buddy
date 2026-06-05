# Localization Specification

## 1. Purpose
Define internationalization and localization strategy from day one so future language expansion is low-risk.

---

## 2. MVP Policy
- Ship with English UI first, but build all UI text through localization resources.
- Never hardcode user-facing strings in SwiftUI views.
- Create and maintain English baseline strings from project start.
- **Wave 1 (shipped):** German (`de`) — system locale only; no in-app language picker.
- **Wave 2 (shipped):** Spanish (`es`) — system locale only; no in-app language picker.
- **Wave 3 (shipped):** Dutch (`nl`) — system locale only; no in-app language picker.

---

## 3. Required Baseline Artifacts
- `Resources/en.lproj/Localizable.strings` (source of truth for keys)
- `Resources/de.lproj/Localizable.strings` (German wave 1)
- `Resources/es.lproj/Localizable.strings` (Spanish wave 2)
- `Resources/nl.lproj/Localizable.strings` (Dutch wave 3)
- Optional structured tables by domain (recommended as app grows):
  - `Resources/en.lproj/Gameplay.strings`
  - `Resources/en.lproj/Settings.strings`
  - `Resources/en.lproj/Errors.strings`

Key rule:
- English strings file is the source of truth for all keys.

---

## 4. String Key Conventions
- Namespaced keys:
  - `play.setup.startMatch`
  - `x01.checkout.doubleOutRequired`
  - `settings.data.reset.confirmTitle`
- Stable keys: do not rename keys casually once referenced.
- No concatenated sentence assembly; localize full phrases.

---

## 5. Formatting and Locale Handling
- Use locale-aware date/time and number formatting APIs.
- Keep score formatting deterministic and culture-safe.
- Ensure pluralization is localized correctly where counts are shown.

---

## 6. Language Expansion Plan (Future)
- Waves 1–3 (`de`, `es`, `nl`) — shipped; see §2.
- **In-app language picker (post-1.0):** Settings override of `Locale`; feature specs remain locale-agnostic (describe behavior, not language). Picker must not break `LocalizationParityTests` key coverage.
- Future waves: additional locales per backlog; same key-parity gate.
- Prioritize strings used in core gameplay first when adding locales.
- Baseball party mode keys: `play.baseball.*`, `play.party.baseball.*`, `history.detail.baseballSummaryFormat`, `history.timeline.baseballTurnFormat`, `history.detail.lineScore*` (including `history.lineScore.emptyCell`, `play.baseball.*AccessibilityFormat`, `play.baseball.playoffRound*`) — see [`BaseballGameSpec.md`](BaseballGameSpec.md).
- Include localization QA and pseudo-localization in CI checks.

---

## 7. Engineering Rules
- PRs adding user-facing text must include localization keys and English value.
- PRs adding keys must update **all** shipped locale files (`en` + `de` + `es` + `nl`).
- `LocalizationParityTests` enforces identical key sets and format-specifier parity (CI).
- Error messages returned from domain/data layers should map to localized keys.

---

## 8. Testing
- `LocalizationParityTests` (`.localization`): en/de/es/nl key set and `%@`/`%d`/etc. parity.
- `GermanLocalizationSmokeUITests`: launch with `-AppleLanguages (de)`; tab bar + Play setup smoke.
- `SpanishLocalizationSmokeUITests`: launch with `-AppleLanguages (es)`; tab bar + Play setup smoke.
- `DutchLocalizationSmokeUITests`: launch with `-AppleLanguages (nl)`; tab bar + Play setup smoke.
- Functional UI tests use default English launch; do not assert English copy in localized smoke suites.
- Pseudo-localization pass for truncation and layout stress (future).
- Right-to-left readiness review (future if RTL languages are added).
- Manual language switch smoke tests across tabs and gameplay flows (Simulator → Deutsch / Español / Nederlands).

### App Store Connect (localized listings, manual)
- Localized subtitle, description, and keywords per shipped locale.
- Screenshots captured with device language set to Deutsch, Español, or Nederlands as appropriate.
- Privacy nutrition labels unchanged; review localized keyword fields before submit.
