import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_typography.dart';

/// Shell destinations (index must match StatefulShellBranch order).
class ShellDest {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;

  const ShellDest({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });
}

const kShellDestinations = <ShellDest>[
  ShellDest(
    label: '主頁',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    path: '/',
  ),
  ShellDest(
    label: '媒體庫',
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view,
    path: '/library',
  ),
  ShellDest(
    label: '收藏',
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder,
    path: '/collection',
  ),
  ShellDest(
    label: '設定',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    path: '/settings',
  ),
];

const kShellWideBreakpoint = 800.0;

/// Wide: fixed [NavigationRail]. Narrow: [Drawer] (open via menu).
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  void _go(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide =
        MediaQuery.sizeOf(context).width >= kShellWideBreakpoint;
    final index = navigationShell.currentIndex;
    final title = kShellDestinations[index.clamp(0, kShellDestinations.length - 1)]
        .label;

    return Scaffold(
      backgroundColor: AppColors.paperBg,
      drawer: wide
          ? null
          : _ShellDrawer(
              selectedIndex: index,
              onSelect: (i) {
                Navigator.of(context).pop();
                _go(i);
              },
            ),
      body: Row(
        children: [
          if (wide)
            _ShellRail(
              selectedIndex: index,
              onSelect: _go,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!wide)
                  Material(
                    color: AppColors.paperElevated,
                    child: SafeArea(
                      bottom: false,
                      child: SizedBox(
                        height: 52,
                        child: Row(
                          children: [
                            Builder(
                              builder: (ctx) => IconButton(
                                icon: const Icon(Icons.menu),
                                color: AppColors.inkSecondary,
                                onPressed: () =>
                                    Scaffold.of(ctx).openDrawer(),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                title,
                                style: AppTypography.title.copyWith(
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (!wide)
                  const Divider(height: 1, color: AppColors.borderSubtle),
                Expanded(child: navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShellRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _ShellRail({
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final extended = MediaQuery.sizeOf(context).width >= 1100;
    return Material(
      color: AppColors.paperElevated,
      child: SafeArea(
        right: false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationRail(
              extended: extended,
              minExtendedWidth: 168,
              backgroundColor: AppColors.paperElevated,
              indicatorColor: AppColors.anime.withValues(alpha: 0.14),
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(
                color: AppColors.anime,
              ),
              unselectedIconTheme: const IconThemeData(
                color: AppColors.inkSecondary,
              ),
              selectedLabelTextStyle: AppTypography.caption.copyWith(
                color: AppColors.inkPrimary,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelTextStyle: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
              ),
              destinations: [
                for (final d in kShellDestinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.borderSubtle,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _ShellDrawer({
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.paperElevated,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'ACG To-Do',
                style: AppTypography.title.copyWith(fontSize: 18),
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 8),
            for (var i = 0; i < kShellDestinations.length; i++)
              ListTile(
                leading: Icon(
                  selectedIndex == i
                      ? kShellDestinations[i].selectedIcon
                      : kShellDestinations[i].icon,
                  color: selectedIndex == i
                      ? AppColors.anime
                      : AppColors.inkSecondary,
                ),
                title: Text(
                  kShellDestinations[i].label,
                  style: AppTypography.body.copyWith(
                    fontWeight: selectedIndex == i
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: AppColors.inkPrimary,
                  ),
                ),
                selected: selectedIndex == i,
                selectedTileColor: AppColors.anime.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () => onSelect(i),
              ),
          ],
        ),
      ),
    );
  }
}
