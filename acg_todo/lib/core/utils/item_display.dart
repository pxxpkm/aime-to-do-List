import 'package:acg_todo/core/utils/zh_convert.dart';
import 'package:acg_todo/domain/entities/item.dart';

/// Display helpers for item fields (e.g. title S2T).
String displayTitle(String title, {required bool simpToTrad}) {
  return preferTraditionalTitle(title, enabled: simpToTrad);
}

/// Normalize title fields when adding from APIs.
Item applyTitleS2t(Item item, {required bool enabled}) {
  if (!enabled) return item;
  return item.copyWith(
    title: simplifiedToTraditional(item.title),
    originalTitle: item.originalTitle != null
        ? simplifiedToTraditional(item.originalTitle!)
        : null,
  );
}
