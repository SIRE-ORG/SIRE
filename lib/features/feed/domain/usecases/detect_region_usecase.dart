import '../entities/geo_location.dart';
import '../repositories/feed_repository.dart';

class DetectRegionUseCase {
  const DetectRegionUseCase(this._repository);

  final FeedRepository _repository;

  Future<GeoLocation> call() => _repository.detectRegion();
}
