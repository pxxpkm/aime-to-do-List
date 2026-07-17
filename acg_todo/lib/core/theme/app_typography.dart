import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:acg_todo/core/theme/app_colors.dart';

/// Paper-gallery type scale — Noto TC via google_fonts.
class AppTypography {
  static String? get sansFamily => GoogleFonts.notoSansTc().fontFamily;
  static String? get serifFamily => GoogleFonts.notoSerifTc().fontFamily;

  static TextStyle get display => GoogleFonts.notoSerifTc(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: 0,
        color: AppColors.inkPrimary,
      );

  static TextStyle get title => GoogleFonts.notoSerifTc(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: AppColors.inkPrimary,
      );

  static TextStyle get cardTitle => GoogleFonts.notoSansTc(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: AppColors.inkPrimary,
      );

  static TextStyle get body => GoogleFonts.notoSansTc(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: AppColors.inkPrimary,
      );

  static TextStyle get caption => GoogleFonts.notoSansTc(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.inkSecondary,
      );

  static TextStyle get micro => GoogleFonts.notoSansTc(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: AppColors.inkMuted,
      );
}
