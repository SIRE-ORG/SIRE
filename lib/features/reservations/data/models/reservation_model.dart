import '../../domain/entities/reservation.dart';

class ReservationModel {
  const ReservationModel({
    required this.id,
    required this.publicationId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
    this.publicationTitle,
    this.publicationCity,
    this.publicationImageUrl,
  });

  final String id;
  final String publicationId;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String createdAt;
  final String? publicationTitle;
  final String? publicationCity;
  final String? publicationImageUrl;

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    // publication solo se incluye en GET /mine; en create/update está ausente.
    final pub =
        (json['publication'] as Map?)?.cast<String, dynamic>() ?? const {};
    return ReservationModel(
      id: json['id'] as String,
      publicationId: json['publicationId'] as String,
      date: json['date'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] as String? ?? '',
      publicationTitle: pub['title'] as String?,
      publicationCity: pub['city'] as String?,
      publicationImageUrl: pub['imageUrl'] as String?,
    );
  }

  Reservation toEntity() => Reservation(
    id: id,
    publicationId: publicationId,
    date: date,
    startTime: startTime,
    endTime: endTime,
    status: reservationStatusFromString(status),
    createdAt: createdAt,
    publicationTitle: publicationTitle,
    publicationCity: publicationCity,
    publicationImageUrl: publicationImageUrl,
  );
}
