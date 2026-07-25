// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'items_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$searchMediaHash() => r'9b45869febc558d3e513a1c3fdcf4137207244ea';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [searchMedia].
@ProviderFor(searchMedia)
const searchMediaProvider = SearchMediaFamily();

/// See also [searchMedia].
class SearchMediaFamily extends Family<AsyncValue<List<SourceCandidate>>> {
  /// See also [searchMedia].
  const SearchMediaFamily();

  /// See also [searchMedia].
  SearchMediaProvider call(
    String query,
    ItemCategory category,
    MediaSource source,
  ) {
    return SearchMediaProvider(query, category, source);
  }

  @override
  SearchMediaProvider getProviderOverride(
    covariant SearchMediaProvider provider,
  ) {
    return call(provider.query, provider.category, provider.source);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'searchMediaProvider';
}

/// See also [searchMedia].
class SearchMediaProvider
    extends AutoDisposeFutureProvider<List<SourceCandidate>> {
  /// See also [searchMedia].
  SearchMediaProvider(String query, ItemCategory category, MediaSource source)
    : this._internal(
        (ref) => searchMedia(ref as SearchMediaRef, query, category, source),
        from: searchMediaProvider,
        name: r'searchMediaProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$searchMediaHash,
        dependencies: SearchMediaFamily._dependencies,
        allTransitiveDependencies: SearchMediaFamily._allTransitiveDependencies,
        query: query,
        category: category,
        source: source,
      );

  SearchMediaProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
    required this.category,
    required this.source,
  }) : super.internal();

  final String query;
  final ItemCategory category;
  final MediaSource source;

  @override
  Override overrideWith(
    FutureOr<List<SourceCandidate>> Function(SearchMediaRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchMediaProvider._internal(
        (ref) => create(ref as SearchMediaRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
        category: category,
        source: source,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<SourceCandidate>> createElement() {
    return _SearchMediaProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchMediaProvider &&
        other.query == query &&
        other.category == category &&
        other.source == source;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);
    hash = _SystemHash.combine(hash, source.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SearchMediaRef on AutoDisposeFutureProviderRef<List<SourceCandidate>> {
  /// The parameter `query` of this provider.
  String get query;

  /// The parameter `category` of this provider.
  ItemCategory get category;

  /// The parameter `source` of this provider.
  MediaSource get source;
}

class _SearchMediaProviderElement
    extends AutoDisposeFutureProviderElement<List<SourceCandidate>>
    with SearchMediaRef {
  _SearchMediaProviderElement(super.provider);

  @override
  String get query => (origin as SearchMediaProvider).query;
  @override
  ItemCategory get category => (origin as SearchMediaProvider).category;
  @override
  MediaSource get source => (origin as SearchMediaProvider).source;
}

String _$itemsNotifierHash() => r'd3ddc85791c64acb79825d763274061f88619c13';

/// See also [ItemsNotifier].
@ProviderFor(ItemsNotifier)
final itemsNotifierProvider =
    AutoDisposeNotifierProvider<ItemsNotifier, List<Item>>.internal(
      ItemsNotifier.new,
      name: r'itemsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$itemsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ItemsNotifier = AutoDisposeNotifier<List<Item>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
