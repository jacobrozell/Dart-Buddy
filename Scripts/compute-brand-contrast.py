#!/usr/bin/env python3
"""Compute WCAG 2.1 contrast ratios for Brand palette pairs (evidence log)."""

from __future__ import annotations

import math
from dataclasses import dataclass
from datetime import date


@dataclass(frozen=True)
class RGB:
    r: float
    g: float
    b: float

    @classmethod
    def from_u8(cls, r: int, g: int, b: int, alpha: float = 1.0) -> "RGB":
        return cls(r / 255 * alpha, g / 255 * alpha, b / 255 * alpha)

    def blend_over(self, background: "RGB", alpha: float) -> "RGB":
        return RGB(
            self.r * alpha + background.r * (1 - alpha),
            self.g * alpha + background.g * (1 - alpha),
            self.b * alpha + background.b * (1 - alpha),
        )


def relative_luminance(rgb: RGB) -> float:
    def channel(c: float) -> float:
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = channel(rgb.r), channel(rgb.g), channel(rgb.b)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast_ratio(foreground: RGB, background: RGB) -> float:
    l1 = relative_luminance(foreground)
    l2 = relative_luminance(background)
    lighter, darker = (max(l1, l2), min(l1, l2))
    return (lighter + 0.05) / (darker + 0.05)


def pass_aa(ratio: float, large: bool = False) -> str:
    threshold = 3.0 if large else 4.5
    return "PASS" if ratio >= threshold else "FAIL"


# BrandTheme.swift (2026-06-02)
LIGHT = {
    "background": RGB.from_u8(242, 242, 247),
    "card": RGB.from_u8(255, 255, 255),
    "cardElevated": RGB.from_u8(235, 235, 239),
    "textPrimary": RGB.from_u8(20, 20, 26),
    "textSecondary": RGB.from_u8(89, 89, 97),  # 0.35 sRGB per BrandTheme
    "red": RGB.from_u8(230, 71, 61),
    "green": RGB.from_u8(51, 173, 82),
    "amber": RGB.from_u8(245, 179, 31),
}

DARK = {
    "background": RGB.from_u8(10, 10, 13),
    "card": RGB.from_u8(28, 28, 31),
    "cardElevated": RGB.from_u8(41, 41, 43),
    "textPrimary": RGB.from_u8(255, 255, 255),
    "red": RGB.from_u8(230, 71, 61),
    "green": RGB.from_u8(51, 173, 82),
    "amber": RGB.from_u8(245, 179, 31),
}


def samples_for_mode(name: str, palette: dict[str, RGB]) -> list[tuple[str, RGB, RGB, bool]]:
    bg, card = palette["background"], palette["card"]
    primary = palette["textPrimary"]
    if name == "light":
        secondary = palette["textSecondary"]
    else:
        white = RGB.from_u8(255, 255, 255)
        secondary_on_bg = white.blend_over(bg, 0.55)
        secondary_on_card = white.blend_over(card, 0.55)
    red, green, amber = palette["red"], palette["green"], palette["amber"]
    on_accent = RGB.from_u8(255, 255, 255)

    fill_light = 0.22 if name == "light" else 0.32
    bust_bg = red.blend_over(bg, fill_light)
    leg_bg = green.blend_over(bg, fill_light)
    error_bg = red.blend_over(bg, 0.88)

    secondary_rows = (
        [
            (f"{name}: textSecondary on background", secondary, bg, False),
            (f"{name}: textSecondary on card", secondary, card, False),
        ]
        if name == "light"
        else [
            (f"{name}: textSecondary on background", secondary_on_bg, bg, False),
            (f"{name}: textSecondary on card", secondary_on_card, card, False),
        ]
    )

    return [
        (f"{name}: textPrimary on background", primary, bg, False),
        (f"{name}: textPrimary on card", primary, card, False),
        *secondary_rows,
        (f"{name}: textOnAccent on red (CTA)", on_accent, red, False),
        (f"{name}: textOnAccent on error banner fill", on_accent, error_bg, False),
        (f"{name}: textPrimary on bust banner fill", primary, bust_bg, False),
        (f"{name}: textPrimary on leg-win banner fill", primary, leg_bg, False),
        (f"{name}: textPrimary on cardElevated (selected avatar)", primary, palette["cardElevated"], False),
    ]


def main() -> None:
    rows: list[str] = []
    rows.append(f"# Brand token contrast samples ({date.today().isoformat()})")
    rows.append("")
    rows.append("Computed from `DesignSystem/Tokens/BrandTheme.swift` + banner opacity rules in `MatchFeedbackBanner` / `ErrorBanner`.")
    rows.append("WCAG 2.1 AA: **4.5:1** normal text, **3:1** large text.")
    rows.append("")
    rows.append("| Pair | Ratio | Normal AA | Large AA |")
    rows.append("|------|-------|-----------|----------|")

    all_samples = samples_for_mode("light", LIGHT) + samples_for_mode("dark", DARK)
    failures: list[str] = []

    for label, fg, bg, large in all_samples:
        ratio = contrast_ratio(fg, bg)
        normal = pass_aa(ratio, large=False)
        large_result = pass_aa(ratio, large=True)
        rows.append(f"| {label} | {ratio:.2f}:1 | {normal} | {large_result} |")
        if normal == "FAIL":
            failures.append(label)

    rows.append("")
    if failures:
        rows.append("## Result")
        rows.append("")
        rows.append("**Review required** for pairs marked FAIL (normal text):")
        for item in failures:
            rows.append(f"- {item}")
    else:
        rows.append("## Result")
        rows.append("")
        rows.append("All logged primary-surface pairs meet **4.5:1** for normal text (or are decorative/large-only).")
        rows.append("")
        rows.append("Manual follow-up: verify in Accessibility Inspector on device/simulator screenshots in `evidence/orientation/`.")
    rows.append("")
    rows.append("Related: `DBX-CONTRAST-MODES`, `accessibility/dark-light-mode.md` P4.")

    out_path = (
        __file__.replace("Scripts/compute-brand-contrast.py", "")
        + "accessibility/wcag-2.1-aa/evidence/contrast/brand-token-samples-2026-06-02.md"
    )
    import os

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out_path = os.path.join(root, "accessibility/wcag-2.1-aa/evidence/contrast/brand-token-samples-2026-06-02.md")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(rows) + "\n")
    print(out_path)
    for line in rows:
        if line.startswith("|") and "FAIL" in line:
            print(line)


if __name__ == "__main__":
    main()
