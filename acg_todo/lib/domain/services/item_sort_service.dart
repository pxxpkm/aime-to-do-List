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

  List<Item> sort(List<Item> input, HomeSortMode mode) {
    final list = List<Item>.from(input);
    switch (mode) {
      case HomeSortMode.manual:
        list.sort(_manual);
      case HomeSortMode.deadline:
        list.sort(_deadline);
      case HomeSortMode.updated:
        list.sort(_updated);
      case HomeSortMode.created:
        list.sort(_created);
      case HomeSortMode.title:
        list.sort(_title);
      case HomeSortMode.siteScore:
        list.sort(_siteScore);
      case HomeSortMode.myScore:
        list.sort(_myScore);
      case HomeSortMode.progress:
        list.sort(_progress);
    }
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
