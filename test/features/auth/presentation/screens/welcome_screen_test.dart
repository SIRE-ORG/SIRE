import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/auth/presentation/screens/welcome_screen.dart';

void main() {
  testWidgets('WelcomeScreen muestra contenido principal', (
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

    final mockRouter = GoRouter(
      initialLocation: '/welcome',
      routes: [
        GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
        GoRoute(
          path: '/location',
          builder: (_, _) => const Scaffold(body: Text('Pantalla Location')),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Pantalla Login')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: mockRouter));
    await tester.pump();

    expect(
      find.text('Sistema Integral de Reservas Estratégicas.'),
      findsOneWidget,
    );
    expect(
      find.text('Encuentra y reserva espacios cerca de ti.'),
      findsOneWidget,
    );
    expect(find.text('Comenzar'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Ya tengo cuenta. '), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('WelcomeScreen navega a /location al pulsar Comenzar', (
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

    final mockRouter = GoRouter(
      initialLocation: '/welcome',
      routes: [
        GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
        GoRoute(
          path: '/location',
          builder: (_, _) => const Scaffold(body: Text('Pantalla Location')),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Pantalla Login')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: mockRouter));
    await tester.pump();

    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla Location'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('WelcomeScreen navega a /login al pulsar Iniciar sesión', (
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

    final mockRouter = GoRouter(
      initialLocation: '/welcome',
      routes: [
        GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
        GoRoute(
          path: '/location',
          builder: (_, _) => const Scaffold(body: Text('Pantalla Location')),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Pantalla Login')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: mockRouter));
    await tester.pump();

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla Login'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });
}
