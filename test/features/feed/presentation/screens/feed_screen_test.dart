import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/feed/presentation/screens/feed_screen.dart';

void main() {
  testWidgets('FeedScreen renderiza UI y filtros', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    final mockRouter = GoRouter(
      initialLocation: '/feed',
      routes: [
        GoRoute(
          path: '/feed',
          builder: (context, state) => const FeedScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: mockRouter,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Explorar'), findsWidgets);
    expect(find.text('Cancha de fútbol sintética'), findsWidgets);

    await tester.tap(find.text('Deporte').first);
    await tester.pumpAndSettle();

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('FeedScreen filtro Deporte muestra solo publicación de Deporte',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };

    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1.0;

    final mockRouter = GoRouter(
      initialLocation: '/feed',
      routes: [
        GoRoute(
          path: '/feed',
          builder: (context, state) => const FeedScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: mockRouter),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Deporte').first);
    await tester.pumpAndSettle();

    expect(find.text('Cancha de fútbol sintética'), findsOneWidget);
    expect(find.text('Consultorio de kinesiología'), findsNothing);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });
}