#!/usr/bin/env python3
"""Generate documentation coverage summary (documented vs gaps)."""

from __future__ import annotations

import glob
import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SPECS_DIR = REPO_ROOT / "specs"
CODE_SEARCH_DIRS = (
    "App",
    "Domain",
    "Data",
    "Persistence",
    "Features",
    "Intents",
    "Support",
    "DesignSystem",
)
CATALOG_ID_RE = re.compile(r"`((?:standard|party|coop|practice)\.[a-zA-Z0-9]+)`")
MODES_CATALOG_KEY_RE = re.compile(
    r"modes\.catalog\.((?:standard|party|coop|practice)\.[a-zA-Z0-9]+)\."
)
TABLE_RULE_RE = re.compile(r"^\|[-: |]+\|\s*$")
VERIFIED_DATE_RE = re.compile(
    r"\*\*Last verified\*\*\s*\|\s*(\d{4}-\d{2}-\d{2})",
    re.IGNORECASE,
)
SPEC_LINK_RE = re.compile(r"`([^`]+\.md)`")


@dataclass
class ChecklistRow:
    area: str
    spec_refs: list[str]
    code_tokens: list[str]
    spec_exists: bool
    code_ok: bool
    verified: str | None
    missing_specs: list[str]
    missing_code: list[str]


@dataclass
class ModeRow:
    catalog_id: str
    name: str
    status: str
    spec_path: str | None


