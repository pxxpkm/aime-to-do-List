import 'package:acg_todo/core/utils/poster_url.dart';
import 'package:acg_todo/data/metadata/media_source_adapter.dart';
import 'package:acg_todo/data/metadata/source_candidate.dart';
import 'package:acg_todo/data/repositories/anilist/anilist_client.dart';
import 'package:acg_todo/domain/entities/item_category.dart';

class AniListAdapter implements MediaSourceAdapter {
  final AniListClient _client;

  AniListAdapter(this._client);

  @override
  String get key => 'anilist';

  @override
  String get label => 'AniList';

  @override
  bool supportsCategory(ItemCategory category) =>
      category != ItemCategory.game;

  @override
  Future<List<SourceCandidate>> search(
    String query,
    ItemCategory category, {
    String? token,
  }) async {
    if (!supportsCategory(category)) return [];
    final results = await _client.search(query, category.storageKey);
    return results.map((r) {
      final mediaPath = category == ItemCategory.anime ? 'anime' : 'manga';
      final score10 =
          r.averageScore != null ? r.averageScore! / 10.0 : null;
      return SourceCandidate(
        sourceKey: key,
        externalId: '${r.id}',
        title: r.title,
        posterUrl: normalizePosterUrl(r.posterUrl),
        episodes: r.totalEpisodes,
        chapters: r.totalChapters,
        volumes: r.totalVolumes,
        summary: r.description,
        score: score10,
        categoryHint: category,
        libraryId: 'al_${r.id}',
        externalUrl: 'https://anilist.co/$mediaPath/${r.id}',
      );
    }).toList();
  }
}
