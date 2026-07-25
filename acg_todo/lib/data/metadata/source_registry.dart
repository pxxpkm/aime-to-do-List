import 'package:acg_todo/data/metadata/media_source_adapter.dart';
import 'package:acg_todo/data/metadata/source_candidate.dart';
import 'package:acg_todo/domain/entities/item_category.dart';

/// Registry of [MediaSourceAdapter]s. Add a source by registering only.
class SourceRegistry {
  final List<MediaSourceAdapter> _adapters;

  SourceRegistry(List<MediaSourceAdapter> adapters)
      : _adapters = List.unmodifiable(adapters);

  List<MediaSourceAdapter> get all => _adapters;

  MediaSourceAdapter? byKey(String key) {
    for (final a in _adapters) {
      if (a.key == key) return a;
    }
    return null;
  }

  List<MediaSourceAdapter> forCategory(ItemCategory category) =>
      _adapters.where((a) => a.supportsCategory(category)).toList();

  Future<List<SourceCandidate>> search(
    String key,
    String query,
    ItemCategory category, {
    String? token,
  }) async {
    final adapter = byKey(key);
    if (adapter == null) return [];
    if (!adapter.supportsCategory(category)) return [];
    final q = query.trim();
    if (q.isEmpty) return [];
    return adapter.search(q, category, token: token);
  }
}
