import 'package:acg_todo/data/local/library_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UI-facing description of where the library is stored.
class LibraryBackendInfo {
  final String backendId;
  final String title;
  final String detail;
  final String? dbPath;

  const LibraryBackendInfo({
    required this.backendId,
    required this.title,
    required this.detail,
    this.dbPath,
  });

  bool get isServer => backendId == LibraryBackendIds.server;
}

final libraryBackendInfoProvider = Provider<LibraryBackendInfo>((ref) {
  throw UnimplementedError('Override libraryBackendInfoProvider in main');
});
