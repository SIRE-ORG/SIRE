import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'publication_image_datasource.dart';

class PublicationImageDatasourceImpl implements PublicationImageDatasource {
  PublicationImageDatasourceImpl({SupabaseClient? client, Uuid? uuid})
    : _client = client ?? Supabase.instance.client,
      _uuid = uuid ?? const Uuid();

  final SupabaseClient _client;
  final Uuid _uuid;

  static const String _bucket = 'publications';

  @override
  Future<String> uploadImage({
    required Uint8List bytes,
    required String extension,
  }) async {
    final path = '${_uuid.v4()}.$extension';
    await _client.storage.from(_bucket).uploadBinary(path, bytes);
    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}
