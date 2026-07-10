import 'package:acg_todo/core/utils/poster_url.dart';

class BangumiSearchResult {
  final int id;
  final String title;
  final String? nameCn;
  final String? posterUrl;
  final int? episodes;
  final int? chapters;
  final int? volumes;
  final String? summary;
  final double? score;
  final int? scoreCount;
  final String? airDate;
  final int type;

  BangumiSearchResult({
    required this.id,
    required this.title,
    this.nameCn,
    this.posterUrl,
    this.episodes,
    this.chapters,
    this.volumes,
    this.summary,
    this.score,
    this.scoreCount,
    this.airDate,
    required this.type,
  });

  factory BangumiSearchResult.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>?;
    final rating = json['rating'] as Map<String, dynamic>?;

    // Prefer large for home/detail clarity; common is ~list thumb and looks soft.
    // API: large | common | medium | small | grid (see bangumi OpenAPI images).
    final rawPoster = images?['large'] as String? ??
        images?['common'] as String? ??
        images?['medium'] as String? ??
        images?['small'] as String? ??
        images?['grid'] as String?;

    return BangumiSearchResult(
      id: json['id'] as int,
      title: json['name'] as String? ?? 'Unknown',
      nameCn: json['name_cn'] as String?,
      posterUrl: normalizePosterUrl(rawPoster),
      episodes: json['eps'] as int? ??
          json['eps_count'] as int? ??
          json['total_episodes'] as int?,
      chapters: json['chapters'] as int?,
      volumes: json['volumes'] as int?,
      summary: json['summary'] as String?,
      score: (rating?['score'] as num?)?.toDouble(),
      scoreCount: rating?['total'] as int?,
      airDate: json['air_date'] as String?,
      type: json['type'] as int? ?? 2,
    );
  }

  String get displayName =>
      (nameCn != null && nameCn!.isNotEmpty) ? nameCn! : title;
}
