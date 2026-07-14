import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sire/features/auth/domain/repositories/auth_repository.dart';
import 'package:sire/features/auth/presentation/providers/auth_provider.dart';
import 'package:sire/features/auth/presentation/screens/welcome_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    when(() => mockRepository.signInAnonymously()).thenAnswer((_) async {});
  });

  Widget buildSubject() {
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

    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
      child: MaterialApp.router(routerConfig: mockRouter),
    );
  }

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

    await tester.pumpWidget(buildSubject());
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

  testWidgets(
    'WelcomeScreen inicia sesion anonima y navega a /location al pulsar '
    'Comenzar',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        if (details.exceptionAsString().contains('Unable to load asset')) {
          return;
        }
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      expect(find.text('Pantalla Location'), findsOneWidget);
      verify(() => mockRepository.signInAnonymously()).called(1);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        FlutterError.onError = originalOnError;
      });
    },
  );

  testWidgets(
    'WelcomeScreen con signInAnonymously fallido igual navega a /location',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        if (details.exceptionAsString().contains('Unable to load asset')) {
          return;
        }
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;

      when(
        () => mockRepository.signInAnonymously(),
      ).thenThrow(Exception('sin red'));

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      // El feed es público: aunque falle la sesión anónima, la navegación
      // no se bloquea (solo se avisa con un SnackBar).
      expect(find.text('Pantalla Location'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        FlutterError.onError = originalOnError;
      });
    },
  );

  testWidgets('WelcomeScreen navega a /location aunque signInAnonymously nunca '
      'resuelva (timeout de red móvil)', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      if (details.exceptionAsString().contains('Unable to load asset')) {
        return;
      }
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    // Future que nunca se completa: simula una red móvil que nunca
    // responde.
    when(
      () => mockRepository.signInAnonymously(),
    ).thenAnswer((_) => Completer<void>().future);

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.text('Comenzar'));
    await tester.pump();

    // Sigue en welcome, mostrando el estado de carga: el timeout aún no
    // se cumplió.
    expect(find.text('Comenzando...'), findsOneWidget);
    expect(find.text('Pantalla Location'), findsNothing);

    // Se cumple el timeout de 6s configurado en _comenzar: navega igual.
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla Location'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets(
    'WelcomeScreen un segundo tap mientras la operación está en vuelo no '
    're-dispara signInAnonymously',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        if (details.exceptionAsString().contains('Unable to load asset')) {
          return;
        }
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;

      final completer = Completer<void>();
      when(
        () => mockRepository.signInAnonymously(),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      // Segundo tap con la operación ya en vuelo (el texto ya cambió a
      // "Comenzando..."): no debe re-disparar.
      expect(find.text('Comenzando...'), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      verify(() => mockRepository.signInAnonymously()).called(1);

      completer.complete();
      await tester.pumpAndSettle();

      expect(find.text('Pantalla Location'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        FlutterError.onError = originalOnError;
      });
    },
  );

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

    await tester.pumpWidget(buildSubject());
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
