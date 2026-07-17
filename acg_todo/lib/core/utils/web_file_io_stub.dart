/// Non-web stubs.
Future<void> downloadTextFile(String filename, String content) async {
  throw UnsupportedError('File download is only supported on Web');
}

Future<String?> pickTextFile({String accept = '.json,application/json'}) async {
  throw UnsupportedError('File pick is only supported on Web');
}
