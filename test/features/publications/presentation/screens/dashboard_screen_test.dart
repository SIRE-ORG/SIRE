import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/core/providers/role_provider.dart';
import 'package:sire/features/publications/presentation/screens/dashboard_screen.dart';

void main() {
  Widget _buildSubject({bool isPublisher = true, Size size = const Size(390, 2400)}) {
    final mockRouter = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/my-publications',
          builder: (_, __) => const Scaffold(body: Text('Mis publicaciones')),
        ),
        GoRoute(
          path: '/received-reservations',
          builder: (_, __) => const Scaffold(body: Text('Reservas recibidas')),
        ),
        GoRoute(
          path: '/feed',
          builder: (_, __) => const Scaffold(body: Text('Feed')),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const Scaffold(body: Text('Perfil')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        isPublisherProvider.overrideWith((ref) => isPublisher),
      ],
      child: MaterialApp.router(routerConfig: mockRouter),
    );
  }

  void _setup(WidgetTester tester, {Size size = const Size(390, 2400)}) {
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
    _setup(tester);
    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();
    expect(find.text('Mi Panel'), findsOneWidget);
  });

  testWidgets('muestra sección Mis publicaciones', (tester) async {
    _setup(tester);
    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();
    expect(find.text('Mis publicaciones'), findsWidgets);
  });

  testWidgets('muestra sección Reservas recibidas', (tester) async {
    _setup(tester);
    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();
    expect(find.text('Reservas recibidas'), findsWidgets);
  });

  testWidgets('muestra barra de navegación inferior', (tester) async {
    _setup(tester);
    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('layout web muestra SIRE en sidebar', (tester) async {
    _setup(tester, size: const Size(1280, 800));
    await tester.pumpWidget(_buildSubject(size: const Size(1280, 800)));
    await tester.pumpAndSettle();
    expect(find.text('SIRE'), findsOneWidget);
  });
}
