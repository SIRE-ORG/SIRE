// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_eligibility_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reservationEligibilityHash() =>
    r'46de402c72b509ecbe417a68784add66ec3f616b';

/// Deriva la [ReservationEligibility] del usuario actual (regla de negocio 4
/// del flujo de 3 fases). Depende de [authStatusProvider] (feature auth) y,
/// solo para el caso `guest`, de las reservas propias.
///
/// Copied from [reservationEligibility].
@ProviderFor(reservationEligibility)
final reservationEligibilityProvider =
    AutoDisposeFutureProvider<ReservationEligibility>.internal(
      reservationEligibility,
      name: r'reservationEligibilityProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$reservationEligibilityHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReservationEligibilityRef =
    AutoDisposeFutureProviderRef<ReservationEligibility>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
