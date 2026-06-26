import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/core/providers/role_provider.dart';
import 'package:sire/features/publications/presentation/screens/my_publications_screen.dart';

void main() {
  Widget _buildSubject({bool isPublisher = true, Size size = const Size(390, 2400)}) {
    final mockRouter = GoRouter(
      initialLocation: '/my-publications',
      routes: [
        GoRoute(
          path: '/my-publications',
          builder: (_, __) => const MyPublicationsScreen(),
        ),
        GoRoute(
          path: '/publication/create',
          builder: (_, __) => const Scaffold(body: Text('Crear publicación')),
        ),
        GoRoute(
          path: '/publication/:id/edit',
          builder: (_, __) => const Scaffold(body: Text('Editar publicación')),
        ),
        GoRoute(
          path: '/feed',
          builder: (_, __) => const Scaffold(body: Text('Feed')),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const Scaffold(body: Text('Dashboard')),
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

  testWidgets('muestra título Mis publicaciones', (tester) async {
    _setup(tester);
    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();
    expect(find.text('Mis publicaciones'), findsWidgets);
  });

  testWidgets('muestra botón para crear publicación', (tester) async {
    _setup(tester);
    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('muestra barra de navegación inferior', (tester) async {
    _setup(tester);
    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('layout web muestra sidebar con Dashboard', (tester) async {
    _setup(tester, size: const Size(1280, 800));
    await tester.pumpWidget(_buildSubject(size: const Size(1280, 800)));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Mis publicaciones'), findsWidgets);
  });
}
