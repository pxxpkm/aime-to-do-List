import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// 圖片下載管理器 — 節流 + 重試 + 快取
class ImageLoadManager {
  static final ImageLoadManager _instance = ImageLoadManager._();
  factory ImageLoadManager() => _instance;
  ImageLoadManager._();

  static const _maxConcurrent = 2;
  static const _requestDelay = Duration(milliseconds: 150);
  static const _maxRetries = 2;

  final Map<String, Uint8List> _cache = {};
  final Set<String> _downloading = {};
  final List<_PendingRequest> _queue = [];
  int _activeCount = 0;

  Future<Uint8List?> download(String url) async {
    if (_cache.containsKey(url)) return _cache[url];

    final completer = Completer<Uint8List?>();
    _queue.add(_PendingRequest(url, completer));
    _processQueue();
    return completer.future;
  }

  void _processQueue() {
    if (_activeCount >= _maxConcurrent || _queue.isEmpty) return;

    final request = _queue.removeAt(0);
    _activeCount++;
    _downloading.add(request.url);

    _downloadWithRetry(request.url).then((bytes) {
      if (bytes != null) _cache[request.url] = bytes;
      request.completer.complete(bytes);
    }).catchError((e) {
      request.completer.complete(null);
    }).whenComplete(() {
      _activeCount--;
      _downloading.remove(request.url);
      _processQueue();
    });

    if (_queue.isNotEmpty && _activeCount < _maxConcurrent) {
      Timer(_requestDelay, _processQueue);
    }
  }

  Future<Uint8List?> _downloadWithRetry(String url) async {
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      if (attempt > 0) {
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      }

      try {
        final response = await http.get(Uri.parse(url), headers: {
          'User-Agent': 'ACG-ToDo/1.0',
        });
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          return response.bodyBytes;
        }
      } catch (_) {}
    }
    return null;
  }
}

class _PendingRequest {
  final String url;
  final Completer<Uint8List?> completer;
  _PendingRequest(this.url, this.completer);
}
