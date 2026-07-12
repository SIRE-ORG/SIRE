import 'package:dio/dio.dart';

import '../../../../core/network/app_exception.dart';
import '../../domain/entities/geo_location.dart';
import 'reverse_geocoding_datasource.dart';

/// Reverse-geocoding contra la API pública de **Nominatim** (OpenStreetMap).
///
/// Es la integración con una API externa exigida por el hito: convierte las
/// coordenadas del dispositivo (que entrega Geolocator) en región/ciudad vía
/// HTTP, en lugar del geocoder nativo del SO.
///
/// No requiere API key. La política de uso de Nominatim pide:
///  - un `User-Agent` identificable (no el genérico de la librería), y
///  - un máximo de ~1 req/s (el onboarding hace una sola llamada -> OK).
///
/// Doc: https://nominatim.org/release-docs/develop/api/Reverse/
class NominatimReverseGeocodingDatasourceImpl
    implements ReverseGeocodingDatasource {
  NominatimReverseGeocodingDatasourceImpl({Dio? dio}) : _dio = dio ?? _build();

  final Dio _dio;

  static Dio _build() => Dio(
    BaseOptions(
      baseUrl: 'https://nominatim.openstreetmap.org',
      // User-Agent identificable, requerido por la política de Nominatim.
      headers: {'User-Agent': 'SIRE-App/1.0 (UFRO ICC706; academic project)'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  @override
  Future<GeoLocation> reverse({
    required double lat,
    required double lon,
  }) async {
    try {
      final response = await _dio.get(
        '/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'format': 'jsonv2',
          'accept-language': 'es',
          // zoom 10 ≈ nivel región/comuna; evita devolver calles innecesarias.
          'zoom': 10,
        },
      );

      final data = (response.data as Map).cast<String, dynamic>();
      final address =
          (data['address'] as Map?)?.cast<String, dynamic>() ?? const {};

      // En Chile, `state` es la región. La ciudad puede venir en varias claves
      // según el tipo de localidad; se toma la primera disponible.
      final region = (address['state'] as String?) ?? '';
      final city =
          (address['city'] ??
                  address['town'] ??
                  address['village'] ??
                  address['municipality'] ??
                  address['county'])
              as String?;

      if (region.isEmpty) {
        throw ServerException(
          code: 'REVERSE_GEOCODING_EMPTY',
          message: 'Nominatim no devolvió una región para las coordenadas.',
        );
      }

      return GeoLocation(
        region: region,
        city: (city == null || city.isEmpty) ? null : city,
      );
    } on DioException catch (e) {
      throw ServerException(
        code: 'REVERSE_GEOCODING_FAILED',
        message: 'Falló el reverse-geocoding con Nominatim: ${e.message}',
      );
    }
  }
}
