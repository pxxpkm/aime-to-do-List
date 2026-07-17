import 'package:acg_todo/core/utils/zh_s2t_data.dart';
import 'package:acg_todo/core/utils/zh_t2s_data.dart';

/// Traditional Chinese → Simplified for Bangumi search queries.
String traditionalToSimplified(String input) {
  if (input.isEmpty) return input;
  final sb = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    sb.write(kZhTraditionalToSimplified[ch] ?? ch);
  }
  return sb.toString();
}

/// True if conversion changed the string (likely had traditional chars).
bool didConvertToSimplified(String original, String converted) =>
    original != converted;

/// Simplified Chinese → Traditional for display / storage of titles.
String simplifiedToTraditional(String input) {
  if (input.isEmpty) return input;
  final sb = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    sb.write(kZhSimplifiedToTraditional[ch] ?? ch);
  }
  return sb.toString();
}

bool didConvertToTraditional(String original, String converted) =>
    original != converted;

/// Prefer traditional form when [enabled]; otherwise return [raw].
String preferTraditionalTitle(String raw, {required bool enabled}) {
  if (!enabled || raw.isEmpty) return raw;
  return simplifiedToTraditional(raw);
}
