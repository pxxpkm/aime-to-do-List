import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/data/metadata/media_source_adapter.dart';
import 'package:acg_todo/data/metadata/source_candidate.dart';
import 'package:acg_todo/data/metadata/source_registry.dart';
import 'package:acg_todo/domain/entities/item_category.dart';

class _FakeAdapter implements MediaSourceAdapter {
  @override
  final String key;
  @override
  final String label;
  final Set<ItemCategory> supported;
  final List<SourceCandidate> hits;

  _FakeAdapter({
    required this.key,
    required this.label,
    required this.supported,
    required this.hits,
  });

  @override
  bool supportsCategory(ItemCategory category) => supported.contains(category);

  @override
  Future<List<SourceCandidate>> search(
    String query,
    ItemCategory category, {
    String? token,
  }) async {
    if (!supportsCategory(category)) return [];
    return hits
        .where((h) => h.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

void main() {
  final reg = SourceRegistry([
    _FakeAdapter(
      key: 'bangumi',
      label: 'Bangumi',
      supported: ItemCategory.values.toSet(),
      hits: [
        const SourceCandidate(
          sourceKey: 'bangumi',
          externalId: '1',
          title: 'Steins Gate',
          categoryHint: ItemCategory.anime,
          libraryId: 'bgm_1',
        ),
      ],
    ),
    _FakeAdapter(
      key: 'anilist',
      label: 'AniList',
      supported: {
        ItemCategory.anime,
        ItemCategory.manga,
        ItemCategory.lightNovel,
      },
      hits: [
        const SourceCandidate(
          sourceKey: 'anilist',
          externalId: '2',
          title: 'Steins;Gate',
          categoryHint: ItemCategory.anime,
          libraryId: 'al_2',
        ),
      ],
    ),
  ]);

  test('byKey and forCategory', () {
    expect(reg.byKey('bangumi')?.label, 'Bangumi');
    expect(reg.forCategory(ItemCategory.game).map((a) => a.key), ['bangumi']);
    expect(
      reg.forCategory(ItemCategory.anime).map((a) => a.key).toList(),
      ['bangumi', 'anilist'],
    );
  });

  test('search routes to adapter', () async {
    final hits = await reg.search('bangumi', 'steins', ItemCategory.anime);
    expect(hits, hasLength(1));
    expect(hits.first.libraryId, 'bgm_1');
  });

  test('anilist rejects game category via supports', () async {
    final hits = await reg.search('anilist', 'x', ItemCategory.game);
    expect(hits, isEmpty);
  });

  test('SourceCandidate.toItem uses library id and preferred category', () {
    const c = SourceCandidate(
      sourceKey: 'bangumi',
      externalId: '9',
      title: 'Novel',
      volumes: 3,
      categoryHint: ItemCategory.manga,
      libraryId: 'bgm_9',
    );
    final item = c.toItem('u', preferredCategory: ItemCategory.lightNovel);
    expect(item.id, 'bgm_9');
    expect(item.type, 'light_novel');
    expect(item.totalUnits, 3);
    expect(item.source, 'bangumi');
  });
}
