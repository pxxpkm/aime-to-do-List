import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Dual-column detail when the body is wide enough (desktop / landscape tablet).
bool useWideDetailLayout(BoxConstraints c) {
  return c.maxWidth >= 900;
}

/// Adaptive left poster column width for dual-column detail.
///
/// - 900–1100: ~37% (cap 360)
/// - 1100–1400: ~33% (cap 400)
/// - >1400: fixed ~420 so info column absorbs rest
double widePosterColumnWidth(double maxWidth) {
  if (maxWidth < 900) return maxWidth;
  if (maxWidth < 1100) {
    return math.min(maxWidth * 0.37, 360.0);
  }
  if (maxWidth < 1400) {
    return math.min(maxWidth * 0.33, 400.0);
  }
  return 420.0;
}

/// Portrait poster for narrow layout: larger than old 320 cap.
({double width, double height}) portraitPosterSize({
  required double mediaWidth,
  required double mediaHeight,
  double heightFraction = 0.55,
  double aspect = 0.7,
  double horizontalPadding = 32,
  double maxWidth = 420,
}) {
  final maxH = mediaHeight * heightFraction;
  final maxW = math.min(mediaWidth - horizontalPadding, maxWidth);
  var w = math.min(maxW, maxH * aspect);
  var h = w / aspect;
  if (h > maxH) {
    h = maxH;
    w = h * aspect;
  }
  return (width: w, height: h);
}

/// Wide left poster: fill available height within column width, ratio 0.7.
({double width, double height}) widePosterSize({
  required double columnWidth,
  required double availableHeight,
  double aspect = 0.7,
}) {
  final h = math.max(160.0, availableHeight);
  var w = h * aspect;
  if (w > columnWidth) {
    w = columnWidth;
  }
  final finalH = w / aspect;
  return (width: w, height: finalH);
}
