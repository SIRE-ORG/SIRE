// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservations_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reservationsRemoteDatasourceHash() =>
    r'0bf77ce02566bdc3a01d125776df643da7e007cf';

/// See also [reservationsRemoteDatasource].
@ProviderFor(reservationsRemoteDatasource)
final reservationsRemoteDatasourceProvider =
    AutoDisposeProvider<ReservationsRemoteDatasource>.internal(
      reservationsRemoteDatasource,
      name: r'reservationsRemoteDatasourceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$reservationsRemoteDatasourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReservationsRemoteDatasourceRef =
    AutoDisposeProviderRef<ReservationsRemoteDatasource>;
String _$reservationsRepositoryHash() =>
    r'3c2e95b6686758f2a1ced7adfc4691f3a244d3bf';

/// See also [reservationsRepository].
@ProviderFor(reservationsRepository)
final reservationsRepositoryProvider =
    AutoDisposeProvider<ReservationsRepository>.internal(
      reservationsRepository,
      name: r'reservationsRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$reservationsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReservationsRepositoryRef =
    AutoDisposeProviderRef<ReservationsRepository>;
String _$myReservationsNotifierHash() =>
    r'0d18fbc5f0730315c626d82bed8939e147f6fa9f';

/// See also [MyReservationsNotifier].
@ProviderFor(MyReservationsNotifier)
final myReservationsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      MyReservationsNotifier,
      List<Reservation>
    >.internal(
      MyReservationsNotifier.new,
      name: r'myReservationsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$myReservationsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MyReservationsNotifier = AutoDisposeAsyncNotifier<List<Reservation>>;
String _$reservationActionNotifierHash() =>
    r'7fb4804656cadb4fc9510edb5729e425461b7fbc';

/// See also [ReservationActionNotifier].
@ProviderFor(ReservationActionNotifier)
final reservationActionNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ReservationActionNotifier, void>.internal(
      ReservationActionNotifier.new,
      name: r'reservationActionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$reservationActionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ReservationActionNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
