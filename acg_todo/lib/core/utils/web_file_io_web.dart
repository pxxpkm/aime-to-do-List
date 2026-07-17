// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<void> downloadTextFile(String filename, String content) async {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<String?> pickTextFile({String accept = '.json,application/json'}) async {
  final input = html.FileUploadInputElement()..accept = accept;
  input.click();
  await input.onChange.first;
  final file = input.files?.isNotEmpty == true ? input.files!.first : null;
  if (file == null) return null;
  final reader = html.FileReader();
  reader.readAsText(file);
  await reader.onLoad.first;
  final result = reader.result;
  return result is String ? result : null;
}
