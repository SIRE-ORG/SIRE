import 'dart:typed_data';

import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';
import '../../data/datasources/avatar_storage_datasource.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase({
    required AuthRepository repository,
    required AvatarStorageDatasource avatarDatasource,
  }) : _repository = repository,
       _avatarDatasource = avatarDatasource;

  final AuthRepository _repository;
  final AvatarStorageDatasource _avatarDatasource;

  Future<UserProfile> call({
    required String userId,
    String? name,
    String? phone,
    Uint8List? avatarBytes,
    String? avatarExtension,
  }) async {
    String? avatarUrl;
    if (avatarBytes != null && avatarExtension != null) {
      avatarUrl = await _avatarDatasource.uploadAvatar(
        userId: userId,
        bytes: avatarBytes,
        extension: avatarExtension,
      );
    }
    return _repository.updateProfile(
      name: name,
      phone: phone,
      avatarUrl: avatarUrl,
    );
  }
}
