# Delete All Local Data Specification

## 1. Purpose

Define what **Reset All Local Data** must wipe, how new persistence surfaces register for reset as the app scales, and how automated tests prevent inventory drift.

**Related specs:** Settings entry point — [`SettingsSpec.md`](SettingsSpec.md). SwiftData models — [`SwiftData.md`](SwiftData.md), [`DataSchemaSpec.md`](DataSchemaSpec.md). Bootstrap store recovery — [`SwiftData.md`](SwiftData.md) §9. Privacy — [`SecurityPrivacySpec.md`](SecurityPrivacySpec.md) §3.

---

## 2. MVP Scope (1.0.0)

### In scope
- Settings → **Reset All Local Data** (destructive, confirmed)
- Canonical inventory of every cleared surface
- Regression tests that fail when inventory and schema diverge

### Out of scope
- Selective delete (single player, single match)
- Cloud backup restore
- Export-before-reset (see `FutureIdeas/backlog.md`)

---

## 3. User-Facing Behavior

### 3.1 Settings path

1. User taps **Reset all data** in Settings → Data section (`settings_resetAllDataButton`).
2. Confirmation alert: title **Reset all local data?**; actions **Cancel** and **Reset Data** (destructive).
3. Alert copy must state that players, matches, settings, and (when shipped) Journey progress and achievements are removed.
4. On confirm:
   - Show in-progress state; block duplicate taps.
   - Execute reset sequence (§5).
   - Reload settings into UI and in-memory preference mirrors.
   - Post `dartBuddy.localDataDidReset` notification.
5. On failure: show recoverable error (`settings.error.reset`); user may retry.
6. On cancel: dismiss alert; no data change.

Accessibility identifiers and VoiceOver contract: [`accessibility/wcag-2.1-aa/evidence/voiceover/core-flow-settings-reset.md`](../accessibility/wcag-2.1-aa/evidence/voiceover/core-flow-settings-reset.md).

### 3.2 Expected post-reset state

Same as a fresh install after onboarding skip (data-wise):

- No players, matches, history, or in-progress session
- One default `SettingsRecord` (factory defaults — see [`SettingsSpec.md`](SettingsSpec.md) §4)
- Onboarding flags cleared (onboarding may show again on next cold start per launch rules)
- Last-used match-setup chip values restored to mode defaults
- Play tab empty; Statistics and History empty

Manual smoke: [`SmokeTestChecklist.md`](SmokeTestChecklist.md) **Pre-Run Reset**.

---

## 4. Reset Entry Points

| Entry | Trigger | SwiftData | UserDefaults | In-memory |
|-------|---------|-----------|--------------|-----------|
| **Settings** | `SettingsViewModel.confirmReset()` | Row delete via `LocalDataResetInventory` + fresh `SettingsRecord` | `LocalAppStateReset.clearAllPersistedAuxiliaryState()` | `ActiveMatchStore`, `PendingMatchPlayerSelections` |
| **Bootstrap recovery** | `BootstrapStoreRecovery` store recreation | `AppStoreReset.deleteSQLiteStore()` (file delete) | Same UserDefaults clear on next Settings reset | Fresh bootstrap (new dependency graph) |
| **UI tests / demo** | `-ui_test_reset` launch arg | SQLite file delete before container creation | Same UserDefaults clear | N/A (new process) |

All user-visible wipe paths must converge on the inventory in §6. Bootstrap store recreation may skip row-by-row delete because the store file is removed; outcome must match Settings reset when the user later resets from Settings.

---

## 5. Execution Sequence (Settings)

Order is fixed — do not reorder without updating tests:

```
SettingsViewModel.confirmReset()
  1. SettingsRepository.resetAllLocalData()     // SwiftData — §6.1
  2. ActiveMatchStore.clearAll()                // §6.3
  3. PendingMatchPlayerSelections.clearAll()    // §6.3
  4. LocalAppStateReset.clearAllPersistedAuxiliaryState()  // §6.2
  5. LocalAppStateReset.notifyDidReset()
  6. fetchSettings() + UserPreferencesStore.apply()
```

SwiftData reset must be transactional within the repository call: delete all inventoried models, insert one default `SettingsRecord`, save once.

