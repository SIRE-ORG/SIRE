import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/feed/presentation/screens/publication_detail_screen.dart';

void main() {
  Widget buildSubject() {
    final mockRouter = GoRouter(
      initialLocation: '/publication/pub-001',
      routes: [
        GoRoute(
          path: '/publication/:id',
          builder: (_, state) => PublicationDetailScreen(
            id: state.pathParameters['id'] ?? 'pub-001',
          ),
          routes: [
            GoRoute(
              path: 'confirm',
              builder: (_, _) => const Scaffold(body: Text('Confirmación')),
            ),
          ],
        ),
      ],
    );
    return ProviderScope(child: MaterialApp.router(routerConfig: mockRouter));
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('PublicationDetailScreen muestra título de la publicación', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      if (details.exceptionAsString().contains('NetworkImageLoadException')) {
        return;
      }
      if (details.exceptionAsString().contains('statusCode: 400')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await pumpScreen(tester);

    expect(find.text('Detalles Publicación'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('PublicationDetailScreen muestra información de la cancha', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      if (details.exceptionAsString().contains('NetworkImageLoadException')) {
        return;
      }
      if (details.exceptionAsString().contains('statusCode: 400')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await pumpScreen(tester);

    expect(find.text('Cancha de fútbol El Estadio'), findsOneWidget);
    expect(find.text('Pedro González'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('PublicationDetailScreen muestra selector de fecha', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      if (details.exceptionAsString().contains('NetworkImageLoadException')) {
        return;
      }
      if (details.exceptionAsString().contains('statusCode: 400')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await pumpScreen(tester);

    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    final currentMonthName = months[DateTime.now().month - 1];

    expect(find.textContaining(currentMonthName), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('PublicationDetailScreen muestra slots de tiempo', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      if (details.exceptionAsString().contains('NetworkImageLoadException')) {
        return;
      }
      if (details.exceptionAsString().contains('statusCode: 400')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await pumpScreen(tester);

    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('PublicationDetailScreen muestra categoría Deportes', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      if (details.exceptionAsString().contains('NetworkImageLoadException')) {
        return;
      }
      if (details.exceptionAsString().contains('statusCode: 400')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await pumpScreen(tester);

    expect(find.text('Deportes'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('tap Reservar sin slot seleccionado muestra SnackBar de error', (
    tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      if (details.exceptionAsString().contains('NetworkImageLoadException')) {
        return;
      }
      if (details.exceptionAsString().contains('statusCode: 400')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await pumpScreen(tester);

    await tester.tap(find.text('Reservar'));
    await tester.pump();

    expect(find.text('Por favor selecciona un horario'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });
}
