import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:acg_todo/data/local/bangumi_token_store.dart';
import 'package:acg_todo/data/local/library_store.dart';
import 'package:acg_todo/domain/entities/folder.dart';
import 'package:acg_todo/domain/entities/item.dart';

class _FakeLibraryStore implements LibraryStore {
  Map<String, dynamic> bundle = {};

  @override
  String get backendId => LibraryBackendIds.server;

  @override
  Future<void> hydrate() async {}

  @override
  List<Item> getAllItems() => [];

  @override
  Item? getItem(String id) => null;

  @override
  int nextSortOrder() => 0;

  @override
  Future<void> putItem(Item item) async {}

  @override
  Future<void> putItems(List<Item> items) async {}

  @override
  Future<void> deleteItem(String id) async {}

  @override
  Future<void> clearAllItems() async {}

  @override
  List<Folder> getAllFolders() => [];

  @override
  Folder? getFolder(String id) => null;

  @override
  int nextFolderSortOrder() => 0;

  @override
  Future<void> putFolder(Folder folder) async {}

  @override
  Future<void> putFolders(List<Folder> folders) async {}

  @override
  Future<void> deleteFolder(String id) async {}

  @override
  Future<void> replaceLibrary({
    required List<Folder> folders,
    required List<Item> items,
  }) async {}

  @override
  Map<String, dynamic> getSettingsBundle() =>
      Map<String, dynamic>.from(bundle);

  @override
  Future<void> putSettingsBundle(Map<String, dynamic> next) async {
    bundle = Map<String, dynamic>.from(next);
  }
}

void main() {
  late Box box;
  late BangumiTokenStore store;
  late _FakeLibraryStore library;

  setUp(() async {
    Hive.init('./.dart_tool/test_hive_bgm_token');
    box = await Hive.openBox(
      'bgm_token_${DateTime.now().microsecondsSinceEpoch}',
    );
    library = _FakeLibraryStore();
    store = BangumiTokenStore(box, libraryStore: library);
  });

  tearDown(() async {
    await box.clear();
    await box.close();
  });

  test('default hive-only token', () async {
    expect(store.persistToDisk, isFalse);
    await store.saveToken('abc');
    await store.saveUsername('user1');
    expect(store.token, 'abc');
    expect(store.cachedUsername, 'user1');
    expect(library.bundle['bangumi_auth'], isNull);
  });

  test('opt-in copies token to disk bundle', () async {
    await store.saveToken('secret');
    await store.saveUsername('neo');
    await store.setPersistToDisk(true);
    expect(store.persistToDisk, isTrue);
    final auth = library.bundle['bangumi_auth'] as Map;
    expect(auth['token'], 'secret');
    expect(auth['username'], 'neo');
    expect(auth['persist'], isTrue);
  });

  test('opt-out clears disk but keeps hive', () async {
    await store.saveToken('secret');
    await store.setPersistToDisk(true);
    await store.setPersistToDisk(false);
    expect(store.persistToDisk, isFalse);
    expect(library.bundle.containsKey('bangumi_auth'), isFalse);
    expect(store.token, 'secret');
  });

  test('save while persist updates disk', () async {
    await store.setPersistToDisk(true);
    await store.saveToken('t2');
    await store.saveUsername('u2');
    final auth = library.bundle['bangumi_auth'] as Map;
    expect(auth['token'], 't2');
    expect(auth['username'], 'u2');
  });
}
