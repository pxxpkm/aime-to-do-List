import 'package:acg_todo/core/utils/poster_url.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/item_category.dart';

import 'bangumi_search_result.dart';
import 'bangumi_collection.dart';

String? _trimSummary(String? s, {int max = 2000}) {
  if (s == null) return null;
  final t = s.trim();
  if (t.isEmpty) return null;
  if (t.length <= max) return t;
  return t.substring(0, max);
}

extension BangumiSearchResultMapper on BangumiSearchResult {
  /// [preferredCategory] keeps Light Novel as light_novel when Bangumi type is 1 (book).
  Item toItem(String userId, {ItemCategory? preferredCategory}) {
    final category = preferredCategory != null &&
            preferredCategory != ItemCategory.anime &&
            ((type == 1 &&
                    (preferredCategory == ItemCategory.manga ||
                        preferredCategory == ItemCategory.lightNovel)) ||
                (type == 2 && preferredCategory == ItemCategory.anime) ||
                (type == 4 && preferredCategory == ItemCategory.game))
        ? preferredCategory
        : switch (type) {
            2 => ItemCategory.anime,
            1 => preferredCategory == ItemCategory.lightNovel
                ? ItemCategory.lightNovel
                : ItemCategory.manga,
            4 => ItemCategory.game,
            _ => preferredCategory ?? ItemCategory.anime,
          };

    final int? total = switch (type) {
      2 => episodes,
      1 => preferredCategory == ItemCategory.lightNovel
          ? (volumes ?? chapters)
          : (chapters ?? volumes),
      4 => null,
      _ => episodes,
    };

    final totalUnits = (total != null && total > 0) ? total : null;
    final display = displayName;
    final original =
        (title.isNotEmpty && title != display) ? title : null;

    return Item(
      id: 'bgm_$id',
      userId: userId,
      type: category.storageKey,
      title: display,
      posterUrl: normalizePosterUrl(posterUrl),
      totalUnits: totalUnits,
      currentUnits: 0,
      unitLabel: category.unitLabel,
      status: 'in_progress',
      score: score,
      scoreCount: scoreCount,
      summary: _trimSummary(summary),
      originalTitle: original,
      airDate: airDate,
      source: 'bangumi',
      externalUrl: 'https://bgm.tv/subject/$id',
    );
  }
}

extension BangumiCollectionMapper on BangumiCollection {
  Item toItem(String userId) {
    final category = switch (type) {
      2 => ItemCategory.anime,
      1 => ItemCategory.manga,
      4 => ItemCategory.game,
      _ => ItemCategory.anime,
    };

    final total = eps;
    final totalUnits = (total != null && total > 0) ? total : null;

    final statusStr = switch (status) {
      3 => 'completed',
      4 => 'paused',
      5 => 'dropped',
      _ => 'in_progress',
    };

    return Item(
      id: 'bgm_$subjectId',
      userId: userId,
      type: category.storageKey,
      title: displayName,
      posterUrl: normalizePosterUrl(posterUrl),
      totalUnits: totalUnits,
      currentUnits: 0,
      unitLabel: category.unitLabel,
      status: statusStr,
      source: 'bangumi',
      externalUrl: 'https://bgm.tv/subject/$subjectId',
    );
  }
}

String getBangumiDefaultImageUrl() =>
    'https://lain.bgm.tv/img/no_icon_subject.png';
