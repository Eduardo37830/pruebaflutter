// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editor_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$editorNotifierHash() => r'e9a8150c3d6aed640d07a25e4b4344475481f0ff';

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

abstract class _$EditorNotifier
    extends BuildlessAutoDisposeAsyncNotifier<Chapter?> {
  late final String chapterLocalId;

  FutureOr<Chapter?> build(String chapterLocalId);
}

/// See also [EditorNotifier].
@ProviderFor(EditorNotifier)
const editorNotifierProvider = EditorNotifierFamily();

/// See also [EditorNotifier].
class EditorNotifierFamily extends Family<AsyncValue<Chapter?>> {
  /// See also [EditorNotifier].
  const EditorNotifierFamily();

  /// See also [EditorNotifier].
  EditorNotifierProvider call(String chapterLocalId) {
    return EditorNotifierProvider(chapterLocalId);
  }

  @override
  EditorNotifierProvider getProviderOverride(
    covariant EditorNotifierProvider provider,
  ) {
    return call(provider.chapterLocalId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'editorNotifierProvider';
}

/// See also [EditorNotifier].
class EditorNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<EditorNotifier, Chapter?> {
  /// See also [EditorNotifier].
  EditorNotifierProvider(String chapterLocalId)
    : this._internal(
        () => EditorNotifier()..chapterLocalId = chapterLocalId,
        from: editorNotifierProvider,
        name: r'editorNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$editorNotifierHash,
        dependencies: EditorNotifierFamily._dependencies,
        allTransitiveDependencies:
            EditorNotifierFamily._allTransitiveDependencies,
        chapterLocalId: chapterLocalId,
      );

  EditorNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.chapterLocalId,
  }) : super.internal();

  final String chapterLocalId;

  @override
  FutureOr<Chapter?> runNotifierBuild(covariant EditorNotifier notifier) {
    return notifier.build(chapterLocalId);
  }

  @override
  Override overrideWith(EditorNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: EditorNotifierProvider._internal(
        () => create()..chapterLocalId = chapterLocalId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        chapterLocalId: chapterLocalId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<EditorNotifier, Chapter?>
  createElement() {
    return _EditorNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EditorNotifierProvider &&
        other.chapterLocalId == chapterLocalId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, chapterLocalId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EditorNotifierRef on AutoDisposeAsyncNotifierProviderRef<Chapter?> {
  /// The parameter `chapterLocalId` of this provider.
  String get chapterLocalId;
}

class _EditorNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<EditorNotifier, Chapter?>
    with EditorNotifierRef {
  _EditorNotifierProviderElement(super.provider);

  @override
  String get chapterLocalId =>
      (origin as EditorNotifierProvider).chapterLocalId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
