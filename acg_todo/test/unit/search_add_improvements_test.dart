import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/core/utils/zh_convert.dart';
import 'package:acg_todo/data/repositories/bangumi/bangumi_search_result.dart';
import 'package:acg_todo/data/repositories/bangumi/mappers.dart';
import 'package:acg_todo/domain/entities/item_category.dart';

void main() {
  group('zh convert', () {
    test('traditional to simplified', () {
      expect(traditionalToSimplified('無職轉生'), '无职转生');
      expect(traditionalToSimplified('藥屋少女'), '药屋少女');
      expect(didConvertToSimplified('無職', '无职'), isTrue);
      expect(didConvertToSimplified('hello', 'hello'), isFalse);
    });
  });

  group('Bangumi toItem', () {
    test('respects light novel preferred category', () {
      final r = BangumiSearchResult(
        id: 1,
        title: 'Test',
        type: 1,
        volumes: null,
        chapters: null,
      );
      final item = r.toItem('u', preferredCategory: ItemCategory.lightNovel);
      expect(item.type, 'light_novel');
      expect(item.totalUnits, isNull);
      expect(item.unitLabel, '卷');
    });

    test('zero total treated as unknown', () {
      final r = BangumiSearchResult(
        id: 2,
        title: 'A',
        type: 2,
        episodes: 0,
      );
      final item = r.toItem('u');
      expect(item.totalUnits, isNull);
    });
  });
}