def git_short_head() -> str:
    try:
        return (
            subprocess.check_output(
                ["git", "rev-parse", "--short", "HEAD"],
                cwd=REPO_ROOT,
                stderr=subprocess.DEVNULL,
                text=True,
            )
            .strip()
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "unknown"


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def spec_path(ref: str) -> Path:
    ref = ref.strip().strip("`")
    if ref.startswith("specs/"):
        return REPO_ROOT / ref
    candidates = [
        SPECS_DIR / ref,
        SPECS_DIR / "game-modes" / "implemented" / ref,
        SPECS_DIR / "game-modes" / "planned" / ref,
    ]
    for candidate in candidates:
        if candidate.is_file():
            return candidate
    return candidates[0]


def normalize_code_token(token: str) -> str:
    cleaned = re.sub(r"\([^)]*\)", "", token).strip().strip("`").strip()
    if "*" not in cleaned and cleaned.endswith(".swift"):
        return cleaned.removesuffix(".swift")
    return cleaned


def swift_symbol_exists(symbol: str) -> bool:
    pattern = re.compile(rf"\b(?:enum|struct|class|actor)\s+{re.escape(symbol)}\b")
    for root_name in CODE_SEARCH_DIRS:
        root = REPO_ROOT / root_name
        if not root.is_dir():
            continue
        for path in root.rglob("*.swift"):
            try:
                if pattern.search(path.read_text(encoding="utf-8", errors="replace")):
                    return True
            except OSError:
                continue
    return False


def parse_verified(spec_file: Path) -> str | None:
    if not spec_file.is_file():
        return None
    match = VERIFIED_DATE_RE.search(read_text(spec_file))
    return match.group(1) if match else None


def is_stale_verification(verified: str | None, max_age_days: int = 90) -> bool:
    if not verified:
        return False
    try:
        verified_date = datetime.strptime(verified, "%Y-%m-%d").date()
    except ValueError:
        return False
    return verified_date < date.today() - timedelta(days=max_age_days)


def swift_files_matching(pattern: str) -> list[Path]:
    matches: list[Path] = []
    for root_name in CODE_SEARCH_DIRS:
        root = REPO_ROOT / root_name
        if not root.is_dir():
            continue
        for path in root.rglob(pattern):
            if path.suffix == ".swift":
                matches.append(path)
    return matches


def resolve_code_token(token: str) -> tuple[bool, str]:
    raw = normalize_code_token(token)
    lowered = raw.lower()

    if not raw or lowered in {"shared gameplay chrome", "setup chip extensions"}:
        return True, "n/a (directory/convention)"

    if lowered == "repositories":
        hits = swift_files_matching("*Repository*.swift")
        return bool(hits), f"{len(hits)} repository file(s)"

    if lowered == "aggregates":
        hits = swift_files_matching("StatsService.swift")
        return bool(hits), "StatsService.swift" if hits else "missing"

    if lowered == "detail screen":
        hits = swift_files_matching("MatchHistoryDetailScreen.swift")
        return bool(hits), "MatchHistoryDetailScreen.swift" if hits else "missing"

    if lowered == "party engines":
        engines = ["BaseballEngine.swift", "KillerEngine.swift", "ShanghaiEngine.swift"]
        missing = [name for name in engines if not swift_files_matching(name)]
        return not missing, "ok" if not missing else f"missing {', '.join(missing)}"

    if lowered == "player detail":
        hits = swift_files_matching("PlayerDetailView.swift")
        return bool(hits), "PlayerDetailView.swift" if hits else "missing"

    if lowered == "playereditsheet":
        hits = swift_files_matching("PlayerEditSheet.swift")
        return bool(hits), "PlayerEditSheet.swift" if hits else "missing"

    if lowered == "raidengine":
        hits = swift_files_matching("RaidEngine.swift")
        return bool(hits), "RaidEngine.swift" if hits else "missing"

    if lowered == "playerachievementgallerysection":
        if swift_symbol_exists("PlayerAchievementGallerySection"):
            return True, "BadgeMedal.swift (symbol)"
        return False, "missing"

    if lowered == "defaultachievementservice":
        hits = swift_files_matching("AchievementService.swift")
        return bool(hits), "AchievementService.swift" if hits else "missing"

    if raw.endswith("/"):
        rel = raw.rstrip("/")
        path = REPO_ROOT / rel
        return path.is_dir(), str(rel)

    if "*" in raw:
        hits: list[Path] = []
        for root_name in CODE_SEARCH_DIRS:
            root = REPO_ROOT / root_name
            if root.is_dir():
                hits.extend(Path(p) for p in glob.glob(str(root / "**" / raw), recursive=True))
        return bool(hits), f"{len(hits)} match(es)" if hits else "missing"

    hits = swift_files_matching(f"*{raw}*.swift")
    if hits:
        rel = hits[0].relative_to(REPO_ROOT)
        return True, str(rel)
    if swift_symbol_exists(raw):
        return True, f"symbol {raw}"
    return False, "missing"


def section_until_next_heading(text: str, heading: str) -> str:
    body = text.split(heading, 1)[-1]
    match = re.search(r"\n## \d+\.", body)
    return body[: match.start()] if match else body


def parse_checklist_rows() -> list[ChecklistRow]:
    governance = read_text(SPECS_DIR / "SpecGovernance.md")
    section = section_until_next_heading(
        governance, "## 5. Feature spec coverage checklist"
    )
    rows: list[ChecklistRow] = []
    seen_areas: set[str] = set()

    for line in section.splitlines():
        if (
            not line.startswith("|")
            or "Feature area" in line
            or TABLE_RULE_RE.match(line)
        ):
            continue
        cells = [cell.strip() for cell in line.strip("|").split("|")]
        if len(cells) < 3:
            continue
        area, spec_cell, code_cell = cells[0], cells[1], cells[2]
        if area in {"Field", "N. Verification"}:
            continue
        if area in seen_areas:
            continue
        seen_areas.add(area)

        if area == "Planned modes (12)":
            planned_catalog = [e for e in parse_catalog_entries() if e[2] == "planned"]
            planned_count = len(planned_catalog)
            rows.append(
                ChecklistRow(
                    area=area,
                    spec_refs=["specs/game-modes/planned/"],
                    code_tokens=["GameModeCatalog"],
                    spec_exists=planned_count == 12,
                    code_ok=bool(swift_files_matching("GameModeCatalog.swift")),
                    verified=None,
                    missing_specs=[] if planned_count == 12 else [f"expected 12 planned catalog modes, found {planned_count}"],
                    missing_code=[] if swift_files_matching("GameModeCatalog.swift") else ["GameModeCatalog.swift"],
                )
            )
            continue

        spec_refs = SPEC_LINK_RE.findall(spec_cell)
        if not spec_refs:
            spec_refs = [spec_cell.strip("`")]

        missing_specs = [ref for ref in spec_refs if not spec_path(ref).is_file()]
        spec_exists = not missing_specs

        code_tokens = [part.strip() for part in code_cell.split(",") if part.strip()]
        missing_code: list[str] = []
        for token in code_tokens:
            ok, detail = resolve_code_token(token)
            if not ok:
                missing_code.append(f"{token} ({detail})")

        primary_spec = spec_path(spec_refs[0]) if spec_refs else None
        verified = parse_verified(primary_spec) if primary_spec else None

        rows.append(
            ChecklistRow(
                area=area,
                spec_refs=spec_refs,
                code_tokens=code_tokens,
                spec_exists=spec_exists,
                code_ok=not missing_code,
                verified=verified,
                missing_specs=missing_specs,
                missing_code=missing_code,
            )
        )

    return rows


def parse_catalog_entries() -> list[tuple[str, str, str]]:
    catalog_swift = REPO_ROOT / "Features" / "Modes" / "GameModeCatalog.swift"
    text = read_text(catalog_swift)
    entries: list[tuple[str, str, str]] = []
    for block in re.finditer(r"GameModeCatalogEntry\((.*?)\n\s*\)", text, re.DOTALL):
        chunk = block.group(1)
        id_match = re.search(r'id:\s*"([^"]+)"', chunk)
        name_match = re.search(r'name:\s*"([^"]+)"', chunk)
        status_match = re.search(r"status:\s*\.(shipped|planned)", chunk)
        if id_match and name_match and status_match:
            entries.append((id_match.group(1), name_match.group(1), status_match.group(1)))
    return entries


def catalog_id_from_spec(path: Path) -> str | None:
    text = read_text(path)
    for line in text.splitlines()[:30]:
        if "Status:" in line or "Catalog id" in line:
            match = CATALOG_ID_RE.search(line)
            if match:
                return match.group(1)
    for match in CATALOG_ID_RE.finditer(text):
        if match.group(1).startswith(("standard.", "party.", "coop.", "practice.")):
            return match.group(1)
    key_match = MODES_CATALOG_KEY_RE.search(text)
    if key_match:
        return key_match.group(1)
    return None


def build_mode_spec_index() -> dict[str, str]:
    index: dict[str, str] = {}
    for folder in ("implemented", "planned"):
        spec_dir = SPECS_DIR / "game-modes" / folder
        if not spec_dir.is_dir():
            continue
        for path in sorted(spec_dir.glob("*.md")):
            if path.name.endswith("DeferredWorkPlan.md"):
                continue
            catalog_id = catalog_id_from_spec(path)
            if catalog_id:
                index[catalog_id] = str(path.relative_to(REPO_ROOT))
    return index


def resolve_markdown_href(href: str) -> Path:
    if href.startswith("../"):
        return (SPECS_DIR / href).resolve()
    return (SPECS_DIR / href).resolve()


def parse_readme_spec_links() -> list[tuple[str, str]]:
    readme = read_text(SPECS_DIR / "README.md")
    links: list[tuple[str, str]] = []
    seen: set[str] = set()
    for match in re.finditer(r"\[`([^`]+)`\]\(([^)]+\.md)\)", readme):
        label, href = match.group(1), match.group(2)
        if href.startswith("http"):
            continue
        resolved = resolve_markdown_href(href)
        try:
            rel = str(resolved.relative_to(REPO_ROOT))
        except ValueError:
            rel = href
        if rel in seen:
            continue
        seen.add(rel)
        links.append((label, rel))
    return links


def parse_system_specs() -> list[tuple[str, bool]]:
    readme = read_text(SPECS_DIR / "README.md")
    block = readme.split("## Product and System Specs", 1)[-1].split("## Feature Specs", 1)[0]
    results: list[tuple[str, bool]] = []
    for line in block.splitlines():
        line = line.strip()
        if not line.startswith("- `specs/"):
            continue
        name = line.removeprefix("- `").removesuffix("`")
        path = REPO_ROOT / name
        results.append((name, path.is_file()))
    return results


def parse_ui_screen_specs() -> list[tuple[str, list[str], bool]]:
    ui_impl = read_text(SPECS_DIR / "UIImplementationSpec.md")
    section = section_until_next_heading(ui_impl, "## 3. Screen Contract Index")
    rows: list[tuple[str, list[str], bool]] = []
    for line in section.splitlines():
        if (
            not line.startswith("|")
            or "Screen / flow" in line
            or TABLE_RULE_RE.match(line)
        ):
            continue
        cells = [cell.strip() for cell in line.strip("|").split("|")]
        if len(cells) < 2:
            continue
        screen = cells[0]
        spec_hrefs = re.findall(r"\]\(([^)]+\.md)\)", cells[1])
        spec_paths = []
        missing = False
        for href in spec_hrefs:
            path = resolve_markdown_href(href)
            try:
                rel = str(path.relative_to(REPO_ROOT))
            except ValueError:
                rel = href
            spec_paths.append(rel)
            if not path.is_file():
                missing = True
        if spec_paths:
            rows.append((screen, spec_paths, not missing))
    return rows


def parse_wcag_screens() -> list[tuple[str, bool]]:
    screen_dir = REPO_ROOT / "accessibility" / "wcag-2.1-aa" / "screens"
    rows: list[tuple[str, bool]] = []
    if not screen_dir.is_dir():
        return rows
    for path in sorted(screen_dir.glob("*.md")):
        if path.name.startswith("_"):
            continue
        rows.append((path.stem, path.is_file()))
    return rows


def fmt_bool(ok: bool) -> str:
    return "yes" if ok else "NO"


def pct(numerator: int, denominator: int) -> str:
    if denominator == 0:
        return "n/a"
    return f"{(numerator / denominator) * 100:.1f}%"


def main() -> int:
    generated_at = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
    commit = git_short_head()
    lines: list[str] = [
        "Documentation coverage summary",
        f"Generated: {generated_at}",
        f"Commit: {commit}",
        "",
    ]

    checklist = parse_checklist_rows()
    checklist_documented = sum(1 for row in checklist if row.spec_exists and row.code_ok)
    lines.append("=== Feature checklist (SpecGovernance §5) ===")
    lines.append(
        f"{'Area':<28} {'Spec':<4} {'Code':<4} {'Verified':<12} Notes"
    )
    lines.append("-" * 90)
    for row in checklist:
        notes: list[str] = []
        if row.missing_specs:
            notes.append("missing spec: " + ", ".join(row.missing_specs))
        if row.missing_code:
            notes.append("missing code: " + "; ".join(row.missing_code))
        if row.verified is None and row.spec_exists:
            notes.append("no Verification date")
        elif is_stale_verification(row.verified):
            notes.append(f"stale Verification (>{90}d)")
        lines.append(
            f"{row.area:<28} {fmt_bool(row.spec_exists):<4} {fmt_bool(row.code_ok):<4} "
            f"{(row.verified or '-'):<12} {'; '.join(notes)}"
        )
    lines.append("")
    lines.append(
        f"CHECKLIST TOTAL: {checklist_documented}/{len(checklist)} areas documented "
        f"({pct(checklist_documented, len(checklist))})"
    )
    lines.append("")

    mode_spec_index = build_mode_spec_index()
    mode_rows: list[ModeRow] = []
    for catalog_id, name, status in parse_catalog_entries():
        mode_rows.append(
            ModeRow(
                catalog_id=catalog_id,
                name=name,
                status=status,
                spec_path=mode_spec_index.get(catalog_id),
            )
        )

    shipped = [row for row in mode_rows if row.status == "shipped"]
    planned = [row for row in mode_rows if row.status == "planned"]
    shipped_documented = sum(1 for row in shipped if row.spec_path)
    planned_documented = sum(1 for row in planned if row.spec_path)

    lines.append("=== Game modes (GameModeCatalog) ===")
    lines.append(
        f"{'ID':<32} {'Status':<8} {'Spec':<4} Spec path"
    )
    lines.append("-" * 90)
    for row in mode_rows:
        lines.append(
            f"{row.catalog_id:<32} {row.status:<8} {fmt_bool(bool(row.spec_path)):<4} "
            f"{row.spec_path or 'MISSING'}"
        )
    lines.append("")
    lines.append(
        f"SHIPPED MODES: {shipped_documented}/{len(shipped)} documented "
        f"({pct(shipped_documented, len(shipped))})"
    )
    lines.append(
        f"PLANNED MODES: {planned_documented}/{len(planned)} documented "
        f"({pct(planned_documented, len(planned))})"
    )
    orphan_specs = sorted(set(mode_spec_index.values()) - {row.spec_path for row in mode_rows if row.spec_path})
    r_and_d_orphans = [
        path for path in orphan_specs
        if "/planned/" in path
        and not any(
            token in Path(path).stem.lower()
            for token in ("bobs27", "halveit", "blindkiller", "followtheleader", "loop", "prisoner", "scam", "snooker", "tictactoe", "cerberus", "thevault", "cleartheboard")
        )
    ]
    if r_and_d_orphans:
        lines.append("R&D game-mode specs (no catalog id; informational): " + ", ".join(r_and_d_orphans))
    lines.append("")

    system_specs = parse_system_specs()
    system_ok = sum(1 for _, ok in system_specs if ok)
    lines.append("=== System specs (specs/README.md) ===")
    for name, ok in system_specs:
        lines.append(f"{fmt_bool(ok):<4} {name}")
    lines.append("")
    lines.append(
        f"SYSTEM SPECS: {system_ok}/{len(system_specs)} present "
        f"({pct(system_ok, len(system_specs))})"
    )
    lines.append("")

    readme_links = parse_readme_spec_links()
    readme_ok = sum(1 for _, path in readme_links if (REPO_ROOT / path).is_file())
    lines.append("=== Feature spec index (specs/README.md links) ===")
    for label, path in readme_links:
        ok = (REPO_ROOT / path).is_file()
        lines.append(f"{fmt_bool(ok):<4} {label:<24} {path}")
    lines.append("")
    lines.append(
        f"INDEX LINKS: {readme_ok}/{len(readme_links)} resolve "
        f"({pct(readme_ok, len(readme_links))})"
    )

    checklist_spec_set = {
        str(spec_path(ref).relative_to(REPO_ROOT))
        for row in checklist
        for ref in row.spec_refs
        if spec_path(ref).is_file()
    }
    non_feature_index_prefixes = ("docs/", "specs/game-modes/README.md", "specs/SpecGovernance.md")
    index_only = [
        (label, path)
        for label, path in readme_links
        if path not in checklist_spec_set
        and (REPO_ROOT / path).is_file()
        and not path.endswith("BaseballModeDeferredWorkPlan.md")
        and not any(path.startswith(prefix) for prefix in non_feature_index_prefixes)
    ]
    if index_only:
        lines.append("")
        lines.append("Specs indexed in README but not listed in §5 checklist:")
        for label, path in index_only:
            lines.append(f"  - {label}: {path}")

    lines.append("")
    ui_rows = parse_ui_screen_specs()
    ui_ok = sum(1 for _, _, ok in ui_rows if ok)
    lines.append("=== UI screen index (UIImplementationSpec §3) ===")
    for screen, specs, ok in ui_rows:
        lines.append(f"{fmt_bool(ok):<4} {screen:<30} -> {', '.join(specs)}")
    lines.append("")
    lines.append(
        f"UI SCREEN INDEX: {ui_ok}/{len(ui_rows)} rows resolve "
        f"({pct(ui_ok, len(ui_rows))})"
    )
    lines.append("")

    wcag_rows = parse_wcag_screens()
    lines.append("=== Accessibility screen trackers (wcag-2.1-aa/screens) ===")
    lines.append(f"Tracker files: {len(wcag_rows)}")
    for stem, ok in wcag_rows:
        lines.append(f"{fmt_bool(ok):<4} {stem}")
    lines.append("")

    total_items = (
        len(checklist)
        + len(mode_rows)
        + len(system_specs)
        + len(readme_links)
        + len(ui_rows)
    )
    total_documented = (
        checklist_documented
        + shipped_documented
        + planned_documented
        + system_ok
        + readme_ok
        + ui_ok
    )
    lines.append(
        f"TOTAL: {total_documented}/{total_items} tracked items documented "
        f"({pct(total_documented, total_items)})"
    )

    sys.stdout.write("\n".join(lines) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
