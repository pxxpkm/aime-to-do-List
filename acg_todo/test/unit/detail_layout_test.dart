import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:acg_todo/presentation/pages/item_detail/detail_layout.dart';

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
        const BoxConstraints.tightFor(width: 800, height: 900),
      ),
      isFalse,
    );
  });

  test('detailWidePosterSize prefers full height 2:3', () {
    final s = detailWidePosterSize(
      availableWidth: 1400,
      availableHeight: 700,
    );
    expect(s.height, closeTo(700, 1));
    expect(s.width / s.height, closeTo(0.7, 0.01));
    // Must not take more than ~58% of width
    expect(s.width, lessThanOrEqualTo(1400 * 0.58 + 1));
  });

  test('detailWidePosterSize shrinks when width-limited', () {
    final s = detailWidePosterSize(
      availableWidth: 900,
      availableHeight: 800,
    );
    expect(s.width, lessThanOrEqualTo(900 * 0.58 + 1));
    expect(s.width / s.height, closeTo(0.7, 0.01));
  });

  test('detailHeroPosterSize keeps 2:3 for stacked layout', () {
    final s = detailHeroPosterSize(mediaWidth: 400, mediaHeight: 800);
    expect(s.width / s.height, closeTo(0.7, 0.01));
    expect(s.height, lessThanOrEqualTo(800 * 0.58 + 1));
  });

  test('side panel max width is tight', () {
    expect(kDetailSidePanelMaxWidth, 460);
    expect(kDetailContentMaxWidth, 720);
  });
}
