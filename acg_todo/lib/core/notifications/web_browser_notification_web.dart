import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Browser Notification API wrapper (Flutter Web).
class WebBrowserNotification {
  static bool get isSupported {
    try {
      web.Notification.permission;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 'default' | 'granted' | 'denied' | 'unsupported'
  static String get permission {
    try {
      return web.Notification.permission;
    } catch (_) {
      return 'unsupported';
    }
  }

  static Future<String> requestPermission() async {
    try {
      final jsResult = await web.Notification.requestPermission().toDart;
      return jsResult.toDart;
    } catch (_) {
      return 'denied';
    }
  }

  static void show({
    required String title,
    required String body,
    String? tag,
  }) {
    try {
      if (permission != 'granted') return;
      final options = web.NotificationOptions(
        body: body,
        tag: tag ?? '',
      );
      web.Notification(title, options);
    } catch (_) {
      // Soft-fail: in-app center still works
    }
  }
}
