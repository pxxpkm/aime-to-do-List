import 'dart:convert';

import 'package:acg_todo/core/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ServerHealth {
  final String dbPath;
  final int itemCount;
  final int folderCount;
  final String baseUrl;

  const ServerHealth({
    required this.dbPath,
    required this.itemCount,
    required this.folderCount,
    required this.baseUrl,
  });
}

/// Probe local 8080 library API. Returns null if unavailable.
Future<ServerHealth?> probeLibraryServer({
  String? baseUrl,
  Duration timeout = const Duration(seconds: 3),
  http.Client? client,
}) async {
  final origin = baseUrl ??
      (kIsWeb ? Uri.base.origin : 'http://127.0.0.1:8080');
  // Skip obvious non-http origins (e.g. file://)
  if (!origin.startsWith('http://') && !origin.startsWith('https://')) {
    return null;
  }

  final ownsClient = client == null;
  final c = client ?? http.Client();
  try {
    final uri = Uri.parse(origin).resolve('/api/health');
    final res = await c.get(uri).timeout(timeout);
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    if (body is! Map) return null;
    if (body['ok'] != true) return null;
    return ServerHealth(
      dbPath: body['dbPath']?.toString() ?? '',
      itemCount: (body['itemCount'] as num?)?.toInt() ?? 0,
      folderCount: (body['folderCount'] as num?)?.toInt() ?? 0,
      baseUrl: origin,
    );
  } catch (e) {
    Logger().d('Library server probe failed: $e');
    return null;
  } finally {
    if (ownsClient) c.close();
  }
}
