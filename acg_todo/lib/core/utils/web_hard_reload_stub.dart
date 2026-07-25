/// Non-web: no-op (callers should fall back to Navigator / restart).
Future<void> hardReloadApp() async {}

/// Unregister SW + clear Cache API only (no navigation).
Future<void> clearWebAppCaches() async {}
