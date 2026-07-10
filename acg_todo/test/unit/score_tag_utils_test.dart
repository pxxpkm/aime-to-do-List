import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/core/utils/score_utils.dart';
import 'package:acg_todo/core/utils/tag_utils.dart';

void main() {
  group('roundUserScore', () {
    test('null stays null', () {
      expect(roundUserScore(null), isNull);
    });

    test('clamps and rounds to 0.1', () {
      expect(roundUserScore(-1), 0.0);
      expect(roundUserScore(11), 10.0);
      expect(roundUserScore(9.34), 9.3);
      expect(roundUserScore(9.35), 9.4);
      expect(roundUserScore(9.3), 9.3);
    });
  });

  group('normalizeTags', () {
    test('trim dedupe and limits', () {
      expect(
        normalizeTags(['  a  ', 'a', 'b', '', '  ']),
        ['a', 'b'],
      );
    });

    test('collapses whitespace and truncates length', () {
      final long = 'x' * 40;
      final out = normalizeTags(['hello   world', long]);
      expect(out[0], 'hello world');
      expect(out[1].length, kMaxTagLength);
    });

    test('max tags', () {
      final many = List.generate(30, (i) => 't$i');
      expect(normalizeTags(many).length, kMaxTagsPerItem);
    });
  });
}
