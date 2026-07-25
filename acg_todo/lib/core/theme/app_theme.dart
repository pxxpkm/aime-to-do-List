import 'package:flutter/material.dart';

import 'package:acg_todo/core/theme/app_palette.dart';
import 'package:acg_todo/core/theme/app_typography.dart';

class AppTheme {
  /// Build Material theme from a palette (multi-theme ready).
  static ThemeData fromPalette(AppPalette p) {
    final isDark = p.brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      scaffoldBackgroundColor: p.bg,
      fontFamily: AppTypography.sansFamily,
    );

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: p.anime,
            secondary: p.manga,
            surface: p.surface,
            error: p.danger,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: p.ink,
            onError: Colors.white,
            outline: p.border,
          )
        : ColorScheme.light(
            primary: p.anime,
            secondary: p.manga,
            surface: p.surface,
            error: p.danger,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: p.ink,
            onError: Colors.white,
            outline: p.border,
          );

    TextStyle withInk(TextStyle s, Color c) => s.copyWith(color: c);

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[p],
      colorScheme: colorScheme,
      textTheme: TextTheme(
        displayLarge: withInk(AppTypography.display, p.ink),
        displayMedium: withInk(AppTypography.display, p.ink),
        displaySmall: withInk(AppTypography.title, p.ink),
        headlineLarge: withInk(AppTypography.display, p.ink),
        headlineMedium: withInk(AppTypography.title, p.ink),
        headlineSmall: withInk(AppTypography.title, p.ink),
        titleLarge: withInk(AppTypography.title, p.ink),
        titleMedium: withInk(
          AppTypography.body.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          p.ink,
        ),
        titleSmall: withInk(
          AppTypography.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          p.ink,
        ),
        bodyLarge: withInk(AppTypography.body, p.ink),
        bodyMedium: withInk(AppTypography.body, p.ink),
        bodySmall: withInk(AppTypography.caption, p.inkSecondary),
        labelLarge: withInk(
          AppTypography.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          p.ink,
        ),
        labelMedium: withInk(AppTypography.caption, p.inkSecondary),
        labelSmall: withInk(AppTypography.micro, p.inkMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: withInk(AppTypography.title, p.ink),
        iconTheme: IconThemeData(color: p.inkSecondary),
      ),
      cardTheme: CardThemeData(
        color: p.elevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.anime.withValues(alpha: 0.15),
        disabledColor: p.divider,
        labelStyle: withInk(AppTypography.caption, p.ink),
        secondaryLabelStyle: withInk(AppTypography.caption, p.ink),
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.anime,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? p.elevated : p.ink,
        contentTextStyle: withInk(
          AppTypography.body,
          isDark ? p.ink : Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.elevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: withInk(AppTypography.title, p.ink),
        contentTextStyle: withInk(AppTypography.body, p.ink),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.elevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.elevated,
        hintStyle: withInk(AppTypography.body, p.inkMuted),
        labelStyle: withInk(AppTypography.caption, p.inkSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.anime, width: 1.5),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.anime,
        linearTrackColor: p.divider,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.inkSecondary,
        textColor: p.ink,
      ),
      iconTheme: IconThemeData(color: p.inkSecondary),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.surface,
        selectedIconTheme: IconThemeData(color: p.anime),
        unselectedIconTheme: IconThemeData(color: p.inkSecondary),
        selectedLabelTextStyle: withInk(AppTypography.caption, p.anime),
        unselectedLabelTextStyle:
            withInk(AppTypography.caption, p.inkSecondary),
      ),
      drawerTheme: DrawerThemeData(backgroundColor: p.surface),
    );
  }

  /// Default / frozen paper light (same pixels as historical AppTheme.light).
  static ThemeData get light => fromPalette(AppPalette.paperLight);

  /// Warm dark gallery theme.
  static ThemeData get dark => fromPalette(AppPalette.paperDark);
}
