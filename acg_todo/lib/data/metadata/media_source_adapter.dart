import 'package:acg_todo/data/metadata/source_candidate.dart';
import 'package:acg_todo/domain/entities/item_category.dart';

/// Pluggable metadata search/fetch backend.
abstract class MediaSourceAdapter {
  /// Stable key: bangumi | anilist | manual
  String get key;

  String get label;

  bool supportsCategory(ItemCategory category);

  Future<List<SourceCandidate>> search(
    String query,
    ItemCategory category, {
    String? token,
  });
}
