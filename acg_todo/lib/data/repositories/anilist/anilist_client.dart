import 'dart:convert';

import 'package:acg_todo/core/utils/logger.dart';
import 'package:acg_todo/data/repositories/anilist/rate_limiter.dart';
import 'package:acg_todo/data/repositories/anilist/queries.dart';
import 'package:http/http.dart' as http;

const _anilistEndpoint = 'https://graphql.anilist.co';

class AniListSearchResult {
  final int id;
  final String title;
  final String? posterUrl;
  final int? totalEpisodes;
  final int? totalChapters;
  final int? totalVolumes;
  final String? status;
  final String? description;
  final int? averageScore;

  AniListSearchResult({
    required this.id,
    required this.title,
    this.posterUrl,
    this.totalEpisodes,
    this.totalChapters,
    this.totalVolumes,
    this.status,
    this.description,
    this.averageScore,
  });

  factory AniListSearchResult.fromJson(Map<String, dynamic> json) {
    final titleObj = json['title'] as Map<String, dynamic>?;
    final coverObj = json['coverImage'] as Map<String, dynamic>?;

    return AniListSearchResult(
      id: json['id'] as int,
      title: titleObj?['romaji'] as String? ??
          titleObj?['english'] as String? ??
          titleObj?['native'] as String? ??
          'Unknown',
      posterUrl: coverObj?['extraLarge'] as String? ??
          coverObj?['large'] as String?,
      totalEpisodes: json['episodes'] as int?,
      totalChapters: json['chapters'] as int?,
      totalVolumes: json['volumes'] as int?,
      status: json['status'] as String?,
      description: json['description'] as String?,
      averageScore: json['averageScore'] as int?,
    );
  }
}

class AniListClient {
  final AniListRateLimiter _rateLimiter = AniListRateLimiter();
  final http.Client _http = http.Client();

  /// type: 'ANIME' | 'MANGA' | 'NOVEL'
  Future<List<AniListSearchResult>> search(String query, String type) async {
    await _rateLimiter.acquire();

    final graphqlType = _mapTypeToGraphql(type);

    try {
      final response = await _http.post(
        Uri.parse(_anilistEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': AniListQueries.search,
          'variables': {
            'search': query,
            'type': graphqlType,
            'perPage': 10,
          },
        }),
      );

      if (response.statusCode != 200) {
        Logger().e('AniList error: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final media = (data['data']?['Page']?['media'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      return media.map((m) => AniListSearchResult.fromJson(m)).toList();
    } catch (e) {
      Logger().e('AniList search failed', e);
      return [];
    }
  }

  Future<AniListSearchResult?> getById(int id) async {
    await _rateLimiter.acquire();

    try {
      final response = await _http.post(
        Uri.parse(_anilistEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': AniListQueries.detail,
          'variables': {'id': id},
        }),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final media = data['data']?['Media'] as Map<String, dynamic>?;
      if (media == null) return null;

      return AniListSearchResult.fromJson(media);
    } catch (e) {
      Logger().e('AniList fetch failed', e);
      return null;
    }
  }

  String _mapTypeToGraphql(String type) {
    switch (type) {
      case 'anime':
        return 'ANIME';
      case 'manga':
        return 'MANGA';
      case 'light_novel':
        return 'NOVEL';
      default:
        return 'ANIME';
    }
  }

  void dispose() => _http.close();
}
