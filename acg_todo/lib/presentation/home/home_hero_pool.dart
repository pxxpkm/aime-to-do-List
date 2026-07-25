import 'package:acg_todo/domain/entities/item.dart';

/// Build ordered pool for home hero carousel / daily pick.
///
/// Prefers items with poster art; falls back to all items if none have art.
/// Sort: pin tier (watching → priority → none) → pinOrder → recent progress → title.
List<Item> buildHeroPool(List<Item> items) {
  final withArt = items
      .where((i) => i.posterUrl != null && i.posterUrl!.isNotEmpty)
      .toList();
  final pool =
      withArt.isNotEmpty ? List<Item>.from(withArt) : List<Item>.from(items);

  pool.sort((a, b) {
    final tr = a.pinTier.sortRank.compareTo(b.pinTier.sortRank);
    if (tr != 0) return tr;

    if (a.pinTier.isPinned && b.pinTier.isPinned) {
      final po = a.pinOrder.compareTo(b.pinOrder);
      if (po != 0) return po;
    }

    final at = a.lastProgressAt ?? a.createdAt;
    final bt = b.lastProgressAt ?? b.createdAt;
    if (at != null && bt != null) {
      final c = bt.compareTo(at); // newer first
      if (c != 0) return c;
    } else if (at != null) {
      return -1;
    } else if (bt != null) {
      return 1;
    }

    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  });

  return pool;
}

/// Index of [itemId] in [pool], or 0 if missing / empty.
int heroIndexOf(List<Item> pool, String? itemId) {
  if (pool.isEmpty) return 0;
  if (itemId == null) return 0;
  final i = pool.indexWhere((e) => e.id == itemId);
  return i >= 0 ? i : 0;
}

/// Gacha dialog poster size: height-first 2:3, immersive on desktop.
///
/// [chromeHeight] = title + gaps + action buttons + safe padding reserved
/// **outside** the card (must be large enough that buttons never sit under
/// the poster). Max width ~640.
({double width, double height}) gachaPosterSize({
  required double screenWidth,
  required double screenHeight,
  double chromeHeight = 220,
}) {
  final maxW = (screenWidth * 0.96).clamp(200.0, 640.0);
  final availableH =
      (screenHeight - chromeHeight).clamp(220.0, screenHeight);

  // Leave a little air inside the budget so shadows / borders don't crowd
  // the action row below.
  var cardH = availableH * 0.90;
  var cardW = cardH / 1.5;
  if (cardW > maxW) {
    cardW = maxW;
    cardH = cardW * 1.5;
  }
  if (cardH > availableH) {
    cardH = availableH;
    cardW = cardH / 1.5;
  }
  return (width: cardW, height: cardH);
}

/// Next index when stepping [delta] in a circular pool. Returns [current] if n < 2.
int heroStepIndex(int current, int delta, int length) {
  if (length < 2) return current.clamp(0, 0);
  var idx = current % length;
  if (idx < 0) idx += length;
  final next = (idx + delta) % length;
  return next < 0 ? next + length : next;
}
