class UpdateProfileRequestModel {
  const UpdateProfileRequestModel({this.name, this.phone, this.avatarUrl});

  final String? name;
  final String? phone;
  final String? avatarUrl;

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}
