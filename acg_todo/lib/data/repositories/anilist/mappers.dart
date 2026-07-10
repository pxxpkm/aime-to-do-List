import 'package:acg_todo/core/utils/poster_url.dart';
import 'package:acg_todo/data/repositories/anilist/anilist_client.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/item_category.dart';

String? _stripHtml(String? html, {int max = 2000}) {
  if (html == null) return null;
  var t = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .trim();
  if (t.isEmpty) return null;
  if (t.length > max) t = t.substring(0, max);
  return t;
}

extension AniListSearchResultMapper on AniListSearchResult {
  Item toItem(String userId, {ItemCategory? preferredCategory}) {
    final detectedType = preferredCategory?.storageKey ?? _detectType();
    final (total, label) = _inferUnits(type: detectedType);
    final totalUnits = (total != null && total > 0) ? total : null;
    final score10 =
        averageScore != null ? (averageScore! / 10.0) : null;

    final mediaPath =
        detectedType == 'anime' ? 'anime' : 'manga';

    return Item(
      id: 'al_$id',
      userId: userId,
      type: detectedType,
      anilistId: id,
      title: title,
      posterUrl: normalizePosterUrl(posterUrl),
      totalUnits: totalUnits,
      currentUnits: 0,
      unitLabel: preferredCategory?.unitLabel ?? label,
      status: 'in_progress',
      score: score10,
      summary: _stripHtml(description),
      source: 'anilist',
      externalUrl: 'https://anilist.co/$mediaPath/$id',
    );
  }

  String _detectType() {
    if (totalVolumes != null && totalVolumes! > 0) return 'light_novel';
    if (totalEpisodes != null && totalEpisodes! > 0) return 'anime';
    if (totalChapters != null && totalChapters! > 0) return 'manga';
    return 'anime';
  }

  (int? total, String label) _inferUnits({required String type}) {
    switch (type) {
      case 'anime':
        return (totalEpisodes, '集');
      case 'manga':
        return (totalChapters, '章');
      case 'light_novel':
        return (totalVolumes, '卷');
      default:
        return (null, '集');
    }
  }
}
