import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'avatar_storage_datasource.dart';

class AvatarStorageDatasourceImpl implements AvatarStorageDatasource {
  static const _bucket = 'avatars';

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final path = '$userId.$extension';
    await _client.storage
        .from(_bucket)
        .uploadBinary(path, bytes, fileOptions: FileOptions(upsert: true));
    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}