---

## 6. Canonical Inventory (1.0.0)

**Source of truth in code:** `Support/State/LocalDataResetInventory.swift`

Agents and contributors must update this file when adding persistence. Tests enforce alignment (§8).

### 6.1 SwiftData (`SchemaV2`)

| Model | Cleared | Post-reset |
|-------|---------|------------|
| `PlayerRecord` | All rows deleted | Empty |
| `MatchRecord` | All rows deleted | Empty |
| `MatchParticipantRecord` | All rows deleted | Empty |
| `MatchSnapshotRecord` | All rows deleted | Empty |
| `MatchEventRecord` | All rows deleted | Empty |
| `SettingsRecord` | All rows deleted | Exactly **one** new default row |

Stats and aggregates have no separate tables; they derive from events and matches above.

**When adding a `@Model`:** add to `SchemaVx.models` **and** `LocalDataResetInventory.swiftDataDeleters` / `swiftDataCounters`. Counts must match `SchemaLock.release_1_0_0Schema.models` (test-guarded).

### 6.2 UserDefaults — setup preferences (per game mode)

Each implemented mode with last-used setup chips must conform to `PersistedSetupPreferences` and register in `LocalDataResetInventory.setupPreferenceStores`.

| Store | Keys (prefix) | 1.0.0 |
|-------|---------------|-------|
| `CricketSetupPreferences` | `cricketSetup.*` | ✓ |
| `BaseballSetupPreferences` | `baseballSetup.*` | ✓ |
| `ShanghaiSetupPreferences` | `shanghaiSetup.*` | ✓ |
| `KillerSetupPreferences` | `killer.setup.*` | ✓ |

**When shipping a new game mode** (promote `planned/` → `implemented/`): add `{Mode}SetupPreferences.swift` with `clearStored(userDefaults:)`, conform to `PersistedSetupPreferences`, register in `setupPreferenceStores`. See [`game-modes/README.md`](game-modes/README.md).

### 6.3 UserDefaults — auxiliary

Cleared via `LocalDataResetInventory.clearAuxiliaryUserDefaults`:

| Store | Purpose |
|-------|---------|
| `OnboardingStore` | Completion flag, experience selection |
| `AppStoreUpdateChecker` | Dismissed App Store version |

**When adding other `UserDefaults`:** add an explicit clear call here (not ad hoc in feature code).

### 6.4 In-memory (current session only)

Cleared in `SettingsViewModel.confirmReset()`; listed in `LocalDataResetInventory.inMemorySurfaces`:

| Store | Purpose |
|-------|---------|
| `ActiveMatchStore` | Live `MatchLifecycleSession` cache |
| `PendingMatchPlayerSelections` | Mode/player prefill queue |

**When adding session-scoped state** that survives tab switches but must not survive reset: wire into `confirmReset()` and append to `inMemorySurfaces`.

### 6.6 Post-1.0 gamification (when shipped)

Register in `LocalDataResetInventory` when SwiftData models land. **Reset all local data** must clear these tables/rows the same as players and matches.

| Model / surface | Spec | Cleared on reset all | Notes |
|-----------------|------|----------------------|-------|
| `PlayerAchievementRecord` | [`AchievementsSpec.md`](AchievementsSpec.md) | All rows | Per-player unlocks and incremental progress |
| `CampaignProgressRecord` | [`CampaignSpec.md`](CampaignSpec.md) | All rows | Stage stars, last played |
| `PlayerBadgeRecord` | [`CampaignSpec.md`](CampaignSpec.md) §9 | All rows | Campaign collectibles (Phase 2+) |
| `DailyChallengeCompletionRecord` | [`DailyChallengeSpec.md`](DailyChallengeSpec.md) | All rows | Per-day completion |
| `PlayerRecord` (full roster) | [`PlayerSpec.md`](PlayerSpec.md) | All rows deleted | Existing 1.0 behavior — reset all removes every player including primary and guests |
| `PlayerRecord.playerRoleRaw` | [`CampaignSpec.md`](CampaignSpec.md) §4 | Reset with players | Primary designation cleared with roster |
| Pending daily-challenge + play-reminder notifications | [`DailyChallengeSpec.md`](DailyChallengeSpec.md), [`FutureIdeas/play-reminders.md`](../FutureIdeas/play-reminders.md) | Cancel pending | Same `UNUserNotificationCenter` cleanup |

