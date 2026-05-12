import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageKeys {
  StorageKeys._();
  static const String token = 'auth_token';
  static const String region = 'last_region';
}

class LocalStorageService {
  const LocalStorageService();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);
}
