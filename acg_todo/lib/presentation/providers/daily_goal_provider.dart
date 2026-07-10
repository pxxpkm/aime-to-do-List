import 'package:acg_todo/domain/services/multi_goal_service.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final multiGoalServiceProvider = Provider<MultiGoalService>((ref) {
  return const MultiGoalService();
});

/// Bumps when goal settings or progress change.
final dailyGoalTickProvider = StateProvider<int>((ref) => 0);

final multiGoalProvider = Provider<MultiGoalSnapshot>((ref) {
  ref.watch(dailyGoalTickProvider);
  final items = ref.watch(itemsNotifierProvider);
  final store = ref.watch(goalSettingsStoreProvider);
  return ref.watch(multiGoalServiceProvider).build(
        items: items,
        store: store,
      );
});

/// Settings: daily target only.
final dailyGoalUnitsSettingProvider = Provider<int>((ref) {
  ref.watch(dailyGoalTickProvider);
  return ref.watch(goalSettingsStoreProvider).goalUnits;
});
