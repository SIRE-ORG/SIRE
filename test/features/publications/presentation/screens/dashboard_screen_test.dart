import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/core/providers/role_provider.dart';
import 'package:sire/features/publications/data/datasources/publications_remote_datasource_mock_impl.dart';
import 'package:sire/features/publications/presentation/providers/my_publications_provider.dart';
import 'package:sire/features/publications/presentation/screens/dashboard_screen.dart';
import 'package:sire/features/reservations/data/datasources/reservations_remote_datasource_mock_impl.dart';
import 'package:sire/features/reservations/presentation/providers/reservations_provider.dart';

void main() {
  Widget buildSubject({
    bool isPublisher = true,
    Size size = const Size(390, 2400),
  }) {
    final mockRouter = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
        GoRoute(
          path: '/my-publications',
          builder: (_, _) => const Scaffold(body: Text('Mis publicaciones')),
        ),
        GoRoute(
          path: '/received-reservations',
          builder: (_, _) => const Scaffold(body: Text('Reservas recibidas')),
        ),
        GoRoute(
          path: '/feed',
          builder: (_, _) => const Scaffold(body: Text('Feed')),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, _) => const Scaffold(body: Text('Perfil')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        isPublisherProvider.overrideWith((ref) => isPublisher),
        // DashboardScreen observa mis publicaciones y reservas recibidas:
        // se fuerzan los datasources mock porque ApiFlags.useMocks ahora es
        // false por defecto (backend real).
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

  void setup(WidgetTester tester, {Size size = const Size(390, 2400)}) {
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

  testWidgets('muestra título Mi Panel', (tester) async {
    setup(tester);
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    expect(find.text('Mi Panel'), findsOneWidget);
  });

  testWidgets('muestra sección Mis publicaciones', (tester) async {
    setup(tester);
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    expect(find.text('Mis publicaciones'), findsWidgets);
  });

  testWidgets('muestra sección Reservas recibidas', (tester) async {
    setup(tester);
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    expect(find.text('Reservas recibidas'), findsWidgets);
  });

  testWidgets('muestra barra de navegación inferior', (tester) async {
    setup(tester);
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('layout web muestra SIRE en sidebar', (tester) async {
    setup(tester, size: const Size(1280, 800));
    await tester.pumpWidget(buildSubject(size: const Size(1280, 800)));
    await tester.pumpAndSettle();
    expect(find.text('SIRE'), findsOneWidget);
  });

  // S3-1 (regresión): al entrar directo al dashboard, las stats mostraban
  // "0 publicaciones activas" hasta que otra pantalla (my_publications)
  // disparara el fetch del mismo provider y dejara el valor en caché.
  testWidgets(
    'muestra el conteo real de las stats al entrar, sin visitar el listado '
    'antes',
    (tester) async {
      setup(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Datos del mock: 2 publicaciones propias (1 activa), 3 reservas
      // recibidas (2 pendientes, 1 completada). "1" aparece en Publicaciones
      // Activas y en Completadas; "2" solo en Pendientes por revisar.
      expect(find.text('1'), findsNWidgets(2));
      expect(find.text('2'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    },
  );

  testWidgets(
    'mientras carga muestra loading en las stats y nunca un 0 falso',
    (tester) async {
      setup(tester);
      await tester.pumpWidget(buildSubject());

      // Primer frame: los providers aún están en AsyncLoading (el fetch del
      // mock resuelve en el siguiente ciclo). Antes del fix acá se veía "0".
      expect(find.text('0'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNWidgets(3));

      // Al resolver el fetch, los spinners dan paso a los conteos reales.
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('1'), findsNWidgets(2));
      expect(find.text('2'), findsOneWidget);
    },
  );
}
