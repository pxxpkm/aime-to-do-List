import 'package:hive_flutter/hive_flutter.dart';

import 'package:acg_todo/data/local/library_store.dart';

/// Bangumi OAuth token + username.
///
/// Default: browser Hive only.
/// Opt-in [persistToDisk]: also write into library settings bundle (SQLite)
/// so clearing site data does not drop the token when on disk library.
class BangumiTokenStore {
  static const _tokenKey = 'bangumi_token';
  static const _userKey = 'bangumi_username';
  static const _persistKey = 'bangumi_token_on_disk';
  static const _bundleAuthKey = 'bangumi_auth';

  final Box _settingsBox;

  /// When non-null and [backendId] is server, disk persist is available.
  final LibraryStore? libraryStore;

  BangumiTokenStore(this._settingsBox, {this.libraryStore});

  bool get canPersistToDisk =>
      libraryStore != null &&
      libraryStore!.backendId == LibraryBackendIds.server;

  /// User opted to store token on disk (SQLite settings bundle).
  bool get persistToDisk {
    if (!canPersistToDisk) return false;
    if (_settingsBox.get(_persistKey) == true) return true;
    final auth = _diskAuth();
    return auth != null && auth['persist'] == true;
  }

  Future<void> setPersistToDisk(bool enabled) async {
    if (!canPersistToDisk) return;
    if (enabled) {
      await _settingsBox.put(_persistKey, true);
      // Copy current Hive credentials up to disk.
      await _writeDiskAuth(
        token: token,
        username: cachedUsername,
        persist: true,
      );
    } else {
      // Keep credentials in Hive; drop disk copy.
      final t = token;
      final u = cachedUsername;
      if (t != null && t.isNotEmpty) {
        await _settingsBox.put(_tokenKey, t);
      }
      if (u != null && u.isNotEmpty) {
        await _settingsBox.put(_userKey, u);
      }
      await _settingsBox.put(_persistKey, false);
      await _clearDiskAuth();
    }
  }

  String? get token {
    if (persistToDisk) {
      final t = _diskAuth()?['token'] as String?;
      if (t != null && t.isNotEmpty) return t;
    }
    return _settingsBox.get(_tokenKey) as String?;
  }

  Future<void> saveToken(String token) async {
    await _settingsBox.put(_tokenKey, token);
    if (persistToDisk) {
      await _writeDiskAuth(
        token: token,
        username: cachedUsername,
        persist: true,
      );
    }
  }

  Future<void> clearToken() async {
    await _settingsBox.delete(_tokenKey);
    await _settingsBox.delete(_userKey);
    if (canPersistToDisk) {
      await _clearDiskAuth();
      await _settingsBox.put(_persistKey, false);
    }
  }

  bool get hasToken {
    final t = token;
    return t != null && t.isNotEmpty;
  }

  String? get cachedUsername {
    if (persistToDisk) {
      final u = _diskAuth()?['username'] as String?;
      if (u != null && u.isNotEmpty) return u;
    }
    return _settingsBox.get(_userKey) as String?;
  }

  Future<void> saveUsername(String username) async {
    await _settingsBox.put(_userKey, username);
    if (persistToDisk) {
      await _writeDiskAuth(
        token: token,
        username: username,
        persist: true,
      );
    }
  }

  Map<String, dynamic>? _diskAuth() {
    final store = libraryStore;
    if (store == null) return null;
    final raw = store.getSettingsBundle()[_bundleAuthKey];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<void> _writeDiskAuth({
    required String? token,
    required String? username,
    required bool persist,
  }) async {
    final store = libraryStore;
    if (store == null) return;
    final bundle = Map<String, dynamic>.from(store.getSettingsBundle());
    bundle[_bundleAuthKey] = {
      'persist': persist,
      'token': token ?? '',
      'username': username ?? '',
    };
    await store.putSettingsBundle(bundle);
  }

  Future<void> _clearDiskAuth() async {
    final store = libraryStore;
    if (store == null) return;
    final bundle = Map<String, dynamic>.from(store.getSettingsBundle());
    if (!bundle.containsKey(_bundleAuthKey)) return;
    bundle.remove(_bundleAuthKey);
    await store.putSettingsBundle(bundle);
  }
}
