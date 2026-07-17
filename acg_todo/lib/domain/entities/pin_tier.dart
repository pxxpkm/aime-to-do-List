/// Home priority tier — two-level pin board.
enum PinTier {
  none,
  /// 正在追 — left board
  watching,
  /// 優先追 — right board
  priority;

  String get label => switch (this) {
        PinTier.none => '無',
        PinTier.watching => '正在追',
        PinTier.priority => '優先追',
      };

  String get shortBadge => switch (this) {
        PinTier.none => '',
        PinTier.watching => '追',
        PinTier.priority => '優',
      };

  bool get isPinned => this != PinTier.none;

  /// Sort rank: watching(0) < priority(1) < none(2)
  int get sortRank => switch (this) {
        PinTier.watching => 0,
        PinTier.priority => 1,
        PinTier.none => 2,
      };

  static PinTier fromStorage(String? raw, {bool? legacyIsPinned}) {
    if (raw != null) {
      for (final t in PinTier.values) {
        if (t.name == raw) return t;
      }
    }
    // Migrate old isPinned bool → watching
    if (legacyIsPinned == true) return PinTier.watching;
    return PinTier.none;
  }
}
