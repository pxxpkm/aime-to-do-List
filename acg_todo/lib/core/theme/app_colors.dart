import 'package:flutter/material.dart';

class AppColors {
  // Background gradient
  static const Color backgroundStart = Color(0xFF1a1a2e);
  static const Color backgroundEnd = Color(0xFF16213e);

  // Surface
  static const Color surface = Color(0xFF0f3460);

  // Category accents
  static const Color anime = Color(0xFFe94560);
  static const Color manga = Color(0xFF0fb5d4);
  static const Color lightNovel = Color(0xFFf5a623);
  static const Color game = Color(0xFF9b59b6);

  // Semantic
  static const Color success = Color(0xFF4ade80);
  static const Color warning = Color(0xFFfbbf24);
  static const Color danger = Color(0xFFef4444);

  // Text
  static const Color textPrimary = Color(0xFFf8f9fa);
  static const Color textSecondary = Color(0xFFadb5bd);
  static const Color textMuted = Color(0xFF6c757d);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
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
