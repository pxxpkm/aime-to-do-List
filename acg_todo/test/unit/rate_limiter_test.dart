import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/data/repositories/anilist/rate_limiter.dart';

void main() {
  group('AniListRateLimiter', () {
    test('allows requests under the limit', () async {
      final limiter = AniListRateLimiter(maxRequests: 5);

      for (var i = 0; i < 5; i++) {
        await limiter.acquire();
      }
      // No exception means it passed
      expect(true, isTrue);
    });

    test('blocks when limit is reached', () async {
      final limiter = AniListRateLimiter(
        maxRequests: 2,
        window: const Duration(milliseconds: 200),
      );

      await limiter.acquire();
      await limiter.acquire();

      // Third acquire should wait (we just verify it doesn't throw)
      final stopwatch = Stopwatch()..start();
      await limiter.acquire();
      stopwatch.stop();

      // Should have waited at least some time
      expect(stopwatch.elapsedMilliseconds, greaterThan(0));
    });

    test('resets after window expires', () async {
      final limiter = AniListRateLimiter(
        maxRequests: 1,
        window: const Duration(milliseconds: 50),
      );

      await limiter.acquire();

      // Wait for window to expire
      await Future.delayed(const Duration(milliseconds: 60));

      // Should be able to acquire again without waiting
      final stopwatch = Stopwatch()..start();
      await limiter.acquire();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });
}
