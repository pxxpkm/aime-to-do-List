/// Stub for non-web platforms.
class WebBrowserNotification {
  static String get permission => 'unsupported';

  static Future<String> requestPermission() async => 'unsupported';

  static bool get isSupported => false;

  static void show({
    required String title,
    required String body,
    String? tag,
  }) {}
}
