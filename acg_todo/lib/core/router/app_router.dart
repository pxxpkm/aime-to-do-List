import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/domain/entities/pin_tier.dart';
import 'package:acg_todo/presentation/pages/batch_add_page.dart';
import 'package:acg_todo/presentation/pages/collection_page.dart';
import 'package:acg_todo/presentation/pages/dashboard_page.dart';
import 'package:acg_todo/presentation/pages/import_collection_page.dart';
import 'package:acg_todo/presentation/pages/item_detail_page.dart';
import 'package:acg_todo/presentation/pages/library_page.dart';
import 'package:acg_todo/presentation/pages/manual_entry_page.dart';
import 'package:acg_todo/presentation/pages/notifications_page.dart';
import 'package:acg_todo/presentation/pages/onboarding_page.dart';
import 'package:acg_todo/presentation/pages/pin_list_page.dart';
import 'package:acg_todo/presentation/pages/search_page.dart';
import 'package:acg_todo/presentation/pages/settings_page.dart';
import 'package:acg_todo/presentation/pages/stats_page.dart';
import 'package:acg_todo/presentation/shell/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const DashboardPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const LibraryPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/collection',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const CollectionPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const SettingsPage(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SearchPage(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: '/item/:id',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: ItemDetailPage(
            itemId: state.pathParameters['id']!,
          ),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: '/manual-entry',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ManualEntryPage(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: '/stats',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StatsPage(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotificationsPage(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingPage(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/import-collection',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ImportCollectionPage(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: '/batch-add',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BatchAddPage(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: '/pin/:tier',
        pageBuilder: (context, state) {
          final tier = PinListPage.parseTier(
                state.pathParameters['tier'],
              ) ??
              PinTier.watching;
          return CustomTransitionPage(
            key: state.pageKey,
            child: PinListPage(tier: tier),
            transitionDuration: const Duration(milliseconds: 280),
            reverseTransitionDuration: const Duration(milliseconds: 280),
            transitionsBuilder: _pinFadeTransition,
          );
        },
        redirect: (context, state) {
          final tier = PinListPage.parseTier(
            state.pathParameters['tier'],
          );
          if (tier == null) return '/';
          return null;
        },
      ),
    ],
  );
});

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
    child: child,
  );
}

/// Pin board → full list: fade only (no slide / Hero clutter).
Widget _pinFadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ),
    child: child,
  );
}
