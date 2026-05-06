# Swift Testing Tags Specification

## 1. Purpose
Define a consistent tagging strategy for Swift Testing so test selection is reliable across local runs, CI, and release gates.

---

## 2. Design Principles
- Tags must be orthogonal (type, subsystem, feature, profile).
- A test may carry multiple tags.
- Tag names are stable API for CI; avoid renaming without migration.
- Prefer a small canonical set over ad-hoc tag growth.

---

## 3. Canonical Tag Catalog

## 3.1 Test Type Tags (required: exactly one)
- `unit`
- `integration`
- `ui`
- `migration`

## 3.2 Infrastructure/System Tags (optional)
- `swiftdata`
- `networking`
- `logging`
- `performance`
- `security`

## 3.3 Feature Tags (optional, use when applicable)
- `player`
- `match`
- `x01`
- `cricket`
- `history`
- `settings`
- `stats`
- `scoringInput`
- `navigation`
- `setupFlow`

## 3.4 Cross-Cutting Quality Tags (optional)
- `accessibility`
- `localization`
- `offline`
- `online`

## 3.5 Runtime/Future Tags (optional)
- `watch`
- `vision`
- `firebaseFuture`

## 3.6 Execution Profile Tags (optional but encouraged)
- `smoke`
- `regression`
- `critical`
- `slow`
- `flaky` (temporary only; requires follow-up issue)

---

## 4. Naming Rules
- Use lowercase for single-word tags.
- Use lowerCamelCase for multi-word tags (e.g., `scoringInput`, `setupFlow`, `firebaseFuture`).
- Do not use aliases or synonyms (e.g., `db` is not allowed; use `swiftdata`).
- Do not encode environment names in tags (`prod`, `staging`).

---

## 5. Tagging Rules by Test Kind
- Every test must include one type tag from section 3.1.
- Domain/feature tests should include at least one feature tag.
- Persistence tests touching store models should include `swiftdata`.
- Tests validating release blockers should include `critical`.
- Tests > 2 seconds median runtime should include `slow`.
- If unstable, tag `flaky` and add a remediation ticket before merge.

---

## 6. Recommended Combinations
- Player repository contract test:
  - `integration`, `swiftdata`, `player`, `regression`
- X01 checkout rule test:
  - `unit`, `x01`, `critical`, `offline`
- Match resume test:
  - `integration`, `match`, `swiftdata`, `critical`
- Accessibility smoke UI test:
  - `ui`, `accessibility`, `smoke`
- Migration safety test:
  - `migration`, `swiftdata`, `regression`, `critical`

---

## 7. CI Profile Mapping

## Pull Request Fast Lane
- Include: `smoke` or `critical`
- Exclude: `slow`, `flaky`

## Pull Request Full
- Include: `unit`, `integration`
- Exclude: `flaky`

## Nightly
- Include: all tags
- Special emphasis: `ui`, `migration`, `slow`

## Release Candidate Gate
- Include:
  - `regression`
  - `critical`
  - `migration`
  - `accessibility`
  - `localization`
  - `performance`

---

## 8. Governance
- Any new tag must be added to this spec before use.
- Removing/renaming tags requires CI profile updates and changelog note.
- `flaky` tests must have owner + due date and should not persist long-term.

---

## 9. Implementation Notes
- Apply tags at test declaration level in Swift Testing (`@Test(..., .tags(...))`).
- Keep tag usage visible in PR descriptions when adding new test suites.
- Align with:
  - `specs/TestPlanSpec.md`
  - `specs/SpecGovernance.md`
