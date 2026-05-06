# Setup Flow Specification

## 1. Purpose
Define the new-match setup flow: required fields, validation, defaults, and launch into gameplay.

---

## 2. MVP Scope
- Select game mode (`X01`, `Cricket`)
- Select 2..N players from active roster
- Configure X01 options:
  - 301/501
  - legs
  - sets toggle/count
  - checkout mode (`singleOut`, `doubleOut`)
- Start match when valid

---

## 3. UI Specification
- Grouped sections in a single setup screen
- Sticky bottom primary CTA: `Start Match`
- Player picker supports quick add path when no players exist
- Inline validation messages

---

## 4. Validation Rules
- Minimum 2 players required
- No duplicate selected players
- X01 start score must be allowed enum value
- Legs/sets must be positive bounded values
- Checkout mode required for X01

---

## 5. Defaults
- Prefill from saved settings
- Persist last-used setup after successful start
- Restore unsaved setup draft only within current app session (optional)

---

## 6. Data Contract
- Build versioned `MatchConfigPayload`
- Persist config as `MatchRecord.configPayload`
- Include explicit `payloadVersion`

---

## 7. Testing
- Validation matrix tests
- Prefill behavior tests
- Start-match transition test for X01 and Cricket
