import 'package:flutter/material.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_typography.dart';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.paperBg,
      fontFamily: AppTypography.sansFamily,
    );

    return base.copyWith(
      colorScheme: ColorScheme.light(
        primary: AppColors.anime,
        secondary: AppColors.manga,
        surface: AppColors.paperSurface,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.inkPrimary,
        onError: Colors.white,
        outline: AppColors.borderSubtle,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.display,
        displayMedium: AppTypography.display,
        displaySmall: AppTypography.title,
        headlineLarge: AppTypography.display,
        headlineMedium: AppTypography.title,
        headlineSmall: AppTypography.title,
        titleLarge: AppTypography.title,
        titleMedium: AppTypography.body.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: AppTypography.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.caption,
        labelLarge: AppTypography.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: AppTypography.caption,
        labelSmall: AppTypography.micro,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paperSurface,
        foregroundColor: AppColors.inkPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: AppTypography.title,
        iconTheme: const IconThemeData(color: AppColors.inkSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.paperElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.paperSurface,
        selectedColor: AppColors.anime.withValues(alpha: 0.15),
        disabledColor: AppColors.divider,
        labelStyle: AppTypography.caption.copyWith(color: AppColors.inkPrimary),
        secondaryLabelStyle:
            AppTypography.caption.copyWith(color: AppColors.inkPrimary),
        side: const BorderSide(color: AppColors.borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.anime,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.inkPrimary,
        contentTextStyle: AppTypography.body.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.paperElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppTypography.title,
        contentTextStyle: AppTypography.body,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.paperElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paperElevated,
        hintStyle: AppTypography.body.copyWith(color: AppColors.inkMuted),
        labelStyle: AppTypography.caption,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.anime, width: 1.5),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.anime,
        linearTrackColor: AppColors.divider,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.inkSecondary,
        textColor: AppColors.inkPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.inkSecondary),
    );
  }

  /// Legacy alias — paper light is the only v1 theme.
  static ThemeData get dark => light;
}
