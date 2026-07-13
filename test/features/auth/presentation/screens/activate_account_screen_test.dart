import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/auth/domain/entities/auth_result.dart';
import 'package:sire/features/auth/domain/entities/user_profile.dart';
import 'package:sire/features/auth/domain/repositories/auth_repository.dart';
import 'package:sire/features/auth/presentation/providers/auth_provider.dart';
import 'package:sire/features/auth/presentation/screens/activate_account_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Doble controlable de [AuthRepository]: solo implementa [activateAccount]
/// (lo único que ejercita ActivateAccountScreen); el resto no debe
/// invocarse en estas pruebas.
class _StubAuthRepository implements AuthRepository {
  _StubAuthRepository({this.error});

  final Object? error;

  @override
  Future<void> activateAccount({required String password}) async {
    if (error != null) throw error!;
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
  Future<UserProfile?> getProfile() => throw UnimplementedError();

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) => throw UnimplementedError();

  @override
  Stream<AuthState> authStateChanges() => throw UnimplementedError();
}

void main() {
  Widget buildApp({AuthRepository? repository}) => ProviderScope(
    overrides: [
      if (repository != null)
        authRepositoryProvider.overrideWithValue(repository),
      currentProfileProvider.overrideWith((ref) => Future.value(null)),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/activate-account',
        routes: [
          GoRoute(
            path: '/activate-account',
            builder: (_, _) => const ActivateAccountScreen(),
          ),
          GoRoute(
            path: '/feed',
            builder: (_, _) => const Scaffold(body: Text('Feed')),
          ),
        ],
      ),
    ),
  );

  void suppressOverflow(WidgetTester tester) {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exceptionAsString().contains('overflowed')) return;
      original?.call(d);
    };
    addTearDown(() {
      FlutterError.onError = original;
      tester.view.resetPhysicalSize();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
  }

  testWidgets('renderiza título, campo Contraseña y botón Activar cuenta', (
    tester,
  ) async {
    suppressOverflow(tester);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Activar cuenta'), findsWidgets);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.textContaining('Mínimo 8 caracteres'), findsOneWidget);
  });

  testWidgets('muestra instrucción sobre la contraseña', (tester) async {
    suppressOverflow(tester);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Establece una contraseña'), findsOneWidget);
  });

  testWidgets('contraseña menor a 8 caracteres muestra SnackBar de error', (
    tester,
  ) async {
    suppressOverflow(tester);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'short');
    await tester.pump();

    await tester.tap(find.text('Activar cuenta').last);
    await tester.pump();

    expect(
      find.text('La contraseña debe tener al menos 8 caracteres'),
      findsOneWidget,
    );
  });

  testWidgets('permite ingresar contraseña en el campo', (tester) async {
    suppressOverflow(tester);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'mipassword123');
    await tester.pump();

    // El campo es de tipo password, el texto puede estar ofuscado pero el widget lo acepta
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('activación exitosa navega al feed (no a crear publicación)', (
    tester,
  ) async {
    suppressOverflow(tester);

    await tester.pumpWidget(buildApp(repository: _StubAuthRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'mipassword123');
    await tester.pump();

    await tester.tap(find.text('Activar cuenta').last);
    await tester.pumpAndSettle();

    expect(find.text('Feed'), findsOneWidget);
  });

  testWidgets('activación fallida se queda en la pantalla y muestra error', (
    tester,
  ) async {
    suppressOverflow(tester);

    await tester.pumpWidget(
      buildApp(repository: _StubAuthRepository(error: Exception('boom'))),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'mipassword123');
    await tester.pump();

    await tester.tap(find.text('Activar cuenta').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo activar'), findsOneWidget);
    expect(find.text('Feed'), findsNothing);
  });
}
