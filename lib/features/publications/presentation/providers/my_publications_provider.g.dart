// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_publications_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$publicationsRemoteDatasourceHash() =>
    r'c8ac75a2ef3f611e0891382857c4364e02950908';

/// See also [publicationsRemoteDatasource].
@ProviderFor(publicationsRemoteDatasource)
final publicationsRemoteDatasourceProvider =
    AutoDisposeProvider<PublicationsRemoteDatasource>.internal(
      publicationsRemoteDatasource,
      name: r'publicationsRemoteDatasourceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$publicationsRemoteDatasourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PublicationsRemoteDatasourceRef =
    AutoDisposeProviderRef<PublicationsRemoteDatasource>;
String _$publicationImageDatasourceHash() =>
    r'f14aad8322c16031a89601cc909bb7d73cab7eeb';

/// See also [publicationImageDatasource].
@ProviderFor(publicationImageDatasource)
final publicationImageDatasourceProvider =
    AutoDisposeProvider<PublicationImageDatasource>.internal(
      publicationImageDatasource,
      name: r'publicationImageDatasourceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$publicationImageDatasourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PublicationImageDatasourceRef =
    AutoDisposeProviderRef<PublicationImageDatasource>;
String _$publicationsRepositoryHash() =>
    r'0ad601099924c8a501914eb26cf4a9961c36c1ba';

/// See also [publicationsRepository].
@ProviderFor(publicationsRepository)
final publicationsRepositoryProvider =
    AutoDisposeProvider<PublicationsRepository>.internal(
      publicationsRepository,
      name: r'publicationsRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$publicationsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PublicationsRepositoryRef =
    AutoDisposeProviderRef<PublicationsRepository>;
String _$publicationDetailHash() => r'2bdb074cf73d3a40e45a6d6b3b78ae1b0b8857de';

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

/// See also [publicationDetail].
@ProviderFor(publicationDetail)
const publicationDetailProvider = PublicationDetailFamily();

/// See also [publicationDetail].
class PublicationDetailFamily extends Family<AsyncValue<Publication>> {
  /// See also [publicationDetail].
  const PublicationDetailFamily();

  /// See also [publicationDetail].
  PublicationDetailProvider call(String id) {
    return PublicationDetailProvider(id);
  }

  @override
  PublicationDetailProvider getProviderOverride(
    covariant PublicationDetailProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'publicationDetailProvider';
}

/// See also [publicationDetail].
class PublicationDetailProvider extends AutoDisposeFutureProvider<Publication> {
  /// See also [publicationDetail].
  PublicationDetailProvider(String id)
    : this._internal(
        (ref) => publicationDetail(ref as PublicationDetailRef, id),
        from: publicationDetailProvider,
        name: r'publicationDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$publicationDetailHash,
        dependencies: PublicationDetailFamily._dependencies,
        allTransitiveDependencies:
            PublicationDetailFamily._allTransitiveDependencies,
        id: id,
      );

  PublicationDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<Publication> Function(PublicationDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PublicationDetailProvider._internal(
        (ref) => create(ref as PublicationDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Publication> createElement() {
    return _PublicationDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PublicationDetailProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PublicationDetailRef on AutoDisposeFutureProviderRef<Publication> {
  /// The parameter `id` of this provider.
  String get id;
}

class _PublicationDetailProviderElement
    extends AutoDisposeFutureProviderElement<Publication>
    with PublicationDetailRef {
  _PublicationDetailProviderElement(super.provider);

  @override
  String get id => (origin as PublicationDetailProvider).id;
}

String _$myPublicationsNotifierHash() =>
    r'6acdc1e4ff7820fe4f98bf75842f6f67ddb39e89';

/// See also [MyPublicationsNotifier].
@ProviderFor(MyPublicationsNotifier)
final myPublicationsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      MyPublicationsNotifier,
      List<PublicationSummaryItem>
    >.internal(
      MyPublicationsNotifier.new,
      name: r'myPublicationsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$myPublicationsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MyPublicationsNotifier =
    AutoDisposeAsyncNotifier<List<PublicationSummaryItem>>;
String _$publicationFormNotifierHash() =>
    r'a4e1271c5b096336dd608f324fd32a99df7b8659';

/// See also [PublicationFormNotifier].
@ProviderFor(PublicationFormNotifier)
final publicationFormNotifierProvider =
    AutoDisposeAsyncNotifierProvider<PublicationFormNotifier, void>.internal(
      PublicationFormNotifier.new,
      name: r'publicationFormNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$publicationFormNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PublicationFormNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
