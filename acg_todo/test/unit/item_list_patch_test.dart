import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/domain/entities/item.dart';

/// Mirrors ItemsNotifier patch helpers without Riverpod.
List<Item> patchId(List<Item> state, Item? item, String id) {
  if (item == null) {
    return [for (final e in state) if (e.id != id) e];
  }
  final idx = state.indexWhere((e) => e.id == id);
  if (idx < 0) return [...state, item];
  final next = List<Item>.of(state);
  next[idx] = item;
  return next;
}

List<Item> removeIds(List<Item> state, Iterable<String> ids) {
  final set = ids.toSet();
  return [for (final e in state) if (!set.contains(e.id)) e];
}

Item _i(String id, {int units = 0}) => Item(
      id: id,
      userId: 'u',
      type: 'anime',
      title: id,
      currentUnits: units,
    );

void main() {
  test('patch upserts existing and appends new', () {
    var state = [_i('a', units: 1), _i('b', units: 2)];
    state = patchId(state, _i('a', units: 5), 'a');
    expect(state.firstWhere((e) => e.id == 'a').currentUnits, 5);
    expect(state.length, 2);

    state = patchId(state, _i('c', units: 0), 'c');
    expect(state.map((e) => e.id), ['a', 'b', 'c']);
  });

  test('patch null removes', () {
    var state = [_i('a'), _i('b')];
    state = patchId(state, null, 'a');
    expect(state.map((e) => e.id), ['b']);
  });

  test('removeIds batch', () {
    final state = removeIds([_i('a'), _i('b'), _i('c')], ['a', 'c']);
    expect(state.map((e) => e.id), ['b']);
  });
}
