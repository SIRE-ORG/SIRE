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
    this.applicantName,
    this.applicantEmail,
    this.applicantPhone,
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
  final String? applicantName;
  final String? applicantEmail;
  final String? applicantPhone;

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    // publication solo se incluye en GET /mine; en create/update está ausente.
    final pub =
        (json['publication'] as Map?)?.cast<String, dynamic>() ?? const {};
    // El backend incluye al solicitante bajo la clave 'solicitante' en
    // GET /received (select: name, email, phone). Se acepta 'applicant'
    // como alias defensivo por si el payload cambia de nombre.
    final applicant =
        (json['solicitante'] as Map?)?.cast<String, dynamic>() ??
        (json['applicant'] as Map?)?.cast<String, dynamic>() ??
        const {};
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
      applicantName:
          applicant['name'] as String? ?? json['applicantName'] as String?,
      applicantEmail:
          applicant['email'] as String? ?? json['applicantEmail'] as String?,
      applicantPhone:
          applicant['phone'] as String? ?? json['applicantPhone'] as String?,
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
    applicantName: applicantName,
    applicantEmail: applicantEmail,
    applicantPhone: applicantPhone,
  );
}
