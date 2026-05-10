import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/network/app_exception.dart';
import '../../domain/entities/geo_location.dart';
import 'geo_datasource.dart';

class GeoDatasourceImpl implements GeoDatasource {
  const GeoDatasourceImpl();

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

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isEmpty) {
      throw ServerException(
        code: 'LOCATION_GEOCODING_EMPTY',
        message: 'No se pudo determinar la región a partir de las coordenadas.',
      );
    }

    final placemark = placemarks.first;
    final region = placemark.administrativeArea ?? '';
    final city = placemark.locality;
    return GeoLocation(
      region: region,
      city: (city == null || city.isEmpty) ? null : city,
    );
  }
}
