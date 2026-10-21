# Review lane Task prompts (Dart Buddy)

Substitute `{REPO}` `{BRANCH}` `{BASE}` `{VERSION}` `{APP}` `{PLATFORM}`. Do not modify product files. Return verdict + `Severity | Location (file:line) | Finding`.

Default: `{APP}=Dart Buddy` · `{PLATFORM}=ios`.

---

## Bugbot

`subagent_type: bugbot` · `description: Bugbot`

```
Full Repository Path: {REPO}
Diff: branch changes
Custom Instructions: {APP} {VERSION} release-readiness on {BRANCH} vs {BASE}. Prioritize user-facing bugs in new/changed flows this version (game modes, match lifecycle, persistence/migrations, undo, setup gating, ProductSurface, analytics).
```

If reviewing a remote branch that is not the current checkout, add: `Base Branch: {BASE}` and name `{BRANCH}` in Custom Instructions so the agent diffs the intended refs.

## Security

`subagent_type: security-review` · `description: Security Review`

```
Full Repository Path: {REPO}
Diff: branch changes
Custom Instructions: {APP} {VERSION} release-readiness. Check PII in analytics, secrets/plists, permission strings vs real use, backup/export exposure, and privacy nutrition vs what the build collects (Firebase Analytics/Crashlytics in Release).
```

---

## Accessibility

`subagent_type: generalPurpose` · `description: Accessibility review`

```
You are the Accessibility review lane for {APP} {VERSION}.

Repo: {REPO}
Branch: {BRANCH} vs {BASE}. Do not modify files.

Read accessibility/audits/ (latest), accessibility/Manual_todo.md, accessibility/wcag-2.1-aa/SUMMARY.md, AccessibilitySpec, design tokens, and new/changed UI on this branch.

Review WCAG 2.1 AA plus Apple HIG Accessibility:
- VoiceOver labels, traits, reading order on new surfaces
- Dynamic Type / font scale clipping
- Contrast on new chrome
- Reduce Motion / animation
- Touch targets ≥44pt
- Accessibility identifiers for new controls
- Color-only state
- Dialog / banner announcements

Return:
1. Verdict: Ready / Ready with nits / Block {VERSION}
2. Table: Severity | Location (file:line) | Finding | Guideline
3. Highest first. Real file:line only.
4. Short “what’s solid”
5. Manual VoiceOver scripts still needed. Do not claim you ran them unless you did.
```

## Architecture

`subagent_type: generalPurpose` · `description: Architecture review`

```
You are the Architecture review lane for {APP} {VERSION}.

Repo: {REPO}
Branch: {BRANCH} vs {BASE}. Do not modify files.

Read docs/release/branch-strategy.md, ProductSurface, MatchLifecycle*, Domain engines vs Features/Play UI, SchemaV2 / SwiftData migration docs, and the version plan if present.

Evaluate:
- Domain/Feature boundaries; rules leaking into UI
- Migration / schema safety for live users
- ProductSurface / feature-flag consistency (hidden vs shipped modes)
- Navigation / resume / review-request state
- Telemetry only through app logger (no direct Analytics/Crashlytics from features)
- What must ship vs defer to the next patch

Return:
1. Verdict: Ready / Ready with nits / Block {VERSION}
2. Table: Severity | Location (file:line) | Finding | Risk if shipped
3. Ship-blockers vs defer-to-next-version, explicitly.
```

## UI/UX

`subagent_type: generalPurpose` · `description: UI/UX review`

