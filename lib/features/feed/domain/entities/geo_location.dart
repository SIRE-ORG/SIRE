import 'package:equatable/equatable.dart';

class GeoLocation extends Equatable {
  const GeoLocation({required this.region, this.city});

  final String region;
  final String? city;

  @override
  List<Object?> get props => [region, city];
}
