#!/usr/bin/env python3
"""Bulk-migrate AppColors surface tokens to context.palette (T2)."""
from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1] / "lib"

SKIP = {
    "core/theme/app_colors.dart",
    "core/theme/app_palette.dart",
    "core/theme/app_theme.dart",
    "core/theme/theme_resolve.dart",
    "core/theme/app_typography.dart",
    "domain/entities/item_category.dart",
}

PAIRS = [
    ("AppColors.paperBg", "context.palette.bg"),
    ("AppColors.paperSurface", "context.palette.surface"),
    ("AppColors.paperElevated", "context.palette.elevated"),
    ("AppColors.inkPrimary", "context.palette.ink"),
    ("AppColors.inkSecondary", "context.palette.inkSecondary"),
    ("AppColors.inkMuted", "context.palette.inkMuted"),
    ("AppColors.divider", "context.palette.divider"),
    ("AppColors.borderSubtle", "context.palette.border"),
    ("AppColors.backgroundStart", "context.palette.bg"),
    ("AppColors.backgroundEnd", "context.palette.gradientEnd"),
    ("AppColors.backgroundGradient", "context.palette.backgroundGradient"),
    ("AppColors.surface", "context.palette.surface"),
    ("AppColors.textPrimary", "context.palette.ink"),
    ("AppColors.textSecondary", "context.palette.inkSecondary"),
    ("AppColors.textMuted", "context.palette.inkMuted"),
    ("AppColors.anime", "context.palette.anime"),
    ("AppColors.manga", "context.palette.manga"),
    ("AppColors.lightNovel", "context.palette.lightNovel"),
    ("AppColors.game", "context.palette.game"),
    ("AppColors.success", "context.palette.success"),
    ("AppColors.warning", "context.palette.warning"),
    ("AppColors.danger", "context.palette.danger"),
]

IMPORT_LINE = "import 'package:acg_todo/core/theme/app_palette.dart';\n"


def main() -> None:
    for path in sorted(ROOT.rglob("*.dart")):
        rel = path.relative_to(ROOT).as_posix()
        if rel in SKIP:
            continue
        text = path.read_text(encoding="utf-8")
        if not any(a in text for a, _ in PAIRS) and "AppColors.getTypeColor" not in text:
            continue
        original = text
        for a, b in PAIRS:
            text = text.replace(a, b)
        text = re.sub(
            r"AppColors\.getTypeColor\(([^)]+)\)",
            r"context.palette.typeColor(\1)",
            text,
        )
        if "context.palette." in text and "app_palette.dart" not in text:
            if "package:acg_todo/core/theme/app_colors.dart" in text:
                text = text.replace(
                    "import 'package:acg_todo/core/theme/app_colors.dart';\n",
                    "import 'package:acg_todo/core/theme/app_colors.dart';\n" + IMPORT_LINE,
                )
            elif "package:flutter/material.dart" in text:
                text = text.replace(
                    "import 'package:flutter/material.dart';\n",
                    "import 'package:flutter/material.dart';\n" + IMPORT_LINE,
                    1,
                )
            else:
                text = IMPORT_LINE + text
        # Remove `const` only on lines that reference context.palette
        fixed_lines = []
        for line in text.splitlines(keepends=True):
            if "context.palette" in line and "const " in line:
                line = line.replace("const ", "", 1)
            fixed_lines.append(line)
        text = "".join(fixed_lines)
        if text != original:
            path.write_text(text, encoding="utf-8")
            print("updated", rel)


if __name__ == "__main__":
    main()
