import '../../domain/entities/geo_location.dart';

/// Convierte coordenadas (lat/lon) en una ubicación administrativa
/// (región/ciudad). Es la frontera con un servicio de geocodificación inverso
/// externo; mantenerla detrás de una interfaz permite cambiar de proveedor
/// (Nominatim, OpenCage, Google…) sin tocar el resto de la capa geo.
abstract interface class ReverseGeocodingDatasource {
  Future<GeoLocation> reverse({required double lat, required double lon});
}
