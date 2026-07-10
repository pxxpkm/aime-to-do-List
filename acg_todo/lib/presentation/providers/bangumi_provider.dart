import 'package:acg_todo/data/local/bangumi_token_store.dart';
import 'package:acg_todo/data/repositories/bangumi/bangumi_client.dart';
import 'package:acg_todo/data/repositories/bangumi/mappers.dart';
import 'package:acg_todo/domain/entities/item_category.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bangumi_provider.freezed.dart';
part 'bangumi_provider.g.dart';

@freezed
class BangumiState with _$BangumiState {
  const factory BangumiState({
    @Default(false) bool isLoading,
    @Default(false) bool isVerified,
    String? username,
    String? error,
  }) = _BangumiState;
}

@riverpod
class BangumiNotifier extends _$BangumiNotifier {
  @override
  BangumiState build() {
    final tokenStore = ref.read(bangumiTokenStoreProvider);
    final username = tokenStore.cachedUsername;
    return BangumiState(
      isVerified: tokenStore.hasToken,
      username: username,
    );
  }

  BangumiClient get _client => ref.read(bangumiClientProvider);
  BangumiTokenStore get _tokenStore => ref.read(bangumiTokenStoreProvider);

  Future<void> verifyAndSaveToken(String token) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _client.userInfo(token);
      if (user != null) {
        await _tokenStore.saveToken(token);
        await _tokenStore.saveUsername(user.nickname);
        state = state.copyWith(
          isLoading: false,
          isVerified: true,
          username: user.nickname,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '驗證失敗：請檢查 Token 是否正確',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '驗證失敗：$e',
      );
    }
  }

  Future<void> clearToken() async {
    await _tokenStore.clearToken();
    state = const BangumiState();
  }

  Future<int> importCollections(ItemCategory category) async {
    final token = _tokenStore.token;
    if (token == null) return 0;

    state = state.copyWith(isLoading: true);
    try {
      final collections = await _client.getAllCollections(token, category.bangumiType);
      final items = collections.map((c) => c.toItem('local_user')).toList();

      // 過濾已存在的
      final existingIds = ref.read(itemsNotifierProvider).map((i) => i.id).toSet();
      final newItems = items.where((i) => !existingIds.contains(i.id)).toList();

      await ref.read(itemsNotifierProvider.notifier).addItems(newItems);
      state = state.copyWith(isLoading: false);
      return newItems.length;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '匯入失敗：$e');
      return 0;
    }
  }
}
