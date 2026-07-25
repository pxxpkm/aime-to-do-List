import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:acg_todo/core/theme/app_palette.dart';

/// Paper-gallery type scale — Noto TC via google_fonts.
///
/// **No baked ink colors** — use with [DefaultTextStyle], Theme textTheme,
/// or [AppTypography.themed] / `copyWith(color: context.palette.ink)`.
/// Baked light ink broke dark mode contrast.
class AppTypography {
  static String? get sansFamily => GoogleFonts.notoSansTc().fontFamily;
  static String? get serifFamily => GoogleFonts.notoSerifTc().fontFamily;

  static TextStyle get display => GoogleFonts.notoSerifTc(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: 0,
      );

  static TextStyle get title => GoogleFonts.notoSerifTc(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  static TextStyle get cardTitle => GoogleFonts.notoSansTc(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  static TextStyle get body => GoogleFonts.notoSansTc(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.45,
      );

  static TextStyle get caption => GoogleFonts.notoSansTc(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle get micro => GoogleFonts.notoSansTc(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.25,
      );

  /// Styles with palette ink (primary / secondary / muted).
  static ({
    TextStyle display,
    TextStyle title,
    TextStyle cardTitle,
    TextStyle body,
    TextStyle caption,
    TextStyle micro,
  }) themed(BuildContext context) {
    final p = context.palette;
    return (
      display: display.copyWith(color: p.ink),
      title: title.copyWith(color: p.ink),
      cardTitle: cardTitle.copyWith(color: p.ink),
      body: body.copyWith(color: p.ink),
      caption: caption.copyWith(color: p.inkSecondary),
      micro: micro.copyWith(color: p.inkMuted),
    );
  }
}
