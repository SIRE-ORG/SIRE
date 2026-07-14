import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/feed/presentation/screens/publication_detail_screen.dart';
import 'package:sire/features/publications/data/datasources/publications_remote_datasource_mock_impl.dart';
import 'package:sire/features/publications/presentation/providers/my_publications_provider.dart';

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
              builder: (_, state) => Scaffold(
                body: Text(
                  'Confirmación date=${state.uri.queryParameters['date']}',
                ),
              ),
            ),
          ],
        ),
      ],
    );
    return ProviderScope(
      // El detalle sale de publicationDetailProvider -> el datasource mock
      // trae el fixture "Cancha de fútbol El Estadio" con owner "Pedro
      // González" que esta pantalla verifica. Se fuerza explícitamente
      // porque ApiFlags.useMocks ahora es false por defecto (backend real).
      overrides: [
        publicationsRemoteDatasourceProvider.overrideWithValue(
          PublicationsRemoteDatasourceMockImpl(),
        ),
      ],
      child: MaterialApp.router(routerConfig: mockRouter),
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  // El fixture `mock-pub-1` (PublicationsRemoteDatasourceMockImpl) cierra los
  // domingos (`dayOverrides: SUNDAY closed`); la pantalla arranca con
  // `_selectedDate = DateTime.now()`. Si el test corre un domingo, "hoy" no
  // tiene slots y las aserciones de horario fallan sin que haya ningún bug
  // real. Se selecciona explícitamente el primer día abierto (nunca dos
  // domingos seguidos) antes de interactuar con los horarios.
  DateTime firstOpenDate() {
    var date = DateTime.now();
    if (date.weekday == DateTime.sunday) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  Future<void> selectFirstOpenDateIfNeeded(WidgetTester tester) async {
    if (DateTime.now().weekday == DateTime.sunday) {
      await tester.tap(find.byType(GestureDetector).at(1));
      await tester.pump();
    }
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
    // Ubicación (ícono de pin) y autor (ícono de tienda) son campos
    // distintos: antes el pin mostraba por error el nombre del publicador.
    expect(find.text('Temuco'), findsOneWidget);
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
    await selectFirstOpenDateIfNeeded(tester);

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

  testWidgets(
    'tap Reservar con slot seleccionado envía la fecha del slot en ISO '
    '(YYYY-MM-DD) a /confirm, no un texto libre sin año',
    (tester) async {
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
      await selectFirstOpenDateIfNeeded(tester);

      await tester.tap(find.text('09:00'));
      await tester.pump();
      await tester.tap(find.text('Reservar'));
      await tester.pumpAndSettle();

      final selected = firstOpenDate();
      final expectedIso =
          '${selected.year.toString().padLeft(4, '0')}-'
          '${selected.month.toString().padLeft(2, '0')}-'
          '${selected.day.toString().padLeft(2, '0')}';
      expect(find.text('Confirmación date=$expectedIso'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        FlutterError.onError = originalOnError;
      });
    },
  );
}
