/// Personal rating helpers: 0.0–10.0 in 0.1 steps.
double? roundUserScore(double? value) {
  if (value == null) return null;
  final clamped = value.clamp(0.0, 10.0);
  return (clamped * 10).round() / 10.0;
}

String formatUserScore(double score) {
  final r = roundUserScore(score) ?? 0;
  return r == r.roundToDouble()
      ? r.toInt().toString()
      : r.toStringAsFixed(1);
}
