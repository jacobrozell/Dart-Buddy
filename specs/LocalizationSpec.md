# Localization Specification

## 1. Purpose
Define internationalization and localization strategy from day one so future language expansion is low-risk.

---

## 2. MVP Policy
- Ship with English UI first, but build all UI text through localization resources.
- Never hardcode user-facing strings in SwiftUI views.
- Create and maintain English baseline strings from project start.

---

## 3. Required Baseline Artifacts
- `en.lproj/Localizable.strings`
- Optional structured tables by domain (recommended as app grows):
  - `en.lproj/Gameplay.strings`
  - `en.lproj/Settings.strings`
  - `en.lproj/Errors.strings`

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
- Add top requested languages in waves.
- Prioritize strings used in core gameplay first.
- Include localization QA and pseudo-localization in CI checks.

---

## 7. Engineering Rules
- PRs adding user-facing text must include localization keys and English value.
- Missing localization key is build/test failure in CI (future gate).
- Error messages returned from domain/data layers should map to localized keys.

---

## 8. Testing
- Pseudo-localization pass for truncation and layout stress.
- Right-to-left readiness review (future if RTL languages are added).
- Manual language switch smoke tests across tabs and gameplay flows.
