import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Side-by-side layout when body is wide enough (desktop 16:9).
bool useWideDetailLayout(BoxConstraints c) => c.maxWidth >= 900;

/// Max width of the info panel in wide side-by-side mode (do not stretch).
const double kDetailSidePanelMaxWidth = 460;

/// Max width for stacked (vertical) content under poster.
const double kDetailContentMaxWidth = 720;

/// Wide layout: poster fills available height (2:3), then may shrink for width.
({double width, double height}) detailWidePosterSize({
  required double availableWidth,
  required double availableHeight,
  double aspect = 0.7,
  /// Poster must not eat more than this fraction of total body width.
  double maxWidthFraction = 0.58,
}) {
  final maxH = math.max(200.0, availableHeight);
  var h = maxH;
  var w = h * aspect;

  final maxW = availableWidth * maxWidthFraction;
  if (w > maxW) {
    w = maxW;
    h = w / aspect;
  }
  // Leave a little padding inside the column.
  final pad = 16.0;
  if (w > availableWidth - pad) {
    w = math.max(160.0, availableWidth - pad);
    h = w / aspect;
  }
  return (width: w, height: h);
}

/// Narrow / vertical detail: max 2:3 within viewport, centered.
({double width, double height}) detailHeroPosterSize({
  required double mediaWidth,
  required double mediaHeight,
  double heightFraction = 0.58,
  double aspect = 0.7,
  double horizontalPadding = 32,
  double maxPosterWidth = 560,
}) {
  final maxH = mediaHeight * heightFraction;
  final maxW = math.min(mediaWidth - horizontalPadding, maxPosterWidth);
  var w = math.min(maxW, maxH * aspect);
  var h = w / aspect;
  if (h > maxH) {
    h = maxH;
    w = h * aspect;
  }
  if (w < 200) {
    w = math.min(maxW, 200);
    h = w / aspect;
  }
  return (width: w, height: h);
}
