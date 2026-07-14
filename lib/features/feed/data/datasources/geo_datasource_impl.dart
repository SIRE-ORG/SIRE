import 'package:geolocator/geolocator.dart';

import '../../../../core/network/app_exception.dart';
import '../../domain/entities/geo_location.dart';
import 'geo_datasource.dart';
import 'reverse_geocoding_datasource.dart';

class GeoDatasourceImpl implements GeoDatasource {
  const GeoDatasourceImpl({required this.reverseGeocoder});

  /// Resuelve lat/lon -> región vía API externa (Nominatim).
  final ReverseGeocodingDatasource reverseGeocoder;

  @override
  Future<GeoLocation> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw ServerException(
        code: 'LOCATION_SERVICE_DISABLED',
        message: 'El servicio de ubicación está desactivado.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw ServerException(
        code: 'LOCATION_PERMISSION_DENIED',
        message: 'Permiso de ubicación denegado por el usuario.',
      );
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.low,
      timeLimit: Duration(seconds: 10),
    );
    final position = await Geolocator.getCurrentPosition(
      locationSettings: settings,
    );

    // Reverse-geocoding vía API externa (Nominatim), no por el geocoder del SO.
    return reverseGeocoder.reverse(
      lat: position.latitude,
      lon: position.longitude,
    );
  }

  @override
  Future<bool> hasLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    // Solo consulta el estado actual, nunca lo solicita: a diferencia de
    // getCurrentLocation, esto no debe disparar el diálogo nativo.
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
}
