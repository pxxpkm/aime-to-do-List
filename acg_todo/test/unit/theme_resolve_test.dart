import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/core/theme/app_palette.dart';
import 'package:acg_todo/core/theme/theme_resolve.dart';

void main() {
  group('resolvePalette', () {
    test('defaults to paper_light for null/unknown id', () {
      expect(
        resolvePalette(
          themeId: null,
          followSystem: false,
          platformBrightness: Brightness.dark,
        ).id,
        AppPalette.paperLightId,
      );
      expect(
        resolvePalette(
          themeId: 'nope',
          followSystem: false,
          platformBrightness: Brightness.light,
        ).id,
        AppPalette.paperLightId,
      );
    });

    test('manual dark id', () {
      final p = resolvePalette(
        themeId: AppPalette.paperDarkId,
        followSystem: false,
        platformBrightness: Brightness.light,
      );
      expect(p.id, AppPalette.paperDarkId);
      expect(p.brightness, Brightness.dark);
    });

    test('follow system overrides theme id', () {
      expect(
        resolvePalette(
          themeId: AppPalette.paperDarkId,
          followSystem: true,
          platformBrightness: Brightness.light,
        ).id,
        AppPalette.paperLightId,
      );
      expect(
        resolvePalette(
          themeId: AppPalette.paperLightId,
          followSystem: true,
          platformBrightness: Brightness.dark,
        ).id,
        AppPalette.paperDarkId,
      );
    });
  });

  group('AppPalette.paperLight freeze', () {
    test('matches legacy paper hex values', () {
      // Guard against accidental redesign of the live light site.
      expect(AppPalette.paperLight.bg, const Color(0xFFF6F1E8));
      expect(AppPalette.paperLight.surface, const Color(0xFFFFFBF5));
      expect(AppPalette.paperLight.elevated, const Color(0xFFFFFFFF));
      expect(AppPalette.paperLight.ink, const Color(0xFF1F1A12));
      expect(AppPalette.paperLight.anime, const Color(0xFFD6455D));
    });
  });
}
