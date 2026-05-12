import 'dart:typed_data';

abstract interface class PublicationImageDatasource {
  Future<String> uploadImage({
    required Uint8List bytes,
    required String extension,
  });
}