```
You are the UI/UX review lane for {APP} {VERSION}.

Repo: {REPO}
Branch: {BRANCH} vs {BASE}. Do not modify files.

Read docs/ux-design-review.md, DesignSystem/, specs/DesignSystemSpec.md, gameplay-layout docs, and new/changed match + setup screens on this branch.

Evaluate (ship-risk first, not speculative redesign):
- First-run / setup cognitive load for new modes
- Match screen hierarchy (score, turn, pad) consistency across modes
- Mode accent / identity without color-only meaning
- Empty / error / resume states
- Dynamic Type and landscape/iPad layout regressions
- Copy tone vs Learn to play / What's New
- Marketing screenshot freshness vs actual UI (note gaps; do not claim visual QA on device unless you did)

Return:
1. Verdict: Ready / Ready with nits / Block {VERSION}
2. Table: Severity | Location (file:line) | Finding | User impact
3. Top polish wins that are NOT blockers.
4. What already feels coherent.
```

## Code smells

`subagent_type: generalPurpose` · `description: Code smells review`

```
You are the Code smells / maintainability review lane for {APP} {VERSION}.

Repo: {REPO}
Branch: {BRANCH} vs {BASE}. Do not modify files.

Look for ship-risk smells: god types, duplicated domain rules, dead/gated-half-wired paths (EmptyView routes, fatalError defaults for “shipped” modes), force unwraps, side effects in view body, missing tests for shipped behavior.

Skip style-only nits and file-split work already planned for a later version unless they are bugs.

Return:
1. Verdict: Ready / Ready with nits / Block {VERSION} (block only for ship-risk)
2. Table: Severity | Location (file:line) | Smell | Why it matters for {VERSION}
3. Top 3 cleanups that are NOT blockers.
```

## Tests

`subagent_type: generalPurpose` · `description: Run test suite`

```
You are the Test runner lane for {APP} {VERSION}.

Repo: {REPO}
Branch: {BRANCH}. Do not modify product code. You MAY generate the Xcode project if required to run tests.

Actually run the project’s unit tests, then UI tests if feasible.

iOS: docs/testing.md / docs/testing/, CI scripts, xcodebuild; unsigned simulator when available.

Return:
1. Verdict: Pass / Pass with gaps / Fail (block {VERSION})
2. Commands + destination
3. executed / passed / failed / skipped
4. Failure table: Test | File | Error (truncated)
5. Coverage gaps for this version’s shipped behavior
If tests cannot run, say exactly why and what you tried.
```

## Store policy

`subagent_type: generalPurpose` · `description: Store policy review`

```
You are the store-policy review lane for {APP} {VERSION} ({PLATFORM}).

Repo: {REPO}
Branch: {BRANCH} vs {BASE}. Do not modify files.

Fetch current official guidelines:
- iOS: https://developer.apple.com/app-store/review/guidelines/

Read docs/release/*ship-checklist*, App Store copy, privacy/support HTML, Info.plist permissions, review-prompt code, ProductSurface, and What’s New / screenshots docs.

Map the binary + metadata to 2.1 completeness, 2.3 accurate metadata, privacy, review prompting, hidden/unfinished UI, age rating, and export/encryption.

Return:
1. Verdict: Likely approve / Risk of rejection / Likely reject
2. Table: Guideline | Risk | Location | Issue | Fix before submit (yes/no)
3. Suggested Notes for Review
4. Metadata gaps (What’s New, screenshots, privacy, min OS)
5. What is already in good shape
```

## Data integrity

`subagent_type: generalPurpose` · `description: Data integrity review`

```
You are the Data integrity review lane for {APP} {VERSION}.

Repo: {REPO}
Branch: {BRANCH} vs {BASE}. Do not modify files.

Highest risk: live users upgrading into a new schema / reconcile / backup path.

Read specs/SwiftData.md, SchemaV* migrations, ActiveMatchStore / MatchRepository, demo-data cleanup, and related tests.

Evaluate:
- Lightweight vs custom migration; wipe-on-open-failure
- In-memory tests vs on-disk upgrade
- Reconcile treating fetch failure as empty
- Orphan FKs, demo vs real rows, backup round-trip after edits

Return:
1. Verdict: Ready / Ready with nits / Block {VERSION}
2. Table: Severity | Location (file:line) | Finding | User impact
3. Migration test gaps that could hide data loss
4. What looks correct
```
