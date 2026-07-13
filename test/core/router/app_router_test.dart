// PI-ROUTER-01/02 - guards de navegación por estado de cuenta (P1 del flujo
// de 3 fases ANON -> GUEST -> ACTIVE). `decideRedirect` es la tabla de
// decisiones pura (rápida de testear exhaustivamente); el segundo grupo
// prueba el wiring real (appRouterProvider + refreshListenable) con un par
// de escenarios representativos, no la matriz completa.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/core/router/app_router.dart';
import 'package:sire/features/auth/domain/entities/user_profile.dart';
import 'package:sire/features/auth/presentation/providers/auth_provider.dart';
import 'package:sire/features/reservations/data/datasources/reservations_remote_datasource_mock_impl.dart';
import 'package:sire/features/reservations/presentation/providers/reservations_provider.dart';

void main() {
  group('decideRedirect - rutas públicas', () {
    const publicPaths = [
      '/location',
      '/feed',
      '/publication/:id',
      '/login',
      '/register',
      '/verify-otp',
      '/activate-account',
      '/forgot-password',
    ];

    for (final path in publicPaths) {
      test('$path nunca redirige, sin importar el status', () {
        expect(decideRedirect(path, null), isNull);
        expect(decideRedirect(path, AccountStatus.anon), isNull);
        expect(decideRedirect(path, AccountStatus.guest), isNull);
        expect(decideRedirect(path, AccountStatus.active), isNull);
      });
    }
  });

  group('decideRedirect - / (welcome)', () {
    test('sin sesión no redirige (welcome se muestra normal)', () {
      expect(decideRedirect('/', null), isNull);
    });

    for (final status in [
      AccountStatus.anon,
      AccountStatus.guest,
      AccountStatus.active,
    ]) {
      test('con sesión ($status) redirige a /feed', () {
        expect(decideRedirect('/', status), '/feed');
      });
    }
  });

  group('decideRedirect - requiere sesión (anon basta)', () {
    // `/profile` está acá (y no en "requiere perfil"): un anónimo sin perfil
    // no se redirige en seco a /login, ve un empty-state invitándolo a crear
    // cuenta.
    const sessionPaths = ['/publication/:id/confirm', '/profile'];

    for (final path in sessionPaths) {
      test('$path: sin sesión (status null) -> /login', () {
        expect(decideRedirect(path, null), '/login');
      });

      for (final status in [
        AccountStatus.anon,
        AccountStatus.guest,
        AccountStatus.active,
      ]) {
        test('$path: $status no redirige', () {
          expect(decideRedirect(path, status), isNull);
        });
      }
    }
  });

  group('decideRedirect - requiere AccountStatus.active', () {
    const activePaths = [
      '/dashboard',
      '/my-publications',
      '/publication/create',
      '/publication/:id/edit',
      '/received-reservations',
      '/received-reservation/detail',
    ];

    for (final path in activePaths) {
      test('$path: active no redirige', () {
        expect(decideRedirect(path, AccountStatus.active), isNull);
      });

      test('$path: sin sesión, anon o guest -> /profile', () {
        expect(decideRedirect(path, null), '/profile');
        expect(decideRedirect(path, AccountStatus.anon), '/profile');
        expect(decideRedirect(path, AccountStatus.guest), '/profile');
      });
    }
  });

  group('decideRedirect - requiere perfil (guest o active)', () {
    const profilePaths = [
      '/my-reservations',
      '/reservation/:id',
      '/notifications',
      '/profile/edit',
    ];

    for (final path in profilePaths) {
      test('$path: guest no redirige', () {
        expect(decideRedirect(path, AccountStatus.guest), isNull);
      });

      test('$path: active no redirige', () {
        expect(decideRedirect(path, AccountStatus.active), isNull);
      });

      test('$path: sin sesión -> /login', () {
        expect(decideRedirect(path, null), '/login');
      });

      test('$path: anon (sesión sin perfil) -> /login', () {
        expect(decideRedirect(path, AccountStatus.anon), '/login');
      });
    }
  });

  test('ruta no catalogada no redirige (fail-open)', () {
    expect(decideRedirect('/ruta-no-catalogada', null), isNull);
  });

  // -------------------------------------------------------------------
  // Wiring real: appRouterProvider (redirect + refreshListenable) contra
  // un par de escenarios representativos, no toda la matriz (ya cubierta
  // arriba de forma aislada).
  // -------------------------------------------------------------------
  group('appRouterProvider - wiring end-to-end', () {
    void suppressOverflow(WidgetTester tester) {
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        original?.call(details);
      };
      addTearDown(() {
        FlutterError.onError = original;
        tester.view.resetPhysicalSize();
      });
      tester.view.physicalSize = const Size(1080, 2400);
    }

    testWidgets('sin sesión, /dashboard encadena redirects (requiere active -> '
        'requiere perfil -> público) hasta terminar en /login', (tester) async {
      suppressOverflow(tester);
      late GoRouter router;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authStatusProvider.overrideWith((ref) async => null)],
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ruta pública inicial: sin redirect.
      expect(find.text('Comenzar'), findsOneWidget);

      router.go('/dashboard');
      await tester.pumpAndSettle();

      // /dashboard (requiere active) -> /profile (requiere perfil, sigue
      // sin sesión) -> /login (público). LoginScreen no necesita overrides
      // adicionales (ver login_screen_test.dart).
      expect(find.text('Bienvenido a SIRE'), findsOneWidget);
    });

    testWidgets('guest (con perfil) accede a /my-reservations sin redirect', (
      tester,
    ) async {
      suppressOverflow(tester);
      late GoRouter router;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStatusProvider.overrideWith((ref) async => AccountStatus.guest),
            reservationsRemoteDatasourceProvider.overrideWithValue(
              ReservationsRemoteDatasourceMockImpl(),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/my-reservations');
      await tester.pumpAndSettle();

      expect(find.text('Mis Reservas'), findsWidgets);
      expect(find.text('Bienvenido a SIRE'), findsNothing);
    });
  });
}
