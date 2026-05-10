import 'dart:typed_data';

abstract interface class AvatarStorageDatasource {
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
  });
}
