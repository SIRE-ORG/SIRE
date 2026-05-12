import '../../domain/entities/geo_location.dart';

abstract interface class GeoDatasource {
  Future<GeoLocation> getCurrentLocation();
}
