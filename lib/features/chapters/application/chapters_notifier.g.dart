// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapters_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chaptersByProjectHash() => r'e4fd51c5b20e9a5cb85c1cb853562a59166eb434';

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

/// See also [chaptersByProject].
@ProviderFor(chaptersByProject)
const chaptersByProjectProvider = ChaptersByProjectFamily();

/// See also [chaptersByProject].
class ChaptersByProjectFamily extends Family<AsyncValue<List<Chapter>>> {
  /// See also [chaptersByProject].
  const ChaptersByProjectFamily();

  /// See also [chaptersByProject].
  ChaptersByProjectProvider call(String projectLocalId) {
    return ChaptersByProjectProvider(projectLocalId);
  }

  @override
  ChaptersByProjectProvider getProviderOverride(
    covariant ChaptersByProjectProvider provider,
  ) {
    return call(provider.projectLocalId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chaptersByProjectProvider';
}

/// See also [chaptersByProject].
class ChaptersByProjectProvider
    extends AutoDisposeStreamProvider<List<Chapter>> {
  /// See also [chaptersByProject].
  ChaptersByProjectProvider(String projectLocalId)
    : this._internal(
        (ref) => chaptersByProject(ref as ChaptersByProjectRef, projectLocalId),
        from: chaptersByProjectProvider,
        name: r'chaptersByProjectProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$chaptersByProjectHash,
        dependencies: ChaptersByProjectFamily._dependencies,
        allTransitiveDependencies:
            ChaptersByProjectFamily._allTransitiveDependencies,
        projectLocalId: projectLocalId,
      );

  ChaptersByProjectProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.projectLocalId,
  }) : super.internal();

  final String projectLocalId;

  @override
  Override overrideWith(
    Stream<List<Chapter>> Function(ChaptersByProjectRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChaptersByProjectProvider._internal(
        (ref) => create(ref as ChaptersByProjectRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        projectLocalId: projectLocalId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Chapter>> createElement() {
    return _ChaptersByProjectProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChaptersByProjectProvider &&
        other.projectLocalId == projectLocalId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, projectLocalId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChaptersByProjectRef on AutoDisposeStreamProviderRef<List<Chapter>> {
  /// The parameter `projectLocalId` of this provider.
  String get projectLocalId;
}

class _ChaptersByProjectProviderElement
    extends AutoDisposeStreamProviderElement<List<Chapter>>
    with ChaptersByProjectRef {
  _ChaptersByProjectProviderElement(super.provider);

  @override
  String get projectLocalId =>
      (origin as ChaptersByProjectProvider).projectLocalId;
}

String _$chaptersNotifierHash() => r'681a8fe99b331b4668473ae51d4ef1193371f194';

/// See also [ChaptersNotifier].
@ProviderFor(ChaptersNotifier)
final chaptersNotifierProvider =
    AutoDisposeNotifierProvider<ChaptersNotifier, void>.internal(
      ChaptersNotifier.new,
      name: r'chaptersNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$chaptersNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ChaptersNotifier = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
