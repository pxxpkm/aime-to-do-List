import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:acg_todo/core/router/app_router.dart';
import 'package:acg_todo/core/theme/app_theme.dart';
import 'package:acg_todo/core/utils/logger.dart';
import 'package:acg_todo/data/local/goal_settings_store.dart';
import 'package:acg_todo/data/local/hive_cache.dart';
import 'package:acg_todo/data/local/hive_library_store.dart';
import 'package:acg_todo/data/local/hive_notification_store.dart';
import 'package:acg_todo/data/local/library_backend_info.dart';
import 'package:acg_todo/data/local/library_store.dart';
import 'package:acg_todo/data/local/notification_store.dart';
import 'package:acg_todo/data/local/server_health.dart';
import 'package:acg_todo/data/local/server_library_store.dart';
import 'package:acg_todo/data/local/server_notification_store.dart';
import 'package:acg_todo/presentation/providers/notification_providers.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();

    final hiveCache = HiveCache();
    await hiveCache.init();

    final hiveNotif = HiveNotificationStore();
    await hiveNotif.init();

    // Prefer local SQLite API (8080) for items/folders/goals/notifications.
    LibraryStore libraryStore;
    ServerHealth? health = await probeLibraryServer();
    String? dbPath;
    if (health != null) {
      final server = ServerLibraryStore(baseUrl: health.baseUrl);
      try {
        await server.hydrate();
        libraryStore = server;
        dbPath = health.dbPath;
        Logger().i(
          'Library backend: server (${health.itemCount} items) '
          'db=${health.dbPath}',
        );
      } catch (e) {
        Logger().w('Server library hydrate failed, fallback Hive: $e');
        libraryStore = HiveLibraryStore(hiveCache);
        await libraryStore.hydrate();
        health = null;
      }
    } else {
      libraryStore = HiveLibraryStore(hiveCache);
      await libraryStore.hydrate();
      Logger().w(
        'Library backend: hive (no /api/health — use python proxy_server.py '
        'at http://127.0.0.1:8080 for disk library)',
      );
    }

    final GoalSettingsStore goalSettings;
    if (libraryStore.backendId == LibraryBackendIds.server) {
      goalSettings = GoalSettingsStore.server(libraryStore);
      // One-time: empty disk settings + Hive has goals → copy up.
      if (goalSettings.isEmptyBundle) {
        final hiveGoals = GoalSettingsStore.hive(hiveCache.settingsBox);
        if (!hiveGoals.isEmptyBundle) {
          final bundle = hiveGoals.exportForBackup();
          // Keep any notifications prefs already on disk.
          final prev = libraryStore.getSettingsBundle();
          if (prev['notifications'] != null) {
            bundle['notifications'] = prev['notifications'];
          }
          await libraryStore.putSettingsBundle(bundle);
          goalSettings.loadFromBundle(bundle);
          Logger().i('Migrated goal settings from Hive → SQLite');
        }
      }
    } else {
      goalSettings = GoalSettingsStore.hive(hiveCache.settingsBox);
    }

    late final NotificationStore notificationStore;
    if (libraryStore.backendId == LibraryBackendIds.server &&
        health != null) {
      final serverNotif = ServerNotificationStore(
        baseUrl: health.baseUrl,
        libraryStore: libraryStore,
      );
      try {
        await serverNotif.hydrate();
        // One-time: empty disk notifications + Hive has data → upload.
        if (serverNotif.isEmptyForMigrate && !hiveNotif.isEmptyForMigrate) {
          final events = hiveNotif.getAll();
          if (events.isNotEmpty) {
            await serverNotif.replaceAll(events);
          }
          serverNotif.loadPrefs(hiveNotif.exportPrefs());
          final bundle =
              Map<String, dynamic>.from(libraryStore.getSettingsBundle());
          bundle['notifications'] = serverNotif.exportPrefs();
          await libraryStore.putSettingsBundle(bundle);
          Logger().i(
            'Migrated notifications from Hive → SQLite '
            '(${events.length} events)',
          );
        }
        notificationStore = serverNotif;
        Logger().i(
          'Notifications backend: server '
          '(${serverNotif.getAll().length} events)',
        );
      } catch (e) {
        Logger().w('Server notifications failed, fallback Hive: $e');
        notificationStore = hiveNotif;
      }
    } else {
      notificationStore = hiveNotif;
    }

    final backendInfo = libraryStore.backendId == LibraryBackendIds.server
        ? LibraryBackendInfo(
            backendId: LibraryBackendIds.server,
            title: '磁碟庫 (SQLite)',
            detail: dbPath != null && dbPath.isNotEmpty
                ? dbPath
                : 'http://127.0.0.1:8080',
            dbPath: dbPath,
          )
        : const LibraryBackendInfo(
            backendId: LibraryBackendIds.hive,
            title: '瀏覽器 (Hive)',
            detail: '清站資料會丟失作品與目標',
          );

    if (!kIsWeb) {
      try {
        await Firebase.initializeApp();
        Logger().i('Firebase initialized');
      } catch (e) {
        Logger().w('Firebase init skipped: $e');
      }
    }

    final supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
    final supabaseKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
    if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseKey,
      );
      Logger().i('Supabase initialized');
    } else {
      Logger().w('Supabase not configured — offline mode');
    }

    Logger().i('App initialized (${backendInfo.title})');

    runApp(
      ProviderScope(
        overrides: [
          hiveCacheProvider.overrideWithValue(hiveCache),
          notificationCacheProvider.overrideWithValue(notificationStore),
          libraryStoreProvider.overrideWithValue(libraryStore),
          goalSettingsStoreProvider.overrideWithValue(goalSettings),
          libraryBackendInfoProvider.overrideWithValue(backendInfo),
        ],
        child: const AcgTodoApp(),
      ),
    );
  } catch (e, st) {
    Logger().e('Bootstrap failed: $e\n$st');
    runApp(BootstrapErrorApp(error: e, stackTrace: st));
  }
}

/// Shown when Hive/bootstrap fails so users never get a silent white screen.
class BootstrapErrorApp extends StatelessWidget {
  final Object error;
  final StackTrace stackTrace;

  const BootstrapErrorApp({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF6F1E8),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(
              '啟動失敗\n\n'
              '若剛升級過 App，可嘗試：\n'
              '1. 無痕模式開啟，或\n'
              '2. 清除本站資料後重新整理\n'
              '   (F12 → Application → Clear site data)\n\n'
              '錯誤：\n$error\n\n$stackTrace',
              style: const TextStyle(
                color: Color(0xFF2C2416),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AcgTodoApp extends ConsumerStatefulWidget {
  const AcgTodoApp({super.key});

  @override
  ConsumerState<AcgTodoApp> createState() => _AcgTodoAppState();
}

class _AcgTodoAppState extends ConsumerState<AcgTodoApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runReminderCheck();
    }
  }

  Future<void> _initNotifications() async {
    try {
      final scheduler = ref.read(notificationSchedulerProvider);
      await scheduler.initialize();
      await _runReminderCheck();
    } catch (e) {
      Logger().w('Notification init skipped: $e');
    }
  }

  Future<void> _runReminderCheck() async {
    try {
      await ref.read(notificationsNotifierProvider.notifier).runCheck();
    } catch (e) {
      Logger().w('Reminder check skipped: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ACG To-Do',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
