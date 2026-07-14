import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/app_exception.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_supabase_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.supabaseDatasource,
    required this.remoteDatasource,
    required this.storage,
  });

  final AuthSupabaseDatasource supabaseDatasource;
  final AuthRemoteDatasource remoteDatasource;
  final LocalStorageService storage;

  @override
  Future<void> login({required String email, required String password}) async {
    await supabaseDatasource.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signInAnonymously() async {
    // Idempotente: si ya hay una sesión (anónima o no), no hace nada.
    if (supabaseDatasource.getCurrentUserId() != null) return;
    await supabaseDatasource.signInAnonymously();
  }

  @override
  Future<void> sendMagicLink({required String email}) async {
    await supabaseDatasource.signInWithOtp(email: email);
  }

  @override
  Future<void> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.email,
  }) async {
    await supabaseDatasource.verifyOtp(email: email, token: token, type: type);
  }

  @override
  Future<void> updateEmail({required String email}) async {
    await supabaseDatasource.updateEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    await supabaseDatasource.signOut();
    await storage.delete(StorageKeys.token);
  }

  @override
  Future<AuthResult> registerGuest({
    required String name,
    required String email,
    required String phone,
  }) async {
    final response = await remoteDatasource.registerGuest(
      name: name,
      email: email,
      phone: phone,
    );
    if (response.token != null) {
      await storage.write(StorageKeys.token, response.token!);
    }
    return response.toEntity();
  }

  @override
  Future<void> activateAccount({required String password}) async {
    await supabaseDatasource.updatePassword(password: password);
    await remoteDatasource.updateAccountStatus();
  }

  @override
  Future<UserProfile?> getProfile() async {
    if (supabaseDatasource.getCurrentUserId() == null) return null;
    try {
      final model = await remoteDatasource.getProfile();
      return model.toEntity();
    } on NotFoundException {
      // Sesión Supabase válida (p. ej. anónima) sin fila de perfil todavía:
      // se trata como "sin perfil", no como error. authStatusProvider deriva
      // AccountStatus.anon a partir de esto.
      return null;
    } on DioException catch (e) {
      // El ErrorInterceptor de DioClient NO lanza la AppException tipada:
      // la envuelve en DioException.error. Sin este unwrap, el 404 de un
      // anónimo sin perfil subía como error y rompía la elegibilidad de
      // reserva (formulario de invitado jamás se mostraba).
      if (e.error is NotFoundException) return null;
      rethrow;
    }
  }

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    final model = await remoteDatasource.updateProfile(
      name: name,
      phone: phone,
      avatarUrl: avatarUrl,
    );
    return model.toEntity();
  }

  @override
  Stream<AuthState> authStateChanges() => supabaseDatasource.authStateChanges();
}
