import '../../domain/entities/geo_location.dart';

abstract interface class GeoDatasource {
  Future<GeoLocation> getCurrentLocation();

  /// `true` si el permiso de ubicación ya está concedido (whileInUse o
  /// always), consultando el estado actual SIN disparar el diálogo nativo
  /// de permiso (a diferencia de [getCurrentLocation], que sí lo dispara
  /// si hace falta). Se usa para saltar la pantalla de ubicación cuando el
  /// usuario ya lo concedió antes.
  Future<bool> hasLocationPermission();
}
