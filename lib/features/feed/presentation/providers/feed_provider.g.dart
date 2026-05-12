// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$feedRemoteDatasourceHash() =>
    r'266e0484d4423a1565a6c67fba8a8fe2b3b10216';

/// See also [feedRemoteDatasource].
@ProviderFor(feedRemoteDatasource)
final feedRemoteDatasourceProvider =
    AutoDisposeProvider<FeedRemoteDatasource>.internal(
      feedRemoteDatasource,
      name: r'feedRemoteDatasourceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$feedRemoteDatasourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeedRemoteDatasourceRef = AutoDisposeProviderRef<FeedRemoteDatasource>;
String _$geoDatasourceHash() => r'f4708f4d2d8c7078b2fea0488a2990c0952b76ef';

/// See also [geoDatasource].
@ProviderFor(geoDatasource)
final geoDatasourceProvider = AutoDisposeProvider<GeoDatasource>.internal(
  geoDatasource,
  name: r'geoDatasourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$geoDatasourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GeoDatasourceRef = AutoDisposeProviderRef<GeoDatasource>;
String _$feedRepositoryHash() => r'56eac5f86183b67cfe8a1980bddd8037185aa6d7';

/// See also [feedRepository].
@ProviderFor(feedRepository)
final feedRepositoryProvider = AutoDisposeProvider<FeedRepository>.internal(
  feedRepository,
  name: r'feedRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$feedRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeedRepositoryRef = AutoDisposeProviderRef<FeedRepository>;
String _$feedNotifierHash() => r'1c359be2a20c61d0547e2d970e4f89fbc84c16a3';

/// See also [FeedNotifier].
@ProviderFor(FeedNotifier)
final feedNotifierProvider =
    AutoDisposeAsyncNotifierProvider<FeedNotifier, FeedPage>.internal(
      FeedNotifier.new,
      name: r'feedNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$feedNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FeedNotifier = AutoDisposeAsyncNotifier<FeedPage>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
