import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/services/item_sort_service.dart';

Item _item({
  required String id,
  int sortOrder = 0,
  String title = 't',
  DateTime? deadline,
  DateTime? createdAt,
  DateTime? lastProgressAt,
  double? score,
  double? userScore,
  int current = 0,
  int? total,
}) {
  return Item(
    id: id,
    userId: 'u',
    type: 'anime',
    title: title,
    sortOrder: sortOrder,
    deadline: deadline,
    createdAt: createdAt,
    lastProgressAt: lastProgressAt,
    score: score,
    userScore: userScore,
    currentUnits: current,
    totalUnits: total,
  );
}

void main() {
  const sorter = ItemSortService();

  test('manual uses sortOrder', () {
    final list = sorter.sort([
      _item(id: 'b', sortOrder: 2),
      _item(id: 'a', sortOrder: 0),
      _item(id: 'c', sortOrder: 1),
    ], HomeSortMode.manual);
    expect(list.map((e) => e.id), ['a', 'c', 'b']);
  });

  test('deadline nulls last, earlier first', () {
    final list = sorter.sort([
      _item(id: 'n'),
      _item(id: 'late', deadline: DateTime(2026, 8, 1)),
      _item(id: 'soon', deadline: DateTime(2026, 7, 11)),
    ], HomeSortMode.deadline);
    expect(list.map((e) => e.id), ['soon', 'late', 'n']);
  });

  test('myScore nulls last, higher first', () {
    final list = sorter.sort([
      _item(id: 'n'),
      _item(id: 'low', userScore: 5),
      _item(id: 'high', userScore: 9.5),
    ], HomeSortMode.myScore);
    expect(list.map((e) => e.id), ['high', 'low', 'n']);
  });

  test('progress ratio desc; no total uses current', () {
    final list = sorter.sort([
      _item(id: 'half', current: 5, total: 10),
      _item(id: 'full', current: 10, total: 10),
      _item(id: 'nototal', current: 99),
    ], HomeSortMode.progress);
    expect(list.first.id, 'full');
    expect(list.last.id, 'nototal');
  });

  test('title case-insensitive', () {
    final list = sorter.sort([
      _item(id: '1', title: 'zeta'),
      _item(id: '2', title: 'Alpha'),
    ], HomeSortMode.title);
    expect(list.map((e) => e.id), ['2', '1']);
  });

  test('title ascending flips to Z first when ascending true', () {
    final desc = sorter.sort([
      _item(id: '1', title: 'zeta'),
      _item(id: '2', title: 'Alpha'),
    ], HomeSortMode.title);
    final asc = sorter.sort([
      _item(id: '1', title: 'zeta'),
      _item(id: '2', title: 'Alpha'),
    ], HomeSortMode.title, ascending: true);
    expect(desc.map((e) => e.id), ['2', '1']);
    expect(asc.map((e) => e.id), ['1', '2']);
  });

  test('manual ignores ascending flag', () {
    final list = sorter.sort([
      _item(id: 'b', sortOrder: 2),
      _item(id: 'a', sortOrder: 0),
    ], HomeSortMode.manual, ascending: true);
    expect(list.map((e) => e.id), ['a', 'b']);
  });
}
