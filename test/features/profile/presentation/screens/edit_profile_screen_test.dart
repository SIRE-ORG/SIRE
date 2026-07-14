import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/features/auth/data/datasources/avatar_storage_datasource.dart';
import 'package:sire/features/auth/domain/entities/auth_result.dart';
import 'package:sire/features/auth/domain/entities/user_profile.dart';
import 'package:sire/features/auth/domain/repositories/auth_repository.dart';
import 'package:sire/features/auth/presentation/providers/auth_provider.dart';
import 'package:sire/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Doble controlable de [AuthRepository]: solo implementa [updateProfile]
/// (lo único que ejercita EditProfileScreen); el resto no debe invocarse en
/// estas pruebas.
class _StubAuthRepository implements AuthRepository {
  _StubAuthRepository({this.result, this.error});

  final UserProfile? result;
  final Object? error;

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    if (error != null) throw error!;
    return result!;
  }

  @override
  Future<void> login({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> signInAnonymously() => throw UnimplementedError();

  @override
  Future<void> sendMagicLink({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.email,
  }) => throw UnimplementedError();

  @override
  Future<void> updateEmail({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<AuthResult> registerGuest({
    required String name,
    required String email,
    required String phone,
  }) => throw UnimplementedError();

  @override
  Future<void> activateAccount({required String password}) =>
      throw UnimplementedError();

  @override
  Future<UserProfile?> getProfile() => throw UnimplementedError();

  @override
  Stream<AuthState> authStateChanges() => throw UnimplementedError();
}

/// AvatarStorageDatasource que revienta si se invoca: en estas pruebas no se
/// selecciona imagen, así que UpdateProfileUseCase no debería llamarlo.
class _UnusedAvatarStorageDatasource implements AvatarStorageDatasource {
  const _UnusedAvatarStorageDatasource();

  @override
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) => throw StateError(
    'AvatarStorageDatasource no debía ser invocado en esta prueba',
  );
}

void main() {
  Widget buildSubject({UserProfile? profile, AuthRepository? repository}) {
    final mockRouter = GoRouter(
      initialLocation: '/edit-profile',
      routes: [
        GoRoute(
          path: '/edit-profile',
          builder: (_, _) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/feed',
          builder: (_, _) => const Scaffold(body: Text('Feed')),
        ),
        GoRoute(
          path: '/my-reservations',
          builder: (_, _) => const Scaffold(body: Text('Mis Reservas')),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) => Future.value(profile)),
        if (repository != null)
          authRepositoryProvider.overrideWithValue(repository),
        avatarStorageDatasourceProvider.overrideWithValue(
          const _UnusedAvatarStorageDatasource(),
        ),
      ],
      child: MaterialApp.router(routerConfig: mockRouter),
    );
  }

  testWidgets('EditProfileScreen muestra título y campos del formulario', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Editar Perfil'), findsWidgets);
    expect(find.text('Nombre completo'), findsOneWidget);
    expect(find.text('Teléfono'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('EditProfileScreen muestra sección cambio de contraseña', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Cambiar contraseña'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('EditProfileScreen muestra AppBar con título', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('EditProfileScreen permite ingresar texto en nombre', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Juan Pérez Test');
    await tester.pump();

    expect(find.text('Juan Pérez Test'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('EditProfileScreen layout web muestra sidebar SIRE', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('SIRE'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('EditProfileScreen layout web muestra formulario con Cancelar', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Editar Perfil'), findsWidgets);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Cambiar contraseña'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('EditProfileScreen layout web muestra botón Guardar cambios', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Guardar cambios'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  group('EditProfileScreen - guardar cambios (Fix 3+4)', () {
    const profile = UserProfile(
      id: 'user-1',
      name: 'Juan Pérez',
      email: 'juan@sire.cl',
      phone: '+56911111111',
      accountStatus: AccountStatus.active,
      emailVerified: true,
    );

    Future<void> pumpAndSave(WidgetTester tester, AuthRepository repo) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        FlutterError.onError = originalOnError;
      });

      await tester.pumpWidget(buildSubject(profile: profile, repository: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'éxito real (el repo no lanza) -> SnackBar "Perfil actualizado"',
      (tester) async {
        await pumpAndSave(
          tester,
          _StubAuthRepository(
            result: const UserProfile(
              id: 'user-1',
              name: 'Juan Editado',
              email: 'juan@sire.cl',
              phone: '+56911111111',
              accountStatus: AccountStatus.active,
              emailVerified: true,
            ),
          ),
        );

        expect(find.text('Perfil actualizado'), findsOneWidget);
      },
    );

    testWidgets(
      'NotFoundException (endpoint viejo de Render o perfil inexistente) -> '
      'mensaje honesto, nunca "Perfil actualizado"',
      (tester) async {
        await pumpAndSave(
          tester,
          _StubAuthRepository(
            error: DioException(
              requestOptions: RequestOptions(path: '/users/me'),
              error: NotFoundException(code: 'UNKNOWN'),
            ),
          ),
        );

        expect(
          find.text(
            'La edición de perfil estará disponible tras la próxima '
            'actualización del servidor',
          ),
          findsOneWidget,
        );
        expect(find.text('Perfil actualizado'), findsNothing);
      },
    );

    testWidgets('NetworkException -> mensaje de sin conexión', (tester) async {
      await pumpAndSave(
        tester,
        _StubAuthRepository(
          error: DioException(
            requestOptions: RequestOptions(path: '/users/me'),
            error: NetworkException(),
          ),
        ),
      );

      expect(
        find.text('Sin conexión. Revisa tu internet e intenta nuevamente.'),
        findsOneWidget,
      );
      expect(find.text('Perfil actualizado'), findsNothing);
    });

    testWidgets(
      'error genérico -> mensaje con code, nunca "Perfil actualizado"',
      (tester) async {
        await pumpAndSave(
          tester,
          _StubAuthRepository(
            error: DioException(
              requestOptions: RequestOptions(path: '/users/me'),
              error: ServerException(
                code: 'INTERNAL_SERVER_ERROR',
                message: 'boom',
              ),
            ),
          ),
        );

        expect(
          find.text(
            'No se pudo guardar el perfil (error INTERNAL_SERVER_ERROR)',
          ),
          findsOneWidget,
        );
        expect(find.text('Perfil actualizado'), findsNothing);
      },
    );

    // S3-3: el upload del avatar ocurre ANTES del PUT (UpdateProfileUseCase)
    // y su fallo llega a la pantalla como AvatarUploadException (el rethrow
    // de ProfileNotifier propaga la excepción tal cual, venga del upload o
    // del PUT). Que el use case lanza esa excepción cuando el storage falla
    // lo cubre update_profile_usecase_test.dart; acá se cubre el mapeo de la
    // pantalla al SnackBar específico.
    testWidgets(
      'fallo de subida del avatar (AvatarUploadException) -> SnackBar '
      'específico de la foto, no el genérico de guardado',
      (tester) async {
        await pumpAndSave(
          tester,
          _StubAuthRepository(
            error: AvatarUploadException(message: 'Bucket not found'),
          ),
        );

        expect(
          find.text(
            'No pudimos subir la foto (almacenamiento en configuración). '
            'Puedes guardar los demás cambios quitando la imagen.',
          ),
          findsOneWidget,
        );
        expect(find.text('No se pudo guardar el perfil'), findsNothing);
        expect(find.text('Perfil actualizado'), findsNothing);
      },
    );
  });
}
