// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationsDatasourceHash() =>
    r'45dabd29a2cbc56858ceed8b52c799b17ff945ba';

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
String _$notificationsHash() => r'bf54890197e27d966b1c5036cea0fc70e0508f15';

/// See also [notifications].
@ProviderFor(notifications)
final notificationsProvider =
    AutoDisposeFutureProvider<List<NotificationModel>>.internal(
      notifications,
      name: r'notificationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationsRef =
    AutoDisposeFutureProviderRef<List<NotificationModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
