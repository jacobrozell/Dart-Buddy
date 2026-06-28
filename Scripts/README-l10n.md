# Localization scripts

Use **`python3 Scripts/l10n.py`** for all locale tooling. Policy and conventions live in [`specs/LocalizationSpec.md`](../specs/LocalizationSpec.md). **`localizable_strings.py`** is the shared `.strings` parser (do not run directly).

**Shipped locales:** `de`, `es`, `nl`, `fr`, `zh-Hans`, `it` (plus English baseline in `en.lproj`).

---

## File layout

| What | English (key order source) | Shipped translations | JSON source of truth |
|------|---------------------------|----------------------|----------------------|
| App UI, errors, settings, rules | `Resources/en.lproj/Localizable.strings` | `Resources/{locale}.lproj/Localizable.strings` | `Scripts/locale_data/{locale}.json` |
| Game mode UI (play screens, setup) | `Resources/en.lproj/GameplayModes.strings` | `Resources/{locale}.lproj/GameplayModes.strings` | `Scripts/locale_data/{locale}_gameplay_modes.json` |

Other paths:

| Path | Purpose |
|------|---------|
| `Scripts/locale_data/patches/gap_patch.json` | Idempotent backfill for known key gaps (mode errors, validation strings) |
| `Scripts/locale_data/patches/gameplay_quality.json` | Targeted GameplayModes translation fixes |
| `Scripts/locale_data/patches/localizable_quality.json` | Targeted Localizable translation fixes |
| `Scripts/locale_data/*_backfill.json` | Historical translation shards; merge with `merge-backfill` |
| `Scripts/locale_neutral_keys.json` | Keys **allowed** to stay identical to English (brands, X01 notation, etc.); used by `audit` |

**Rule:** English `.strings` files define **which keys exist** and their **order**. Shipped locales are generated from JSON to match that order.

---

## Add a new key (checklist)

### Localizable key (most UI)

1. Add the key and English value to `Resources/en.lproj/Localizable.strings`.
2. Add translations to each shipped locale JSON:
   - `Scripts/locale_data/de.json`
   - `Scripts/locale_data/es.json`
   - `Scripts/locale_data/nl.json`
   - `Scripts/locale_data/fr.json`
   - `Scripts/locale_data/zh-Hans.json`
   - `Scripts/locale_data/it.json`
3. Regenerate shipped `.strings`:
   ```bash
   python3 Scripts/l10n.py generate localizable all
   ```
4. Verify:
   ```bash
   python3 Scripts/l10n.py audit
   ```
   CI also runs `LocalizationParityTests` for key set and `%@` / `%d` specifier parity.

Use `L10n.string("your.key")` in Swift — never hard-code user-facing text in views.

### GameplayModes key (play / setup for a mode)

Same flow, but use `GameplayModes.strings` and `{locale}_gameplay_modes.json`:

1. Add key to `Resources/en.lproj/GameplayModes.strings`.
2. Update all six `Scripts/locale_data/{locale}_gameplay_modes.json` files.
3. `python3 Scripts/l10n.py generate gameplay all`
4. `python3 Scripts/l10n.py audit`

Gameplay mode strings resolve through `L10n.string()` against the `GameplayModes` table (same API as Localizable).

---

## Commands

| Command | Purpose |
|---------|---------|
| `python3 Scripts/l10n.py audit` | Key parity, format specifiers, English leakage report |
| `python3 Scripts/l10n.py export all` | Full `.strings` → JSON overwrite for every locale |
| `python3 Scripts/l10n.py sync-json all` | Add **missing** JSON keys only, from existing `.strings` |
| `python3 Scripts/l10n.py merge-backfill all` | Merge `*_backfill.json` shards into locale JSON |
| `python3 Scripts/l10n.py generate all` | JSON → all shipped `.strings` (Localizable + GameplayModes) |
| `python3 Scripts/l10n.py generate localizable de` | Regenerate one locale / one table |
| `python3 Scripts/l10n.py patch-gaps [--write]` | Apply `patches/gap_patch.json` to JSON (+ optional regenerate) |
| `python3 Scripts/l10n.py patch-quality [--write]` | Apply quality patch JSON (+ optional regenerate) |

Run `python3 Scripts/l10n.py --help` for subcommand details.

---

## Workflows

### Edit JSON (preferred)

Update `locale_data/{locale}.json` or `{locale}_gameplay_modes.json`, then:

```bash
python3 Scripts/l10n.py generate all
python3 Scripts/l10n.py audit
```

### Edited `.strings` directly (e.g. in Xcode)

**Option A — full sync (safe after bulk edits):**

```bash
python3 Scripts/l10n.py export all    # overwrite JSON from .strings
python3 Scripts/l10n.py generate all  # optional: normalize key order across locales
python3 Scripts/l10n.py audit
```

**Option B — fill gaps only (when JSON is mostly current):**

```bash
python3 Scripts/l10n.py sync-json all   # copy missing keys from .strings into JSON
python3 Scripts/l10n.py generate all
python3 Scripts/l10n.py audit
```

### `export` vs `sync-json`

| | `export` | `sync-json` |
|---|----------|-------------|
| Scope | Replaces entire JSON from `.strings` | Adds keys present in `.strings` but missing from JSON |
| Overwrites existing JSON values | Yes | No |
| Use when | You trust `.strings` as the latest copy | JSON is current but a few new keys landed in `.strings` |

`sync-json` applies to **Localizable** only (English key list is the gate). Use `export gameplay` to refresh GameplayModes JSON.

### Batch gap / quality fixes

Edit files under `locale_data/patches/`, then:

```bash
python3 Scripts/l10n.py patch-gaps --write
python3 Scripts/l10n.py patch-quality --write
python3 Scripts/l10n.py audit
```

Mode error keys for **English** are upserted into `en.lproj/GameplayModes.strings` directly (English is not generated from JSON).

---

## CI and manual QA

- **`LocalizationParityTests`** — identical key sets and format-specifier parity across all shipped locales.
- **`python3 Scripts/l10n.py audit`** — structural check plus English-leakage counts (see `locale_neutral_keys.json` for intentional matches).
- **Localized smoke UI tests** — launch with `-AppleLanguages (de|es|nl|fr|zh-Hans|it)`; listed in [`specs/LocalizationSpec.md`](../specs/LocalizationSpec.md) §8.

---

## Related docs

- [`specs/LocalizationSpec.md`](../specs/LocalizationSpec.md) — policy, key naming, waves, PR rules
- [`CONTRIBUTING.md`](../CONTRIBUTING.md) § Localization — contributor summary
