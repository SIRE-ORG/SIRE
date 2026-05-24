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
    r'8ba426f99a95a7ce6728b5af63c3316bf5d3602a';

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
String _$authStatusHash() => r'7592802e9646898475e78f98cb5aed2fedae7dae';

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
String _$authNotifierHash() => r'a372c787e0f182dc109d3a1105dda1093020847c';

/// See also [AuthNotifier].
@ProviderFor(AuthNotifier)
final authNotifierProvider =
    AutoDisposeAsyncNotifierProvider<AuthNotifier, void>.internal(
      AuthNotifier.new,
      name: r'authNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AuthNotifier = AutoDisposeAsyncNotifier<void>;
String _$profileNotifierHash() => r'3d1640808b986198d179f93b53d0cb5d040335b3';

/// See also [ProfileNotifier].
@ProviderFor(ProfileNotifier)
final profileNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ProfileNotifier, void>.internal(
      ProfileNotifier.new,
      name: r'profileNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$profileNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ProfileNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
