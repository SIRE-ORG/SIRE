import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/features/auth/domain/entities/auth_result.dart';
import 'package:sire/features/auth/domain/entities/user_profile.dart';
import 'package:sire/features/auth/domain/repositories/auth_repository.dart';
import 'package:sire/features/auth/presentation/providers/auth_provider.dart';
import 'package:sire/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Doble de [AuthRepository] para el reenvío de código: captura los emails
/// con que se invocan [sendMagicLink] (registro directo) y [updateEmail]
/// (activación), con errores inyectables. El resto no debe invocarse.
class _StubAuthRepository implements AuthRepository {
  _StubAuthRepository({this.sendMagicLinkError, this.updateEmailError});

  final Object? sendMagicLinkError;
  final Object? updateEmailError;
  String? magicLinkEmail;
  String? updateEmailEmail;

  @override
  Future<void> sendMagicLink({required String email}) async {
    magicLinkEmail = email;
    if (sendMagicLinkError != null) throw sendMagicLinkError!;
  }

  @override
  Future<void> updateEmail({required String email}) async {
    updateEmailEmail = email;
    if (updateEmailError != null) throw updateEmailError!;
  }

  @override
  Future<void> login({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> signInAnonymously() => throw UnimplementedError();

  @override
  Future<void> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.email,
  }) => throw UnimplementedError();

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
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) => throw UnimplementedError();

  @override
  Stream<AuthState> authStateChanges() => throw UnimplementedError();
}

