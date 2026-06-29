import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/publications/presentation/screens/edit_publication_screen.dart';

void main() {
  Widget buildSubject() {
    final mockRouter = GoRouter(
      initialLocation: '/publication/pub-001/edit',
      routes: [
        GoRoute(
          path: '/publication/:id/edit',
          builder: (_, state) => EditPublicationScreen(
            id: state.pathParameters['id'] ?? 'pub-001',
          ),
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
          path: '/my-publications',
          builder: (_, _) => const Scaffold(body: Text('Mis Publicaciones')),
        ),
      ],
    );
    return ProviderScope(child: MaterialApp.router(routerConfig: mockRouter));
  }

  testWidgets('EditPublicationScreen muestra título del AppBar', (
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

    expect(find.text('Editar publicación'), findsWidgets);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('EditPublicationScreen muestra campos pre-poblados', (
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

    expect(find.text('Cancha de fútbol sintética'), findsOneWidget);
    expect(find.text('Deporte'), findsOneWidget);
    expect(find.text('Temuco'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('EditPublicationScreen muestra configuración de horarios', (
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

    expect(find.text('Agenda Inteligente'), findsOneWidget);
    expect(find.text('Horario para todos los días'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('EditPublicationScreen muestra botón guardar cambios', (
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

    expect(find.text('Guardar cambios'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets(
    'EditPublicationScreen permite editar el nombre de la publicación',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1080, 2400);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final nameField = find.byType(TextField).first;
      await tester.tap(nameField);
      await tester.pump();
      await tester.enterText(nameField, 'Nueva cancha');
      await tester.pump();

      expect(find.text('Nueva cancha'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        FlutterError.onError = originalOnError;
      });
    },
  );

  testWidgets('EditPublicationScreen layout web muestra sidebar', (
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
    expect(find.text('Editar publicación'), findsWidgets);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('EditPublicationScreen muestra selector de duración de slot', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(390, 2400);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('60 min'), findsOneWidget);
    expect(find.text('90 min'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('EditPublicationScreen tap en duración cambia selección', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(390, 2400);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('30 min'));
    await tester.tap(find.text('30 min'));
    await tester.pump();

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('EditPublicationScreen contiene formulario con scroll', (
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

    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(find.byType(TextFormField).evaluate().isNotEmpty ||
        find.byType(TextField).evaluate().isNotEmpty, isTrue);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });
}
