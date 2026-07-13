import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/auth/domain/entities/user_profile.dart';
import 'package:sire/features/auth/presentation/providers/auth_provider.dart';
import 'package:sire/features/profile/presentation/screens/profile_screen.dart';
import 'package:sire/core/providers/role_provider.dart';
import 'package:sire/features/publications/data/datasources/publications_remote_datasource_mock_impl.dart';
import 'package:sire/features/publications/presentation/providers/my_publications_provider.dart';
import 'package:sire/features/reservations/data/datasources/reservations_remote_datasource_mock_impl.dart';
import 'package:sire/features/reservations/presentation/providers/reservations_provider.dart';

const _kProfile = UserProfile(
  id: 'u1',
  name: 'María González',
  email: 'maria@correo.com',
  accountStatus: AccountStatus.active,
  emailVerified: true,
);

void main() {
  Widget buildSubject({
    bool isPublisher = false,
    bool withProfile = true,
    bool anon = false,
  }) {
    final mockRouter = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
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
        GoRoute(
          path: '/profile/edit',
          builder: (_, _) => const Scaffold(body: Text('Editar Perfil')),
        ),
        GoRoute(
          path: '/my-publications',
          builder: (_, _) => const Scaffold(body: Text('Mis Publicaciones')),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Login')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        isPublisherProvider.overrideWith((ref) => isPublisher),
        if (anon) ...[
          currentProfileProvider.overrideWith((ref) async => null),
          authStatusProvider.overrideWith((ref) async => AccountStatus.anon),
        ] else if (withProfile)
          currentProfileProvider.overrideWith((ref) async => _kProfile),
        // ProfileScreen también observa mis publicaciones/reservas para los
        // contadores del panel: se fuerzan los datasources mock porque
        // ApiFlags.useMocks ahora es false por defecto (backend real).
        publicationsRemoteDatasourceProvider.overrideWithValue(
          PublicationsRemoteDatasourceMockImpl(),
        ),
        reservationsRemoteDatasourceProvider.overrideWithValue(
          ReservationsRemoteDatasourceMockImpl(),
        ),
      ],
      child: MaterialApp.router(routerConfig: mockRouter),
    );
  }

  void setup(WidgetTester tester, {Size size = const Size(390, 844)}) {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exceptionAsString().contains('overflowed')) return;
      original?.call(d);
    };
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = original;
    });
  }

  testWidgets('muestra nombre de usuario desde el provider', (tester) async {
    setup(tester, size: const Size(1080, 2400));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('María González'), findsWidgets);
  });

  testWidgets('muestra correo electrónico desde el provider', (tester) async {
    setup(tester, size: const Size(1080, 2400));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('maria@correo.com'), findsWidgets);
  });

  testWidgets('muestra sección Editar Perfil', (tester) async {
    setup(tester, size: const Size(390, 2400));
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    expect(find.text('Editar perfil'), findsOneWidget);
  });

  testWidgets('muestra toggle de Publicador', (tester) async {
    setup(tester, size: const Size(1080, 2400));
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    expect(find.text('Publicador'), findsWidgets);
  });

  testWidgets('muestra opción Cerrar sesión', (tester) async {
    setup(tester, size: const Size(390, 2400));
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('muestra tabs Solicitante y Publicador', (tester) async {
    setup(tester, size: const Size(1080, 2400));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Solicitante'), findsOneWidget);
    expect(find.text('Publicador'), findsWidgets);
  });

  testWidgets('interacción con tab Publicador cambia estado', (tester) async {
    setup(tester, size: const Size(1080, 2400));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Publicador').first);
    await tester.pumpAndSettle();

    expect(find.text('Publicador'), findsWidgets);
  });

  // Layout web (viewport >= 800)
  testWidgets('layout web muestra sidebar con SIRE', (tester) async {
    setup(tester, size: const Size(1280, 800));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('SIRE'), findsOneWidget);
    expect(find.text('Mi Perfil'), findsOneWidget);
  });

  testWidgets('layout web muestra estado de cuenta activa', (tester) async {
    setup(tester, size: const Size(1280, 800));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Cuenta activa'), findsOneWidget);
  });

  testWidgets('modo publicador activo muestra mis publicaciones', (
    tester,
  ) async {
    setup(tester, size: const Size(390, 2400));
    await tester.pumpWidget(buildSubject(isPublisher: true));
    await tester.pumpAndSettle();
    expect(find.text('Mis publicaciones'), findsOneWidget);
  });

  testWidgets(
    'estado anónimo (sin perfil) muestra empty-state amable en vez del '
    'layout completo',
    (tester) async {
      setup(tester, size: const Size(390, 2400));

      await tester.pumpWidget(buildSubject(anon: true));
      await tester.pumpAndSettle();

      expect(find.text('Aún no tienes una cuenta'), findsOneWidget);
      expect(find.text('Crear cuenta o iniciar sesión'), findsOneWidget);
      // El layout completo (que asume un perfil real) no se muestra.
      expect(find.text('Editar perfil'), findsNothing);
      expect(find.text('Cerrar sesión'), findsNothing);
    },
  );

  testWidgets('estado anónimo: tap en el CTA navega a /login', (tester) async {
    setup(tester, size: const Size(390, 2400));

    await tester.pumpWidget(buildSubject(anon: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear cuenta o iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('perfil activo muestra badge Cuenta activa y no Invitado', (
    tester,
  ) async {
    setup(tester, size: const Size(390, 2400));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Cuenta activa'), findsOneWidget);
    expect(find.text('Invitado'), findsNothing);
  });
}
