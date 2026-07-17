import 'package:acg_todo/data/local/bangumi_token_store.dart';
import 'package:acg_todo/data/local/goal_settings_store.dart';
import 'package:acg_todo/data/local/hive_cache.dart';
import 'package:acg_todo/data/local/library_store.dart';
import 'package:acg_todo/data/repositories/anilist/anilist_client.dart';
import 'package:acg_todo/data/repositories/bangumi/bangumi_client.dart';
import 'package:acg_todo/data/repositories/folders_repository.dart';
import 'package:acg_todo/data/repositories/items_repository.dart';
import 'package:acg_todo/data/repositories/library_backup_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aniListClientProvider = Provider<AniListClient>((ref) {
  final client = AniListClient();
  ref.onDispose(client.dispose);
  return client;
});

final bangumiClientProvider = Provider<BangumiClient>((ref) {
  return BangumiClient();
});

/// Overridden in main (hive or server). Fallback for tests without override.
final goalSettingsStoreProvider = Provider<GoalSettingsStore>((ref) {
  final cache = ref.watch(hiveCacheProvider);
  return GoalSettingsStore.hive(cache.settingsBox);
});

final itemsRepositoryProvider = Provider<ItemsRepository>((ref) {
  final store = ref.watch(libraryStoreProvider);
  final anilist = ref.watch(aniListClientProvider);
  final goals = ref.watch(goalSettingsStoreProvider);
  return ItemsRepository(store, anilist, goals);
});

final foldersRepositoryProvider = Provider<FoldersRepository>((ref) {
  final store = ref.watch(libraryStoreProvider);
  return FoldersRepository(store);
});

final bangumiTokenStoreProvider = Provider<BangumiTokenStore>((ref) {
  final cache = ref.watch(hiveCacheProvider);
  return BangumiTokenStore(cache.settingsBox);
});

final libraryBackupRepositoryProvider = Provider<LibraryBackupRepository>((ref) {
  final store = ref.watch(libraryStoreProvider);
  final goals = ref.watch(goalSettingsStoreProvider);
  return LibraryBackupRepository(store, goals);
});

/// True when items/folders are backed by local SQLite API.
final isServerLibraryProvider = Provider<bool>((ref) {
  return ref.watch(libraryStoreProvider).backendId == LibraryBackendIds.server;
});
