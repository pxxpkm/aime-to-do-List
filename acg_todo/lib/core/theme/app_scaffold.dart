import 'package:flutter/material.dart';

import 'package:acg_todo/core/theme/app_palette.dart';

/// Unified paper-background scaffold for all app pages.
///
/// Uses [context.palette] so light/dark (and future themes) switch safely.
/// Default path remains paper light when theme extension is paper_light.
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final bool extendBodyBehindAppBar;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: backgroundColor ?? p.bg,
      appBar: appBar,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: backgroundColor == null ? p.backgroundGradient : null,
          color: backgroundColor,
        ),
        child: body,
      ),
    );
  }
}
