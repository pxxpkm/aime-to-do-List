import 'package:acg_todo/data/local/bangumi_token_store.dart';
import 'package:acg_todo/data/local/goal_settings_store.dart';
import 'package:acg_todo/data/local/hive_cache.dart';
import 'package:acg_todo/data/repositories/anilist/anilist_client.dart';
import 'package:acg_todo/data/repositories/bangumi/bangumi_client.dart';
import 'package:acg_todo/data/repositories/folders_repository.dart';
import 'package:acg_todo/data/repositories/items_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aniListClientProvider = Provider<AniListClient>((ref) {
  final client = AniListClient();
  ref.onDispose(client.dispose);
  return client;
});

final bangumiClientProvider = Provider<BangumiClient>((ref) {
  return BangumiClient();
});

final goalSettingsStoreProvider = Provider<GoalSettingsStore>((ref) {
  final cache = ref.watch(hiveCacheProvider);
  return GoalSettingsStore(cache.settingsBox);
});

final itemsRepositoryProvider = Provider<ItemsRepository>((ref) {
  final cache = ref.watch(hiveCacheProvider);
  final anilist = ref.watch(aniListClientProvider);
  final goals = ref.watch(goalSettingsStoreProvider);
  return ItemsRepository(cache, anilist, goals);
});

final foldersRepositoryProvider = Provider<FoldersRepository>((ref) {
  final cache = ref.watch(hiveCacheProvider);
  return FoldersRepository(cache);
});

final bangumiTokenStoreProvider = Provider<BangumiTokenStore>((ref) {
  final cache = ref.watch(hiveCacheProvider);
  return BangumiTokenStore(cache.settingsBox);
});
