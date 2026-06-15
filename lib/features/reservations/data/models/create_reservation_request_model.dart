class CreateReservationRequestModel {
  const CreateReservationRequestModel({
    required this.publicationId,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  final String publicationId;
  final String date;
  final String startTime;
  final String endTime;

  Map<String, dynamic> toJson() => {
    'publicationId': publicationId,
    'date': date,
    'startTime': startTime,
    'endTime': endTime,
  };
}
