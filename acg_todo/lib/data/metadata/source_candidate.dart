import 'package:acg_todo/core/utils/poster_url.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/item_category.dart';

/// Neutral search hit from any metadata source (Bangumi / AniList / future).
class SourceCandidate {
  /// bangumi | anilist | manual
  final String sourceKey;

  /// External numeric/string id (e.g. Bangumi subject id, AniList media id).
  final String externalId;

  /// Primary display title.
  final String title;

  /// Secondary / original title when different.
  final String? titleAlt;

  final String? posterUrl;
  final int? episodes;
  final int? chapters;
  final int? volumes;
  final String? summary;

  /// Site score on 0–10 scale when known.
  final double? score;
  final int? scoreCount;
  final String? airDate;

  /// Category hint from source (may be refined by UI preferred category).
  final ItemCategory categoryHint;

  /// Canonical library item id (e.g. bgm_123, al_456).
  final String libraryId;

  /// External browse URL when known.
  final String? externalUrl;

  const SourceCandidate({
    required this.sourceKey,
    required this.externalId,
    required this.title,
    this.titleAlt,
    this.posterUrl,
    this.episodes,
    this.chapters,
    this.volumes,
    this.summary,
    this.score,
    this.scoreCount,
    this.airDate,
    required this.categoryHint,
    required this.libraryId,
    this.externalUrl,
  });

  /// Primary label for lists (CN/local name already preferred in [title]).
  String get displayName => title;

  String metaLine() {
    return [
      if (episodes != null) '$episodes 集',
      if (chapters != null) '$chapters 章',
      if (volumes != null) '$volumes 卷',
      if (score != null) '★ $score',
    ].join(' · ');
  }

  /// All ids that might match an existing library row.
  Set<String> get matchIds {
    final n = int.tryParse(externalId);
    return {
      libraryId,
      if (n != null) ...{
        'bgm_$n',
        'al_$n',
        'anilist_$n',
        '$n',
      },
    };
  }

  /// Build domain [Item] for insert.
  Item toItem(String userId, {ItemCategory? preferredCategory}) {
    final cat = preferredCategory ?? categoryHint;
    final int? total = switch (cat) {
      ItemCategory.anime => episodes,
      ItemCategory.manga => chapters ?? volumes,
      ItemCategory.lightNovel => volumes ?? chapters,
      ItemCategory.game => null,
    };
    final totalUnits = (total != null && total > 0) ? total : null;
    final original =
        (titleAlt != null && titleAlt!.isNotEmpty && titleAlt != title)
            ? titleAlt
            : null;

    final anilistId = sourceKey == 'anilist' ? int.tryParse(externalId) : null;

    return Item(
      id: libraryId,
      userId: userId,
      type: cat.storageKey,
      anilistId: anilistId,
      title: title,
      posterUrl: normalizePosterUrl(posterUrl),
      totalUnits: totalUnits,
      currentUnits: 0,
      unitLabel: cat.unitLabel,
      status: 'in_progress',
      score: score,
      scoreCount: scoreCount,
      summary: summary,
      originalTitle: original,
      airDate: airDate,
      source: sourceKey,
      externalUrl: externalUrl,
    );
  }
}
