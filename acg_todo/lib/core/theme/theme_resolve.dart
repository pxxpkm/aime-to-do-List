import 'package:flutter/material.dart';

import 'package:acg_todo/core/theme/app_palette.dart';

/// Resolve active palette from user prefs + optional OS brightness.
///
/// Defaults (safe for existing site):
/// - unknown / empty [themeId] → [AppPalette.paperLight]
/// - [followSystem] false → fixed [themeId]
/// - [followSystem] true → OS dark → paper_dark, else paper_light
///   (special future themes are ignored while follow-system is on)
AppPalette resolvePalette({
  required String? themeId,
  required bool followSystem,
  required Brightness platformBrightness,
}) {
  if (followSystem) {
    return platformBrightness == Brightness.dark
        ? AppPalette.paperDark
        : AppPalette.paperLight;
  }
  return AppPalette.byId(themeId);
}
