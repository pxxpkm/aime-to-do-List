import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/core/utils/item_display.dart';
import 'package:acg_todo/core/utils/zh_convert.dart';
import 'package:acg_todo/domain/entities/item.dart';

void main() {
  group('traditionalToSimplified', () {
    test('converts common traditional chars', () {
      expect(traditionalToSimplified('動畫'), '动画');
      expect(traditionalToSimplified('進擊'), '进击');
    });

    test('leaves simplified and latin unchanged', () {
      expect(traditionalToSimplified('动画'), '动画');
      expect(traditionalToSimplified('Naruto'), 'Naruto');
    });
  });

  group('simplifiedToTraditional', () {
    test('converts common simplified titles', () {
      expect(simplifiedToTraditional('动画'), '動畫');
      expect(simplifiedToTraditional('进击的巨人'), '進擊的巨人');
    });

    test('leaves traditional and latin unchanged', () {
      expect(simplifiedToTraditional('動畫'), '動畫');
      expect(simplifiedToTraditional('One Piece'), 'One Piece');
    });

    test('empty string', () {
      expect(simplifiedToTraditional(''), '');
    });
  });

  group('preferTraditionalTitle / applyTitleS2t', () {
    test('enabled converts', () {
      expect(
        preferTraditionalTitle('动画', enabled: true),
        '動畫',
      );
    });

    test('disabled keeps raw', () {
      expect(
        preferTraditionalTitle('动画', enabled: false),
        '动画',
      );
    });

    test('applyTitleS2t updates title fields', () {
      final item = Item(
        id: 'x',
        userId: 'u',
        type: 'anime',
        title: '动画',
        originalTitle: '进击',
      );
      final out = applyTitleS2t(item, enabled: true);
      expect(out.title, '動畫');
      expect(out.originalTitle, '進擊');
    });
  });
}
