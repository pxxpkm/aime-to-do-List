import 'package:acg_todo/domain/entities/item.dart';

enum HomeSortMode {
  manual,
  deadline,
  updated,
  created,
  title,
  siteScore,
  myScore,
  progress;

  String get label => switch (this) {
        HomeSortMode.manual => '手動',
        HomeSortMode.deadline => '限期',
        HomeSortMode.updated => '最近更新',
        HomeSortMode.created => '最近新增',
        HomeSortMode.title => '標題',
        HomeSortMode.siteScore => '站點評分',
        HomeSortMode.myScore => '我的評分',
        HomeSortMode.progress => '進度',
      };

  static HomeSortMode fromStorage(String? raw) {
    for (final m in HomeSortMode.values) {
      if (m.name == raw) return m;
    }
    return HomeSortMode.manual;
  }
}

class ItemSortService {
  const ItemSortService();

  /// [ascending] reverses non-manual mode comparison (pin tiers stay fixed).
  List<Item> sort(
    List<Item> input,
    HomeSortMode mode, {
    bool ascending = false,
  }) {
    final list = List<Item>.from(input);
    final flip = ascending && mode != HomeSortMode.manual;
    int modeCompare(Item a, Item b) => switch (mode) {
          HomeSortMode.manual => _manual(a, b),
          HomeSortMode.deadline => _deadline(a, b),
          HomeSortMode.updated => _updated(a, b),
          HomeSortMode.created => _created(a, b),
          HomeSortMode.title => _title(a, b),
          HomeSortMode.siteScore => _siteScore(a, b),
          HomeSortMode.myScore => _myScore(a, b),
          HomeSortMode.progress => _progress(a, b),
        };
    list.sort((a, b) {
      // watching → priority → none; within tier by pinOrder.
      final tr = a.pinTier.sortRank.compareTo(b.pinTier.sortRank);
      if (tr != 0) return tr;
      if (a.pinTier.isPinned && b.pinTier.isPinned) {
        final p = a.pinOrder.compareTo(b.pinOrder);
        if (p != 0) return p;
        return a.id.compareTo(b.id);
      }
      final c = modeCompare(a, b);
      return flip ? -c : c;
    });
    return list;
  }

  int _tie(Item a, Item b) {
    final o = a.sortOrder.compareTo(b.sortOrder);
    if (o != 0) return o;
    return a.id.compareTo(b.id);
  }

  int _manual(Item a, Item b) => _tie(a, b);

  int _deadline(Item a, Item b) {
    final ad = a.deadline;
    final bd = b.deadline;
    if (ad == null && bd == null) return _tie(a, b);
    if (ad == null) return 1;
    if (bd == null) return -1;
    final c = ad.compareTo(bd);
    if (c != 0) return c;
    return _tie(a, b);
  }

  int _updated(Item a, Item b) {
    final at = a.lastProgressAt ?? a.createdAt;
    final bt = b.lastProgressAt ?? b.createdAt;
    if (at == null && bt == null) return _tie(a, b);
    if (at == null) return 1;
    if (bt == null) return -1;
    final c = bt.compareTo(at);
    if (c != 0) return c;
    return _tie(a, b);
  }

  int _created(Item a, Item b) {
    final at = a.createdAt;
    final bt = b.createdAt;
    if (at == null && bt == null) return _tie(a, b);
    if (at == null) return 1;
    if (bt == null) return -1;
    final c = bt.compareTo(at);
    if (c != 0) return c;
    return _tie(a, b);
  }

  int _title(Item a, Item b) {
    final c = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    if (c != 0) return c;
    return _tie(a, b);
  }

  int _siteScore(Item a, Item b) {
    final as = a.score;
    final bs = b.score;
    if (as == null && bs == null) return _tie(a, b);
    if (as == null) return 1;
    if (bs == null) return -1;
    final c = bs.compareTo(as);
    if (c != 0) return c;
    return _tie(a, b);
  }

  int _myScore(Item a, Item b) {
    final as = a.userScore;
    final bs = b.userScore;
    if (as == null && bs == null) return _tie(a, b);
    if (as == null) return 1;
    if (bs == null) return -1;
    final c = bs.compareTo(as);
    if (c != 0) return c;
    return _tie(a, b);
  }

  int _progress(Item a, Item b) {
    final ar = _progressRatio(a);
    final br = _progressRatio(b);
    if (ar == null && br == null) {
      final c = b.currentUnits.compareTo(a.currentUnits);
      if (c != 0) return c;
      return _tie(a, b);
    }
    if (ar == null) return 1;
    if (br == null) return -1;
    final c = br.compareTo(ar);
    if (c != 0) return c;
    return _tie(a, b);
  }

  double? _progressRatio(Item item) {
    final t = item.totalUnits;
    if (t == null || t <= 0) return null;
    return item.currentUnits / t;
  }
}
