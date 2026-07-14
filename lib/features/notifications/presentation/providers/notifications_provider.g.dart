// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationsDatasourceHash() =>
    r'5a1f107d08e316df222359cc68fba25fd7bcfabc';

/// See also [notificationsDatasource].
@ProviderFor(notificationsDatasource)
final notificationsDatasourceProvider =
    AutoDisposeProvider<NotificationsDatasource>.internal(
      notificationsDatasource,
      name: r'notificationsDatasourceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationsDatasourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationsDatasourceRef =
    AutoDisposeProviderRef<NotificationsDatasource>;
String _$notificationsRepositoryHash() =>
    r'0accc426eb453b146cc8445471a5e57799986ba1';

/// See also [notificationsRepository].
@ProviderFor(notificationsRepository)
final notificationsRepositoryProvider =
    AutoDisposeProvider<NotificationsRepository>.internal(
      notificationsRepository,
      name: r'notificationsRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationsRepositoryRef =
    AutoDisposeProviderRef<NotificationsRepository>;
String _$notificationsStreamHash() =>
    r'9f5f669bc1522cc69b9e818202974d246dd1b9ab';

/// See also [notificationsStream].
@ProviderFor(notificationsStream)
final notificationsStreamProvider =
    AutoDisposeStreamProvider<List<AppNotification>>.internal(
      notificationsStream,
      name: r'notificationsStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationsStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationsStreamRef =
    AutoDisposeStreamProviderRef<List<AppNotification>>;
String _$unreadCountHash() => r'65da8363152745f2d1f1b72257d9c4ee0563e91c';

/// See also [unreadCount].
@ProviderFor(unreadCount)
final unreadCountProvider = AutoDisposeProvider<int>.internal(
  unreadCount,
  name: r'unreadCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unreadCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnreadCountRef = AutoDisposeProviderRef<int>;
String _$notificationActionsNotifierHash() =>
    r'ad0ee50633a031fa70858e7eecad98c92dc5aeeb';

/// See also [NotificationActionsNotifier].
@ProviderFor(NotificationActionsNotifier)
final notificationActionsNotifierProvider =
    AutoDisposeNotifierProvider<
      NotificationActionsNotifier,
      AsyncValue<void>
    >.internal(
      NotificationActionsNotifier.new,
      name: r'notificationActionsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationActionsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NotificationActionsNotifier = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
