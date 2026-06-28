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
String _$receivedReservationsHash() =>
    r'a1d78aa071c36020a66e0f65f5cfa6be395657f9';

/// See also [receivedReservations].
@ProviderFor(receivedReservations)
final receivedReservationsProvider =
    AutoDisposeFutureProvider<List<Reservation>>.internal(
      receivedReservations,
      name: r'receivedReservationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$receivedReservationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReceivedReservationsRef =
    AutoDisposeFutureProviderRef<List<Reservation>>;
String _$reservationDetailHash() => r'5d9bd8057717e9480a891c22ea0f4a2a95d5e397';

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

/// See also [reservationDetail].
@ProviderFor(reservationDetail)
const reservationDetailProvider = ReservationDetailFamily();

/// See also [reservationDetail].
class ReservationDetailFamily extends Family<AsyncValue<Reservation>> {
  /// See also [reservationDetail].
  const ReservationDetailFamily();

  /// See also [reservationDetail].
  ReservationDetailProvider call(String id) {
    return ReservationDetailProvider(id);
  }

  @override
  ReservationDetailProvider getProviderOverride(
    covariant ReservationDetailProvider provider,
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
  String? get name => r'reservationDetailProvider';
}

/// See also [reservationDetail].
class ReservationDetailProvider extends AutoDisposeFutureProvider<Reservation> {
  /// See also [reservationDetail].
  ReservationDetailProvider(String id)
    : this._internal(
        (ref) => reservationDetail(ref as ReservationDetailRef, id),
        from: reservationDetailProvider,
        name: r'reservationDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$reservationDetailHash,
        dependencies: ReservationDetailFamily._dependencies,
        allTransitiveDependencies:
            ReservationDetailFamily._allTransitiveDependencies,
        id: id,
      );

  ReservationDetailProvider._internal(
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
    FutureOr<Reservation> Function(ReservationDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ReservationDetailProvider._internal(
        (ref) => create(ref as ReservationDetailRef),
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
  AutoDisposeFutureProviderElement<Reservation> createElement() {
    return _ReservationDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReservationDetailProvider && other.id == id;
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
mixin ReservationDetailRef on AutoDisposeFutureProviderRef<Reservation> {
  /// The parameter `id` of this provider.
  String get id;
}

class _ReservationDetailProviderElement
    extends AutoDisposeFutureProviderElement<Reservation>
    with ReservationDetailRef {
  _ReservationDetailProviderElement(super.provider);

  @override
  String get id => (origin as ReservationDetailProvider).id;
}

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
String _$receivedReservationsNotifierHash() =>
    r'c688a2e8a6b998d6cacbf65082c5206ca801b956';

/// See also [ReceivedReservationsNotifier].
@ProviderFor(ReceivedReservationsNotifier)
final receivedReservationsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      ReceivedReservationsNotifier,
      List<Reservation>
    >.internal(
      ReceivedReservationsNotifier.new,
      name: r'receivedReservationsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$receivedReservationsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ReceivedReservationsNotifier =
    AutoDisposeAsyncNotifier<List<Reservation>>;
String _$reservationActionNotifierHash() =>
    r'b6377a4671f2efb2479338b3ae49a46f875e0289';

/// See also [ReservationActionNotifier].
@ProviderFor(ReservationActionNotifier)
final reservationActionNotifierProvider =
    AutoDisposeNotifierProvider<
      ReservationActionNotifier,
      AsyncValue<void>
    >.internal(
      ReservationActionNotifier.new,
      name: r'reservationActionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$reservationActionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ReservationActionNotifier = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
