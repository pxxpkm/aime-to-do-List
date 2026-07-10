import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:acg_todo/core/router/app_router.dart';
import 'package:acg_todo/core/theme/app_theme.dart';
import 'package:acg_todo/core/utils/logger.dart';
import 'package:acg_todo/data/local/hive_cache.dart';
import 'package:acg_todo/data/local/notification_cache.dart';
import 'package:acg_todo/presentation/providers/notification_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();

    final hiveCache = HiveCache();
    await hiveCache.init();

    final notificationCache = NotificationCache();
    await notificationCache.init();

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

    Logger().i('App initialized');

    runApp(
      ProviderScope(
        overrides: [
          hiveCacheProvider.overrideWithValue(hiveCache),
          notificationCacheProvider.overrideWithValue(notificationCache),
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
        backgroundColor: const Color(0xFF1a1a2e),
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
                color: Color(0xFFf8f9fa),
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
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
