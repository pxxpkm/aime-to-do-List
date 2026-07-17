import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/presentation/pages/item_detail/detail_layout.dart';
import 'package:flutter/material.dart';

void main() {
  test('useWideDetailLayout at width >= 900', () {
    expect(
      useWideDetailLayout(
        const BoxConstraints.tightFor(width: 1280, height: 720),
      ),
      isTrue,
    );
    expect(
      useWideDetailLayout(
        const BoxConstraints.tightFor(width: 900, height: 900),
      ),
      isTrue,
    );
    expect(
      useWideDetailLayout(
        const BoxConstraints.tightFor(width: 400, height: 800),
      ),
      isFalse,
    );
    expect(
      useWideDetailLayout(
        const BoxConstraints.tightFor(width: 800, height: 900),
      ),
      isFalse,
    );
  });

  test('widePosterColumnWidth breakpoints', () {
    expect(widePosterColumnWidth(950), closeTo(950 * 0.37, 0.5));
    expect(widePosterColumnWidth(950), lessThanOrEqualTo(360));

    expect(widePosterColumnWidth(1200), closeTo(1200 * 0.33, 0.5));
    expect(widePosterColumnWidth(1200), lessThanOrEqualTo(400));

    expect(widePosterColumnWidth(1600), 420);
    expect(widePosterColumnWidth(2000), 420);
  });

  test('portraitPosterSize respects height fraction and ratio', () {
    final s = portraitPosterSize(mediaWidth: 400, mediaHeight: 800);
    expect(s.width / s.height, closeTo(0.7, 0.01));
    expect(s.height, lessThanOrEqualTo(800 * 0.55 + 1));
    expect(s.width, lessThanOrEqualTo(400 - 32 + 1));
  });

  test('widePosterSize fills height within column', () {
    final s = widePosterSize(columnWidth: 500, availableHeight: 600);
    expect(s.height, lessThanOrEqualTo(600));
    expect(s.width, lessThanOrEqualTo(500));
    expect(s.width / s.height, closeTo(0.7, 0.01));
  });
}
