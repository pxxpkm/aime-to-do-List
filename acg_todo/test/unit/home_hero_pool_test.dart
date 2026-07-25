import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/pin_tier.dart';
import 'package:acg_todo/presentation/home/home_hero_pool.dart';

Item _i({
  required String id,
  String title = 't',
  String? posterUrl = 'https://example.com/p.jpg',
  PinTier pinTier = PinTier.none,
  int pinOrder = 0,
  DateTime? lastProgressAt,
  DateTime? createdAt,
}) {
  return Item(
    id: id,
    userId: 'u',
    type: 'anime',
    title: title,
    posterUrl: posterUrl,
    pinTier: pinTier,
    pinOrder: pinOrder,
    lastProgressAt: lastProgressAt,
    createdAt: createdAt,
  );
}

void main() {
  group('buildHeroPool', () {
    test('prefers items with poster art', () {
      final pool = buildHeroPool([
        _i(id: 'a', posterUrl: null),
        _i(id: 'b', posterUrl: 'https://x/b.jpg'),
        _i(id: 'c', posterUrl: ''),
      ]);
      expect(pool.map((e) => e.id), ['b']);
    });

    test('falls back to all items when none have art', () {
      final pool = buildHeroPool([
        _i(id: 'a', posterUrl: null, title: 'Alpha'),
        _i(id: 'b', posterUrl: '', title: 'Beta'),
      ]);
      expect(pool.length, 2);
      expect(pool.map((e) => e.id).toSet(), {'a', 'b'});
    });

    test('sorts pin watching before priority before none', () {
      final pool = buildHeroPool([
        _i(id: 'none', pinTier: PinTier.none, title: 'Z'),
        _i(id: 'pri', pinTier: PinTier.priority, title: 'Y'),
        _i(id: 'watch', pinTier: PinTier.watching, title: 'X'),
      ]);
      expect(pool.map((e) => e.id), ['watch', 'pri', 'none']);
    });

    test('within same pin tier uses pinOrder then recent progress', () {
      final older = DateTime(2026, 1, 1);
      final newer = DateTime(2026, 6, 1);
      final pool = buildHeroPool([
        _i(
          id: 'w2',
          pinTier: PinTier.watching,
          pinOrder: 1,
          lastProgressAt: newer,
          title: 'B',
        ),
        _i(
          id: 'w0',
          pinTier: PinTier.watching,
          pinOrder: 0,
          lastProgressAt: older,
          title: 'A',
        ),
      ]);
      expect(pool.first.id, 'w0');
    });

    test('empty input yields empty pool', () {
      expect(buildHeroPool([]), isEmpty);
    });
  });

  group('heroIndexOf', () {
    test('finds id or defaults to 0', () {
      final pool = [
        _i(id: 'a'),
        _i(id: 'b'),
        _i(id: 'c'),
      ];
      expect(heroIndexOf(pool, 'b'), 1);
      expect(heroIndexOf(pool, 'missing'), 0);
      expect(heroIndexOf(pool, null), 0);
      expect(heroIndexOf([], 'a'), 0);
    });
  });

  group('gachaPosterSize', () {
    test('keeps ~2:3 aspect ratio', () {
      final s = gachaPosterSize(screenWidth: 1440, screenHeight: 900);
      expect(s.width / s.height, closeTo(2 / 3, 0.02));
    });

    test('desktop is wider than legacy 340/560 caps', () {
      final s = gachaPosterSize(screenWidth: 1440, screenHeight: 900);
      expect(s.width, greaterThan(360));
      expect(s.width, lessThanOrEqualTo(640));
    });

    test('respects max width 640', () {
      final s = gachaPosterSize(screenWidth: 2400, screenHeight: 1400);
      expect(s.width, lessThanOrEqualTo(640.0 + 0.5));
    });

    test('result chrome leaves room for action buttons', () {
      // Result state uses ~220 chrome so poster + buttons don't collide.
      const chrome = 220.0;
      final s = gachaPosterSize(
        screenWidth: 1440,
        screenHeight: 900,
        chromeHeight: chrome,
      );
      expect(s.height + chrome, lessThanOrEqualTo(900 + 1));
      // Poster must not consume almost all height (buttons need air).
      expect(s.height, lessThan(900 - chrome));
    });

    test('narrow phone still fits height budget', () {
      final s = gachaPosterSize(
        screenWidth: 390,
        screenHeight: 844,
        chromeHeight: 220,
      );
      expect(s.height, lessThanOrEqualTo(844 - 220 + 1));
      expect(s.width / s.height, closeTo(2 / 3, 0.02));
    });
  });

  group('heroStepIndex', () {
    test('cycles forward and backward', () {
      expect(heroStepIndex(0, 1, 3), 1);
      expect(heroStepIndex(2, 1, 3), 0);
      expect(heroStepIndex(0, -1, 3), 2);
      expect(heroStepIndex(1, -1, 3), 0);
    });

    test('no-op when length < 2', () {
      expect(heroStepIndex(0, 1, 1), 0);
      expect(heroStepIndex(0, 1, 0), 0);
    });
  });
}
