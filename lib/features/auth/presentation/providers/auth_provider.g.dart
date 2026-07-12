// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authSupabaseDatasourceHash() =>
    r'43f74fc24eb114b2fa5acc82025f49f57712bb80';

/// See also [authSupabaseDatasource].
@ProviderFor(authSupabaseDatasource)
final authSupabaseDatasourceProvider =
    AutoDisposeProvider<AuthSupabaseDatasource>.internal(
      authSupabaseDatasource,
      name: r'authSupabaseDatasourceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authSupabaseDatasourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthSupabaseDatasourceRef =
    AutoDisposeProviderRef<AuthSupabaseDatasource>;
String _$authRemoteDatasourceHash() =>
    r'0a76af05ddf5b0ef29d143db7540ce885e89b06d';

/// See also [authRemoteDatasource].
@ProviderFor(authRemoteDatasource)
final authRemoteDatasourceProvider =
    AutoDisposeProvider<AuthRemoteDatasource>.internal(
      authRemoteDatasource,
      name: r'authRemoteDatasourceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authRemoteDatasourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthRemoteDatasourceRef = AutoDisposeProviderRef<AuthRemoteDatasource>;
String _$avatarStorageDatasourceHash() =>
    r'540471153c3e431511700e291a948686d67296b4';

/// See also [avatarStorageDatasource].
@ProviderFor(avatarStorageDatasource)
final avatarStorageDatasourceProvider =
    AutoDisposeProvider<AvatarStorageDatasource>.internal(
      avatarStorageDatasource,
      name: r'avatarStorageDatasourceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$avatarStorageDatasourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvatarStorageDatasourceRef =
    AutoDisposeProviderRef<AvatarStorageDatasource>;
String _$authRepositoryHash() => r'68d31e1d9383adda142758e6065353e0338720f1';

/// See also [authRepository].
@ProviderFor(authRepository)
final authRepositoryProvider = AutoDisposeProvider<AuthRepository>.internal(
  authRepository,
  name: r'authRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthRepositoryRef = AutoDisposeProviderRef<AuthRepository>;
String _$currentProfileHash() => r'8aea9bb4cacc665bbea20cec85d449eb746665dd';

/// See also [currentProfile].
@ProviderFor(currentProfile)
final currentProfileProvider = AutoDisposeFutureProvider<UserProfile?>.internal(
  currentProfile,
  name: r'currentProfileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentProfileRef = AutoDisposeFutureProviderRef<UserProfile?>;
String _$authStatusHash() => r'b167f4e71e4bea20a985640f049e5261d9515988';

/// See also [authStatus].
@ProviderFor(authStatus)
final authStatusProvider = AutoDisposeFutureProvider<AccountStatus?>.internal(
  authStatus,
  name: r'authStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthStatusRef = AutoDisposeFutureProviderRef<AccountStatus?>;
String _$authNotifierHash() => r'1b13e75a7564d222cb7e9ec09e2610d2f68ba125';

/// See also [AuthNotifier].
@ProviderFor(AuthNotifier)
final authNotifierProvider =
    AutoDisposeNotifierProvider<AuthNotifier, AsyncValue<void>>.internal(
      AuthNotifier.new,
      name: r'authNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AuthNotifier = AutoDisposeNotifier<AsyncValue<void>>;
String _$profileNotifierHash() => r'da1d1940ef31adaa41e3fdec79b6ba5c1c37e561';

/// See also [ProfileNotifier].
@ProviderFor(ProfileNotifier)
final profileNotifierProvider =
    AutoDisposeNotifierProvider<ProfileNotifier, AsyncValue<void>>.internal(
      ProfileNotifier.new,
      name: r'profileNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$profileNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ProfileNotifier = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
