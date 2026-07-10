import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/data/repositories/bangumi/bangumi_search_result.dart';
import 'package:acg_todo/data/repositories/bangumi/mappers.dart';
import 'package:acg_todo/domain/entities/item_category.dart';

void main() {
  test('toItem stores score summary airDate source url', () {
    final r = BangumiSearchResult(
      id: 42,
      title: 'Original JP',
      nameCn: '中文名',
      type: 2,
      episodes: 12,
      score: 8.2,
      scoreCount: 100,
      summary: 'A short summary',
      airDate: '2020-01-01',
    );
    final item = r.toItem('u');
    expect(item.score, 8.2);
    expect(item.scoreCount, 100);
    expect(item.summary, 'A short summary');
    expect(item.airDate, '2020-01-01');
    expect(item.source, 'bangumi');
    expect(item.externalUrl, 'https://bgm.tv/subject/42');
    expect(item.originalTitle, 'Original JP');
    expect(item.title, '中文名');
  });

  test('light novel preferred category', () {
    final r = BangumiSearchResult(id: 1, title: 'LN', type: 1);
    final item =
        r.toItem('u', preferredCategory: ItemCategory.lightNovel);
    expect(item.type, 'light_novel');
  });
}