void main() {
  GoRouter buildRouter({Object? extra}) => GoRouter(
    initialLocation: '/verify-otp',
    initialExtra: extra,
    routes: [
      GoRoute(path: '/verify-otp', builder: (_, _) => const VerifyOtpScreen()),
      GoRoute(
        path: '/activate-account',
        builder: (_, _) => const Scaffold(body: Text('Activar cuenta')),
      ),
    ],
  );

  Widget buildApp({Object? extra, AuthRepository? repository}) => ProviderScope(
    overrides: [
      if (repository != null)
        authRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp.router(routerConfig: buildRouter(extra: extra)),
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

  /// Desmonta la pantalla al final del test: el contador de reenvío usa un
  /// Timer.periodic y, si sigue vivo al cerrar el test, flutter_test acusa
  /// "Timer is still pending". El dispose de la pantalla lo cancela.
  Future<void> desmontar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('renderiza título, campo Código y botón Verificar', (
    tester,
  ) async {
    suppressOverflow(tester);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Verificar código'), findsOneWidget);
    expect(find.text('Código'), findsOneWidget);
    expect(find.text('Verificar'), findsOneWidget);

    await desmontar(tester);
  });

  testWidgets('muestra instrucción sobre el código de 6 dígitos', (
    tester,
  ) async {
    suppressOverflow(tester);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('6 dígitos'), findsOneWidget);

    await desmontar(tester);
  });

  testWidgets('código menor a 6 dígitos muestra SnackBar de error', (
    tester,
  ) async {
    suppressOverflow(tester);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '123');
    await tester.pump();

    await tester.tap(find.text('Verificar'));
    await tester.pump();

    expect(find.text('Ingresa el código de 6 dígitos'), findsOneWidget);

    await desmontar(tester);
  });

  testWidgets('permite ingresar texto en el campo de código', (tester) async {
    suppressOverflow(tester);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pump();

    expect(find.text('123456'), findsOneWidget);

    await desmontar(tester);
  });

  testWidgets(
    'contexto activación (otpType emailChange) cambia título y copy',
    (tester) async {
      suppressOverflow(tester);

      await tester.pumpWidget(
        buildApp(extra: {'email': 'ana@mail.com', 'otpType': 'emailChange'}),
      );
      await tester.pumpAndSettle();

      expect(find.text('Activa tu cuenta'), findsOneWidget);
      expect(find.text('Verificar código'), findsNothing);
      expect(find.textContaining('ana@mail.com'), findsOneWidget);

      await desmontar(tester);
    },
  );

  testWidgets('contexto registro directo muestra el correo del extra', (
    tester,
  ) async {
    suppressOverflow(tester);

    await tester.pumpWidget(
      buildApp(extra: {'email': 'ana@mail.com', 'otpType': 'email'}),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verificar código'), findsOneWidget);
    expect(find.textContaining('ana@mail.com'), findsOneWidget);

    await desmontar(tester);
  });

  group('Reenviar código', () {
    TextButton botonReenviar(WidgetTester tester) =>
        tester.widget<TextButton>(find.byType(TextButton));

    testWidgets('arranca deshabilitado con la cuenta regresiva visible', (
      tester,
    ) async {
      suppressOverflow(tester);

      await tester.pumpWidget(
        buildApp(extra: {'email': 'ana@mail.com', 'otpType': 'email'}),
      );
      await tester.pump();

      expect(find.text('Reenviar código (1:00)'), findsOneWidget);
      expect(botonReenviar(tester).onPressed, isNull);

      // A los 13 segundos el contador va en 0:47 y sigue deshabilitado.
      await tester.pump(const Duration(seconds: 13));
      expect(find.text('Reenviar código (0:47)'), findsOneWidget);
      expect(botonReenviar(tester).onPressed, isNull);

      await desmontar(tester);
    });

    testWidgets('se habilita al llegar la cuenta regresiva a 0', (
      tester,
    ) async {
      suppressOverflow(tester);

      await tester.pumpWidget(
        buildApp(extra: {'email': 'ana@mail.com', 'otpType': 'email'}),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 60));

      expect(find.text('Reenviar código'), findsOneWidget);
      expect(find.textContaining('Reenviar código ('), findsNothing);
      expect(botonReenviar(tester).onPressed, isNotNull);

      await desmontar(tester);
    });

    testWidgets(
      'registro directo (otpType email): reenvía vía magic link, avisa y '
      'reinicia el contador',
      (tester) async {
        suppressOverflow(tester);

        final repo = _StubAuthRepository();
        await tester.pumpWidget(
          buildApp(
            extra: {'email': 'ana@mail.com', 'otpType': 'email'},
            repository: repo,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 60));

        await tester.tap(find.text('Reenviar código'));
        await tester.pump();
        await tester.pump();

        expect(repo.magicLinkEmail, 'ana@mail.com');
        expect(repo.updateEmailEmail, isNull);
        expect(find.text('Código reenviado a ana@mail.com'), findsOneWidget);
        // El contador reinició: botón deshabilitado con cuenta regresiva.
        expect(find.textContaining('Reenviar código ('), findsOneWidget);
        expect(botonReenviar(tester).onPressed, isNull);

        await desmontar(tester);
      },
    );

    testWidgets(
      'activación (otpType emailChange): reenvía re-disparando updateEmail',
      (tester) async {
        suppressOverflow(tester);

        final repo = _StubAuthRepository();
        await tester.pumpWidget(
          buildApp(
            extra: {'email': 'ana@mail.com', 'otpType': 'emailChange'},
            repository: repo,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 60));

        await tester.tap(find.text('Reenviar código'));
        await tester.pump();
        await tester.pump();

        expect(repo.updateEmailEmail, 'ana@mail.com');
        expect(repo.magicLinkEmail, isNull);
        expect(find.text('Código reenviado a ana@mail.com'), findsOneWidget);
        expect(find.textContaining('Reenviar código ('), findsOneWidget);

        await desmontar(tester);
      },
    );

    testWidgets(
      'reenvío fallido muestra error tipado y NO reinicia el contador',
      (tester) async {
        suppressOverflow(tester);

        final repo = _StubAuthRepository(
          sendMagicLinkError: NetworkException(),
        );
        await tester.pumpWidget(
          buildApp(
            extra: {'email': 'ana@mail.com', 'otpType': 'email'},
            repository: repo,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 60));

        await tester.tap(find.text('Reenviar código'));
        await tester.pump();
        await tester.pump();

        expect(
          find.text('Sin conexión. Revisa tu internet e intenta nuevamente.'),
          findsOneWidget,
        );
        // Sin cuenta regresiva: el botón queda habilitado para reintentar.
        expect(find.text('Reenviar código'), findsOneWidget);
        expect(find.textContaining('Reenviar código ('), findsNothing);
        expect(botonReenviar(tester).onPressed, isNotNull);

        await desmontar(tester);
      },
    );

    testWidgets(
      'reenvío fallido en activación muestra error genérico y tampoco '
      'reinicia el contador',
      (tester) async {
        suppressOverflow(tester);

        final repo = _StubAuthRepository(
          updateEmailError: ServerException(
            code: 'INTERNAL_SERVER_ERROR',
            message: 'boom',
          ),
        );
        await tester.pumpWidget(
          buildApp(
            extra: {'email': 'ana@mail.com', 'otpType': 'emailChange'},
            repository: repo,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 60));

        await tester.tap(find.text('Reenviar código'));
        await tester.pump();
        await tester.pump();

        expect(
          find.text('No pudimos reenviar el código. Intenta nuevamente.'),
          findsOneWidget,
        );
        expect(find.textContaining('Reenviar código ('), findsNothing);
        expect(botonReenviar(tester).onPressed, isNotNull);

        await desmontar(tester);
      },
    );
  });
}
