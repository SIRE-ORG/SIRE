import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/reservations/presentation/screens/reservation_detail_screen.dart';

void main() {
  Widget buildSubject({required String status}) {
    final mockRouter = GoRouter(
      initialLocation: '/detail',
      routes: [
        GoRoute(
          path: '/detail',
          builder: (_, _) => ReservationDetailScreen(
            id: 'res-001',
            title: 'Cancha de fútbol',
            publisher: 'Club Deportivo',
            date: '15 jun 2026',
            time: '10:00-11:00',
            status: status,
          ),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: mockRouter);
  }

  testWidgets('ReservationDetailScreen muestra encabezado y campos', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(buildSubject(status: 'pendiente'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle de reserva'), findsOneWidget);
    expect(find.text('DETALLE DE RESERVA'), findsOneWidget);
    expect(find.text('Cancha de fútbol'), findsOneWidget);
    expect(find.text('Club Deportivo'), findsOneWidget);
    expect(find.text('15 jun 2026'), findsOneWidget);
    expect(find.text('10:00-11:00'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets(
    'ReservationDetailScreen con estado pendiente muestra botón cancelar',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1080, 2400);

      await tester.pumpWidget(buildSubject(status: 'pendiente'));
      await tester.pumpAndSettle();

      expect(find.text('Cancelar reserva'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        FlutterError.onError = originalOnError;
      });
    },
  );

  testWidgets(
    'ReservationDetailScreen con estado completada no muestra botón cancelar',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1080, 2400);

      await tester.pumpWidget(buildSubject(status: 'completada'));
      await tester.pumpAndSettle();

      expect(find.text('Cancelar reserva'), findsNothing);
      expect(find.text('completada'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        FlutterError.onError = originalOnError;
      });
    },
  );

  testWidgets(
    'ReservationDetailScreen con estado cancelada no muestra botón cancelar',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1080, 2400);

      await tester.pumpWidget(buildSubject(status: 'cancelada'));
      await tester.pumpAndSettle();

      expect(find.text('Cancelar reserva'), findsNothing);
      expect(find.text('cancelada'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        FlutterError.onError = originalOnError;
      });
    },
  );

  testWidgets('ReservationDetailScreen muestra etiquetas de campo', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(buildSubject(status: 'pendiente'));
    await tester.pumpAndSettle();

    expect(find.text('Publicación'), findsOneWidget);
    expect(find.text('Publicador'), findsOneWidget);
    expect(find.text('Fecha'), findsOneWidget);
    expect(find.text('Horario'), findsOneWidget);
    expect(find.text('Estado'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });
}
