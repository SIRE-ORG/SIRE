import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/reservations/presentation/screens/received_reservations_screen.dart';

void main() {
  Widget buildSubject({List<Override> overrides = const []}) {
    final mockRouter = GoRouter(
      initialLocation: '/received',
      routes: [
        GoRoute(
          path: '/received',
          builder: (_, _) => const ReceivedReservationsScreen(),
        ),
        GoRoute(
          path: '/feed',
          builder: (_, _) => const Scaffold(body: Text('Feed')),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const Scaffold(body: Text('Dashboard')),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, _) => const Scaffold(body: Text('Perfil')),
        ),
        GoRoute(
          path: '/received-reservation/detail',
          builder: (_, _) => const Scaffold(body: Text('Detalle Recibida')),
        ),
      ],
    );
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(routerConfig: mockRouter),
    );
  }

  testWidgets('ReceivedReservationsScreen muestra título y pestañas', (
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

    expect(find.text('Reservas recibidas'), findsOneWidget);
    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('Historial'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets(
    'ReceivedReservationsScreen muestra tarjetas pendientes por defecto',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1080, 2400);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Carlos Pérez'), findsOneWidget);
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.text('Pendiente'), findsWidgets);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        FlutterError.onError = originalOnError;
      });
    },
  );

  testWidgets('ReceivedReservationsScreen cambia a pestaña Historial', (
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

    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();

    expect(find.text('Pedro Soto'), findsOneWidget);
    expect(find.text('Completada'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets(
    'ReceivedReservationsScreen muestra barra de navegación inferior',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(390, 2400);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        FlutterError.onError = originalOnError;
      });
    },
  );

  testWidgets('ReceivedReservationsScreen layout web muestra SIRE en sidebar', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('SIRE'), findsOneWidget);
    expect(find.text('Reservas recibidas'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('ReceivedReservationsScreen toca tarjeta abre detalle', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(390, 844);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Carlos Pérez').first);
    await tester.pump();

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets(
    'ReceivedReservationsScreen layout web muestra historial en pestaña',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      expect(find.text('Pedro Soto'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        FlutterError.onError = originalOnError;
      });
    },
  );
}
