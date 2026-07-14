import 'dart:typed_data';

/// Fallo al subir la imagen de perfil al storage (bucket inexistente o mal
/// configurado, permisos, etc.). Tipa el error del upload para que la UI
/// pueda distinguir "no se pudo subir la foto" de "no se pudo guardar el
/// perfil" sin acoplarse a Supabase.
class AvatarUploadException implements Exception {
  AvatarUploadException({this.message = ''});

  final String message;

  @override
  String toString() => 'AvatarUploadException: $message';
}

abstract interface class AvatarStorageDatasource {
  /// Sube el avatar y devuelve su URL pública.
  ///
  /// Lanza [AvatarUploadException] si el storage rechaza la subida.
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
  });
}
