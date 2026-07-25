// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Unregister Service Workers, clear Cache Storage, then hard reload.
Future<void> hardReloadApp() async {
  await clearWebAppCaches();
  html.window.location.reload();
}

Future<void> clearWebAppCaches() async {
  try {
    final sw = html.window.navigator.serviceWorker;
    if (sw != null) {
      final regs = await sw.getRegistrations();
      for (final r in regs) {
        await r.unregister();
      }
    }
  } catch (_) {}
  try {
    final cacheStorage = html.window.caches;
    if (cacheStorage != null) {
      final keys = await cacheStorage.keys();
      for (final k in keys) {
        await cacheStorage.delete(k);
      }
    }
  } catch (_) {}
}