**Future — selective delete:** [`CampaignSpec.md`](CampaignSpec.md) Phase 3 may add **Delete Journey data only** (progress + campaign badges, not full roster). That path is **not** reset-all; document in Settings when implemented.

### 6.5 Explicitly not cleared

Document new exceptions here before implementing:

| Surface | Reason |
|---------|--------|
| Firebase / Crashlytics SDK internal state | Not user content; see [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) |
| Keychain | No user secrets in 1.0.0 |
| Feature-flag compile-time defaults | Not persisted user data |
| Pending local notifications | Cancel on reset when play-reminder / daily-challenge services ship (§6.6) |

---

## 7. Scaling Checklist

Use this on every PR that adds persistence or a shipped game mode:

- [ ] **SwiftData model added?** → `SchemaVx.models` + `LocalDataResetInventory.swiftDataDeleters` (+ counters)
- [ ] **Mode setup chips persisted?** → `{Mode}SetupPreferences` + `PersistedSetupPreferences` + `setupPreferenceStores`
- [ ] **Other UserDefaults?** → `clearAuxiliaryUserDefaults`
- [ ] **Session cache?** → `SettingsViewModel.confirmReset()` + `inMemorySurfaces`
- [ ] **Bootstrap recovery still valid?** → file delete path clears same UserDefaults when user resets from Settings
- [ ] **Tests updated?** → §8
- [ ] **Gamification model added?** → §6.6 + `LocalDataResetInventory`
- [ ] **This spec §6 inventory table updated** if the shipped surface list changed

---

## 8. Testing Requirements

All tests tagged `.regression` where noted in [`SwiftTestingTagsSpec.md`](SwiftTestingTagsSpec.md).

### 8.1 Inventory guards (unit)

| Test | File |
|------|------|
| `swiftDataInventoryMatchesReleaseSchema` | `Tests/Unit/LocalDataResetInventoryTests.swift` |
| `setupPreferenceInventoryListsEveryImplementedModeStore` | same |
| `clearAllPersistedAuxiliaryStateRemovesEveryRegisteredStore` | same |
| `clearAllPersistedAuxiliaryStateRemovesKnownKeys` | `Tests/Unit/LocalAppStateResetTests.swift` |

### 8.2 SwiftData integration

| Test | File |
|------|------|
| `settingsRepositoryResetAllLocalDataClearsEverySwiftDataTable` | `Tests/Unit/RepositoryContractTests.swift` |

Must seed players, match, participants, events, and snapshots; assert per-table counts before/after.

### 8.3 ViewModel integration

| Test | File |
|------|------|
| `settingsConfirmResetClearsActiveMatchStore` | `Tests/Unit/SettingsViewModelTests.swift` |

### 8.4 UI

| Test | File |
|------|------|
| Confirmation alert present; Cancel dismisses | `Tests/UI/SettingsUITests.swift` |
| Accessibility contract | same + WCAG UI tests |

**Future (recommended):** UI test that confirms reset with `-seed_players` and asserts empty Players/History.

---

## 9. Analytics

Log-only event on successful Settings reset: `settings_reset_all_data` ([`LoggingSpec.md`](LoggingSpec.md)). Must not log player names or match content.

---

## 10. Verification

| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-11 |
| **Commit** | (current branch — reset inventory + spec) |
| **Code** | `LocalDataResetInventory.swift`, `LocalAppStateReset.swift`, `SwiftDataSettingsRepository.swift`, `SettingsViewModel.swift`, `PersistedSetupPreferences.swift`, `SwiftDataStoreReset.swift` |

---

## 11. Future Improvements

- Export diagnostic bundle before reset
- Unified reset service callable from Settings and bootstrap recovery (single orchestrator)
- Cancel pending local notifications on reset ([`FutureIdeas/play-reminders.md`](../FutureIdeas/play-reminders.md))
- UI test: confirm reset → empty roster/history
