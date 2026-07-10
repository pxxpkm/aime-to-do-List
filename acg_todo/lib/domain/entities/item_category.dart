import 'package:flutter/material.dart';

import 'package:acg_todo/core/theme/app_colors.dart';

enum ItemCategory {
  anime,
  manga,
  lightNovel,
  game;

  String get label {
    switch (this) {
      case ItemCategory.anime:
        return 'Anime';
      case ItemCategory.manga:
        return 'Manga';
      case ItemCategory.lightNovel:
        return 'Light Novel';
      case ItemCategory.game:
        return 'Game';
    }
  }

  String get unitLabel {
    switch (this) {
      case ItemCategory.anime:
        return '集';
      case ItemCategory.manga:
        return '章';
      case ItemCategory.lightNovel:
        return '卷';
      case ItemCategory.game:
        return '%';
    }
  }

  String get storageKey {
    switch (this) {
      case ItemCategory.anime:
        return 'anime';
      case ItemCategory.manga:
        return 'manga';
      case ItemCategory.lightNovel:
        return 'light_novel';
      case ItemCategory.game:
        return 'game';
    }
  }

  Color get color {
    switch (this) {
      case ItemCategory.anime:
        return AppColors.anime;
      case ItemCategory.manga:
        return AppColors.manga;
      case ItemCategory.lightNovel:
        return AppColors.lightNovel;
      case ItemCategory.game:
        return AppColors.game;
    }
  }

  static ItemCategory fromStorageKey(String key) {
    return ItemCategory.values.firstWhere(
      (c) => c.storageKey == key,
      orElse: () => ItemCategory.anime,
    );
  }

  int get bangumiType => switch (this) {
    ItemCategory.anime => 2,
    ItemCategory.manga => 1,
    ItemCategory.lightNovel => 1,
    ItemCategory.game => 4,
  };
}
