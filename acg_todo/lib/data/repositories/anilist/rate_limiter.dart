import 'dart:async';

import 'package:acg_todo/core/utils/logger.dart';

/// Token bucket rate limiter — AniList allows 90 req/min.
class AniListRateLimiter {
  final List<DateTime> _timestamps = [];

  AniListRateLimiter({
    this.maxRequests = 85,
    this.window = const Duration(minutes: 1),
  });

  final int maxRequests;
  final Duration window;

  Future<void> acquire() async {
    final now = DateTime.now();
    _timestamps.removeWhere((t) => now.difference(t) > window);

    if (_timestamps.length >= maxRequests) {
      final oldest = _timestamps.first;
      final wait = window - now.difference(oldest);
      Logger().w('Rate limit hit, waiting ${wait.inMilliseconds}ms');
      await Future.delayed(wait + const Duration(milliseconds: 100));
      return acquire();
    }

    _timestamps.add(now);
  }
}
