class PublicationStatusUpdateModel {
  const PublicationStatusUpdateModel({required this.isActive});

  final bool isActive;

  Map<String, dynamic> toJson() => {'isActive': isActive};
}
