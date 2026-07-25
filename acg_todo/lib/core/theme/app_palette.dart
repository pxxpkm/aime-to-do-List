import 'package:flutter/material.dart';

/// Semantic color tokens for one visual theme.
///
/// [paperLight] hex values are **frozen** to match legacy [AppColors] paper
/// light — do not change them when adding dark/other themes.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final String id;
  final String label;
  final Brightness brightness;

  final Color bg;
  final Color surface;
  final Color elevated;
  final Color ink;
  final Color inkSecondary;
  final Color inkMuted;
  final Color divider;
  final Color border;
  final Color gradientEnd;

  final Color anime;
  final Color manga;
  final Color lightNovel;
  final Color game;

  final Color success;
  final Color warning;
  final Color danger;

  const AppPalette({
    required this.id,
    required this.label,
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.elevated,
    required this.ink,
    required this.inkSecondary,
    required this.inkMuted,
    required this.divider,
    required this.border,
    required this.gradientEnd,
    required this.anime,
    required this.manga,
    required this.lightNovel,
    required this.game,
    required this.success,
    required this.warning,
    required this.danger,
  });

  LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [bg, gradientEnd],
      );

  Color typeColor(String type) {
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
        return inkSecondary;
    }
  }

  /// Frozen copy of today's paper light (legacy AppColors). **Do not edit hex.**
  static const paperLight = AppPalette(
    id: 'paper_light',
    label: '淺色紙感',
    brightness: Brightness.light,
    bg: Color(0xFFF6F1E8),
    surface: Color(0xFFFFFBF5),
    elevated: Color(0xFFFFFFFF),
    ink: Color(0xFF1F1A12),
    inkSecondary: Color(0xFF5A4E40),
    inkMuted: Color(0xFF7A6E5E),
    divider: Color(0xFFE8DFD0),
    border: Color(0xFFE0D5C4),
    gradientEnd: Color(0xFFEFE6D8),
    anime: Color(0xFFD6455D),
    manga: Color(0xFF2A9BB5),
    lightNovel: Color(0xFFD4920A),
    game: Color(0xFF7B5EA7),
    success: Color(0xFF3D9B6E),
    warning: Color(0xFFD4A017),
    danger: Color(0xFFC94C4C),
  );

  /// Warm dark gallery (opt-in; not pure OLED black).
  static const paperDark = AppPalette(
    id: 'paper_dark',
    label: '深色畫廊',
    brightness: Brightness.dark,
    bg: Color(0xFF12100E),
    surface: Color(0xFF1C1916),
    elevated: Color(0xFF26221E),
    ink: Color(0xFFF2EBE0),
    inkSecondary: Color(0xFFB8A99A),
    inkMuted: Color(0xFF8A7D70),
    divider: Color(0xFF2E2924),
    border: Color(0xFF3A342E),
    gradientEnd: Color(0xFF0C0B0A),
    anime: Color(0xFFE85A70),
    manga: Color(0xFF3BB5CF),
    lightNovel: Color(0xFFE0A82A),
    game: Color(0xFF9B7EC4),
    success: Color(0xFF4CB87F),
    warning: Color(0xFFE0B020),
    danger: Color(0xFFE05C5C),
  );

  /// Registry — add future themes here only.
  static const Map<String, AppPalette> registry = {
    paperLightId: paperLight,
    paperDarkId: paperDark,
  };

  static const paperLightId = 'paper_light';
  static const paperDarkId = 'paper_dark';
  static const defaultId = paperLightId;

  static AppPalette byId(String? id) {
    if (id == null || id.isEmpty) return paperLight;
    return registry[id] ?? paperLight;
  }

  @override
  AppPalette copyWith({
    String? id,
    String? label,
    Brightness? brightness,
    Color? bg,
    Color? surface,
    Color? elevated,
    Color? ink,
    Color? inkSecondary,
    Color? inkMuted,
    Color? divider,
    Color? border,
    Color? gradientEnd,
    Color? anime,
    Color? manga,
    Color? lightNovel,
    Color? game,
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return AppPalette(
      id: id ?? this.id,
      label: label ?? this.label,
      brightness: brightness ?? this.brightness,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      elevated: elevated ?? this.elevated,
      ink: ink ?? this.ink,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      inkMuted: inkMuted ?? this.inkMuted,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      anime: anime ?? this.anime,
      manga: manga ?? this.manga,
      lightNovel: lightNovel ?? this.lightNovel,
      game: game ?? this.game,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    if (t < 0.5) return this;
    return other;
  }
}

/// Safe access: missing extension → paper light (never crash the site).
extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.paperLight;
}
