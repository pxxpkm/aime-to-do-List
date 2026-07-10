import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/data/local/hive_cache.dart';
import 'package:acg_todo/domain/services/deadline_service.dart';

void main() {
  group('Integration: Add → Update → Complete flow', () {
    late Directory tempDir;
    late HiveCache cache;
    late DeadlineService deadlineService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
      cache = HiveCache();
      await cache.init();
      deadlineService = DeadlineService();
    });

    tearDown(() async {
      await cache.clearAll();
      await Hive.deleteFromDisk();
      await tempDir.delete(recursive: true);
    });

    test('full item lifecycle: add → update progress → mark complete', () async {
      // 1. Add item
      final item = Item(
        id: 'test_flow_1',
        userId: 'user_1',
        type: 'anime',
        title: 'Spy x Family',
        totalUnits: 12,
        currentUnits: 0,
        unitLabel: '集',
        deadline: DateTime.now().add(const Duration(days: 7)),
      );
      await cache.putItem(item);

      var stored = cache.getItem('test_flow_1');
      expect(stored, isNotNull);
      expect(stored!.currentUnits, 0);

      // 2. Update progress
      final updated1 = stored.copyWith(currentUnits: 3);
      await cache.putItem(updated1);

      stored = cache.getItem('test_flow_1');
      expect(stored!.currentUnits, 3);

      // 3. Progress to final episode
      final updated2 = stored.copyWith(
        currentUnits: 12,
        completedAt: DateTime.now(),
      );
      await cache.putItem(updated2);

      stored = cache.getItem('test_flow_1');
      expect(stored!.currentUnits, 12);
      expect(stored.completedAt, isNotNull);

      // 4. Verify deadline info
      final info = deadlineService.analyze(stored);
      expect(info.status, DeadlineStatus.onTrack);
    });

    test('items persist across cache reopens', () async {
      final item = Item(
        id: 'persist_test',
        userId: 'user_1',
        type: 'manga',
        title: 'One Piece',
        totalUnits: 100,
        currentUnits: 42,
        unitLabel: '章',
      );
      await cache.putItem(item);

      // Reopen cache
      final cache2 = HiveCache();
      await cache2.init();

      final stored = cache2.getItem('persist_test');
      expect(stored, isNotNull);
      expect(stored!.title, 'One Piece');
      expect(stored.currentUnits, 42);
    });

    test('filter items by type', () async {
      final items = [
        Item(id: '1', userId: 'u', type: 'anime', title: 'A1'),
        Item(id: '2', userId: 'u', type: 'anime', title: 'A2'),
        Item(id: '3', userId: 'u', type: 'manga', title: 'M1'),
        Item(id: '4', userId: 'u', type: 'game', title: 'G1'),
      ];
      for (final i in items) {
        await cache.putItem(i);
      }

      final anime = cache.getItemsByType('anime');
      expect(anime.length, 2);

      final manga = cache.getItemsByType('manga');
      expect(manga.length, 1);

      final all = cache.getAllItems();
      expect(all.length, 4);
    });

    test('delete item removes it from cache', () async {
      final item = Item(id: 'del_test', userId: 'u', type: 'anime', title: 'Delete Me');
      await cache.putItem(item);

      expect(cache.getItem('del_test'), isNotNull);

      await cache.deleteItem('del_test');

      expect(cache.getItem('del_test'), isNull);
    });
  });
}
