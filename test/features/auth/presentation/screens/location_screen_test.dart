import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/auth/presentation/screens/location_screen.dart';

void main() {
  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/location',
      routes: [
        GoRoute(path: '/location', builder: (_, _) => const LocationScreen()),
        GoRoute(
          path: '/feed',
          builder: (_, _) => const Scaffold(body: Text('Pantalla Feed')),
        ),
      ],
    );
  }

  testWidgets('LocationScreen muestra contenido principal', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      if (details.exceptionAsString().contains('Unable to load asset')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pump();

    expect(find.text('¿Dónde estás?'), findsOneWidget);
    expect(find.text('Permitir ubicación'), findsOneWidget);
    expect(find.text('Seleccionar ubicación manualmente'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('LocationScreen navega a /feed al pulsar Permitir ubicación', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      if (details.exceptionAsString().contains('Unable to load asset')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pump();

    await tester.tap(find.text('Permitir ubicación'));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla Feed'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('LocationScreen navega a /feed al pulsar selección manual', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      if (details.exceptionAsString().contains('Unable to load asset')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pump();

    await tester.tap(find.text('Seleccionar ubicación manualmente'));
    await tester.pumpAndSettle();

    // Se abre el selector de región; al elegir una, navega al feed.
    await tester.tap(find.text('Región de Arica y Parinacota'));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla Feed'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('LocationScreen muestra aviso de privacidad', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      if (details.exceptionAsString().contains('Unable to load asset')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pump();

    expect(
      find.textContaining('Tu ubicación solo se usa para filtrar el feed'),
      findsOneWidget,
    );

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });
}
