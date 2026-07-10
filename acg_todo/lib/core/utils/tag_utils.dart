/// Free-form tag normalization.
const int kMaxTagLength = 24;
const int kMaxTagsPerItem = 20;

List<String> normalizeTags(Iterable<String> raw) {
  final seen = <String>{};
  final out = <String>[];
  for (final t in raw) {
    var s = t.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (s.isEmpty) continue;
    if (s.length > kMaxTagLength) s = s.substring(0, kMaxTagLength);
    if (seen.contains(s)) continue;
    seen.add(s);
    out.add(s);
    if (out.length >= kMaxTagsPerItem) break;
  }
  return out;
}
