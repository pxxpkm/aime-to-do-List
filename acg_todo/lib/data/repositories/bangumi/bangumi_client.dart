import 'dart:convert';
import 'dart:typed_data';

import 'package:acg_todo/core/utils/logger.dart';
import 'package:http/http.dart' as http;

import 'bangumi_search_result.dart';
import 'bangumi_user_info.dart';
import 'bangumi_collection.dart';

class BangumiClient {
  final http.Client _http;
  static const _base = 'https://api.bgm.tv';
  static const _baseV0 = 'https://api.bgm.tv/v0';

  BangumiClient({http.Client? client}) : _http = client ?? http.Client();

  /// Search subjects via legacy GET API (no CORS issues).
  Future<List<BangumiSearchResult>> search(
    String query,
    int type, {
    int maxResults = 10,
  }) async {
    try {
      final uri = Uri.parse('$_base/search/subject/${Uri.encodeComponent(query)}')
          .replace(queryParameters: {
        'type': type.toString(),
        'responseGroup': 'large',
        'max_results': maxResults.toString(),
      });

      final response = await _http.get(uri, headers: {
        'User-Agent': 'ACG-ToDo/1.0',
        'Accept': 'application/json',
      });

      if (response.statusCode != 200) {
        Logger().e('Bangumi search error: ${response.statusCode}');
        return [];
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (json['list'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return list.map(BangumiSearchResult.fromJson).toList();
    } catch (e) {
      Logger().e('Bangumi search failed: $e');
      return [];
    }
  }

  Future<BangumiSearchResult?> getSubject(int id, {String? token}) async {
    try {
      final uri = Uri.parse('$_base/subject/$id').replace(queryParameters: {
        'responseGroup': 'large',
      });
      final headers = <String, String>{'User-Agent': 'ACG-ToDo/1.0'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await _http.get(uri, headers: headers);
      if (response.statusCode == 404) return null;  // NSFW 無權訪問
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return BangumiSearchResult.fromJson(json);
    } catch (e) {
      Logger().e('Bangumi getSubject failed: $e');
      return null;
    }
  }

  /// 取得作品封面圖片 bytes（追蹤 302 redirect，OptionalHTTPBearer）
  Future<Uint8List?> getSubjectImage(int id, {String? token, String type = 'common'}) async {
    try {
      final uri = Uri.parse('$_baseV0/subjects/$id/image').replace(queryParameters: {
        'type': type,  // small|grid|large|medium|common
      });
      final headers = <String, String>{'User-Agent': 'ACG-ToDo/1.0'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      // http.get 預設追蹤 redirect，最終回應就是圖片資料
      final response = await _http.get(uri, headers: headers);
      if (response.statusCode == 404) return null;  // NSFW 無權訪問
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      Logger().e('Bangumi getImage failed: $e');
      return null;
    }
  }

  Future<BangumiUserInfo?> userInfo(String token) async {
    try {
      final uri = Uri.parse('$_baseV0/me');
      final response = await _http.get(uri, headers: {
        'User-Agent': 'ACG-ToDo/1.0',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode != 200) {
        Logger().e('Bangumi userInfo error: ${response.statusCode}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return BangumiUserInfo.fromJson(json);
    } catch (e) {
      Logger().e('Bangumi userInfo failed: $e');
      return null;
    }
  }

  Future<List<BangumiCollection>> getAllCollections(String token, int type) async {
    final info = await userInfo(token);
    if (info == null) return [];

    final results = <BangumiCollection>[];
    const statuses = [1, 2, 3, 4, 5];

    for (final status in statuses) {
      int offset = 0;
      const limit = 50;
      while (true) {
        final batch = await _fetchPage(info.username, token, type, status, offset, limit);
        results.addAll(batch);
        if (batch.length < limit) break;
        offset += limit;
      }
    }

    return results;
  }

  Future<List<BangumiCollection>> _fetchPage(
    String username,
    String token,
    int type,
    int status,
    int offset,
    int limit,
  ) async {
    try {
      final uri = Uri.parse('$_baseV0/users/$username/collections').replace(queryParameters: {
        'subject_type': type.toString(),
        'type': status.toString(),
        'offset': offset.toString(),
        'limit': limit.toString(),
      });

      final response = await _http.get(uri, headers: {
        'User-Agent': 'ACG-ToDo/1.0',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (json['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return data.map((e) => BangumiCollection.fromSubjectJson(e, status)).toList();
    } catch (e) {
      Logger().e('Bangumi _fetchPage failed: $e');
      return [];
    }
  }
}
