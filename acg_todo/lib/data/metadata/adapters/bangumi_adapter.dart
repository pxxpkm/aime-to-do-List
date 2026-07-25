import 'package:acg_todo/core/utils/poster_url.dart';
import 'package:acg_todo/data/metadata/media_source_adapter.dart';
import 'package:acg_todo/data/metadata/source_candidate.dart';
import 'package:acg_todo/data/repositories/bangumi/bangumi_client.dart';
import 'package:acg_todo/domain/entities/item_category.dart';

class BangumiAdapter implements MediaSourceAdapter {
  final BangumiClient _client;

  BangumiAdapter(this._client);

  @override
  String get key => 'bangumi';

  @override
  String get label => 'Bangumi';

  @override
  bool supportsCategory(ItemCategory category) => true;

  @override
  Future<List<SourceCandidate>> search(
    String query,
    ItemCategory category, {
    String? token,
  }) async {
    final results = await _client.search(query, category.bangumiType);
    return results.map((r) {
      final display = r.displayName;
      final original =
          (r.title.isNotEmpty && r.title != display) ? r.title : null;
      final hint = switch (r.type) {
        2 => ItemCategory.anime,
        1 => category == ItemCategory.lightNovel
            ? ItemCategory.lightNovel
            : ItemCategory.manga,
        4 => ItemCategory.game,
        _ => category,
      };
      return SourceCandidate(
        sourceKey: key,
        externalId: '${r.id}',
        title: display,
        titleAlt: original,
        posterUrl: normalizePosterUrl(r.posterUrl),
        episodes: r.episodes,
        chapters: r.chapters,
        volumes: r.volumes,
        summary: r.summary,
        score: r.score,
        scoreCount: r.scoreCount,
        airDate: r.airDate,
        categoryHint: hint,
        libraryId: 'bgm_${r.id}',
        externalUrl: 'https://bgm.tv/subject/${r.id}',
      );
    }).toList();
  }
}
