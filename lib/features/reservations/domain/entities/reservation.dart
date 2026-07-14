import 'package:equatable/equatable.dart';

enum ReservationStatus { pending, cancelled, rejected, completed, failed }

ReservationStatus reservationStatusFromString(String raw) =>
    ReservationStatus.values.firstWhere(
      (s) => s.name == raw.toLowerCase(),
      orElse: () => ReservationStatus.pending, // default documentado
    );

String reservationStatusToString(ReservationStatus s) => s.name; // minúsculas

class Reservation extends Equatable {
  const Reservation({
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
    this.publicationOwnerName,
    this.applicantName,
    this.applicantEmail,
    this.applicantPhone,
  });

  final String id;
  final String publicationId;
  final String date;
  final String startTime;
  final String endTime;
  final ReservationStatus status;
  final String createdAt;
  final String? publicationTitle;
  final String? publicationCity;
  final String? publicationImageUrl;

  /// Nombre del dueño/publicador de la publicación reservada (autor). El
  /// backend hoy no lo incluye en GET /mine (solo title/city/imageUrl); se
  /// deja preparado para cuando lo agregue. Mientras tanto queda `null` y
  /// la UI muestra un guion en vez de inventar el dato.
  final String? publicationOwnerName;
  final String? applicantName;
  final String? applicantEmail;
  final String? applicantPhone;

  @override
  List<Object?> get props => [
    id,
    publicationId,
    date,
    startTime,
    endTime,
    status,
    createdAt,
    publicationTitle,
    publicationCity,
    publicationImageUrl,
    publicationOwnerName,
    applicantName,
    applicantEmail,
    applicantPhone,
  ];
}
