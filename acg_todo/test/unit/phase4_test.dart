import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/services/deadline_service.dart';
import 'package:acg_todo/domain/services/reminder_service.dart';
import 'package:acg_todo/domain/services/reminder_types.dart';
import 'package:acg_todo/presentation/home/home_layout.dart';
import 'package:acg_todo/domain/entities/folder.dart';

void main() {
  group('ReminderTypes offsets', () {
    test('parse and encode', () {
      expect(ReminderTypes.parseOffsets('7,3,1,0'), [7, 3, 1, 0]);
      expect(ReminderTypes.encodeOffsets([0, 3, 3, 7]), '7,3,0');
    });
  });

  group('shouldRemind custom offsets', () {
    const service = DeadlineService();
    final item = Item(
      id: 'x',
      userId: 'u',
      type: 'anime',
      title: 'T',
      deadline: DateTime(2026, 7, 17),
    );

    test('fires on matching day only', () {
      final now = DateTime(2026, 7, 10); // 7 days left
      expect(
        service.shouldRemind(item, offsets: [7, 3, 0], now: now),
        'deadline_d7',
      );
      expect(
        service.shouldRemind(item, offsets: [3, 1, 0], now: now),
        isNull,
      );
    });
  });

  group('ReminderService collect', () {
    const service = ReminderService();

    test('uses global offsets', () {
      final now = DateTime(2026, 7, 10);
      final items = [
        Item(
          id: 'a',
          userId: 'u',
          type: 'anime',
          title: 'A',
          deadline: DateTime(2026, 7, 17),
        ),
      ];
      final list = service.collect(
        items: items,
        goalUnits: 5,
        todayUnits: 5,
        staleDays: 7,
        globalDeadlineOffsets: [7, 0],
        includeOverdue: true,
        enabled: (_) => true,
        now: now,
      );
      expect(list.single.type, 'deadline_d7');
    });

    test('custom mode and off', () {
      final now = DateTime(2026, 7, 10);
      final custom = Item(
        id: 'c',
        userId: 'u',
        type: 'anime',
        title: 'C',
        deadline: DateTime(2026, 7, 17),
        deadlineRemindMode: 'custom',
        customDeadlineOffsets: '14',
      );
      final off = custom.copyWith(id: 'o', deadlineRemindMode: 'off');
      final list = service.collect(
        items: [custom, off],
        goalUnits: 5,
        todayUnits: 5,
        staleDays: 7,
        globalDeadlineOffsets: [7, 0],
        includeOverdue: true,
        enabled: (_) => true,
        now: now,
      );
      expect(list, isEmpty);
    });
  });

  group('homeGridLayout', () {
    test('compact denser than large; poster ratio', () {
      final c = homeGridLayout('compact');
      final l = homeGridLayout('large');
      expect(c.aspectRatio, closeTo(0.67, 0.01));
      expect(c.columns(400), 2);
      expect(c.columns(900), greaterThan(l.columns(900)));
    });
  });

  group('buildHomeCells', () {
    test('folders first then uncategorized', () {
      final folders = [
        Folder(id: 'f1', name: '冬番', sortOrder: 0),
      ];
      final items = [
        Item(
          id: 'i1',
          userId: 'u',
          type: 'anime',
          title: 'In',
          folderId: 'f1',
        ),
        Item(
          id: 'i2',
          userId: 'u',
          type: 'anime',
          title: 'Out',
        ),
      ];
      final cells = buildHomeCells(allItems: items, folders: folders);
      expect(cells.length, 2);
      expect(cells[0], isA<FolderHomeCell>());
      expect(cells[1], isA<ItemHomeCell>());
    });
  });
}
