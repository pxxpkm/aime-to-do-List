import 'package:flutter/material.dart';

/// Paper-gallery design tokens (warm light default).
class AppColors {
  // Paper base
  static const Color paperBg = Color(0xFFF6F1E8);
  static const Color paperSurface = Color(0xFFFFFBF5);
  static const Color paperElevated = Color(0xFFFFFFFF);
  static const Color inkPrimary = Color(0xFF1F1A12);
  static const Color inkSecondary = Color(0xFF5A4E40);
  static const Color inkMuted = Color(0xFF7A6E5E);
  static const Color divider = Color(0xFFE8DFD0);
  static const Color borderSubtle = Color(0xFFE0D5C4);

  // Compatibility aliases (legacy dark names → paper semantics)
  static const Color backgroundStart = paperBg;
  static const Color backgroundEnd = Color(0xFFEFE6D8);
  static const Color surface = paperSurface;
  static const Color textPrimary = inkPrimary;
  static const Color textSecondary = inkSecondary;
  static const Color textMuted = inkMuted;

  // Category accents (soft, non-neon)
  static const Color anime = Color(0xFFD6455D);
  static const Color manga = Color(0xFF2A9BB5);
  static const Color lightNovel = Color(0xFFD4920A);
  static const Color game = Color(0xFF7B5EA7);

  // Semantic
  static const Color success = Color(0xFF3D9B6E);
  static const Color warning = Color(0xFFD4A017);
  static const Color danger = Color(0xFFC94C4C);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundStart, backgroundEnd],
  );

  static Color getTypeColor(String type) {
    switch (type) {
      case 'anime':
        return anime;
      case 'manga':
        return manga;
      case 'light_novel':
        return lightNovel;
      case 'game':
        return game;
      default:
        return textSecondary;
    }
  }
}
