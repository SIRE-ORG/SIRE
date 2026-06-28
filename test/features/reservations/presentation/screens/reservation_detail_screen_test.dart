import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/features/reservations/domain/entities/reservation.dart';
import 'package:sire/features/reservations/domain/repositories/reservations_repository.dart';
import 'package:sire/features/reservations/presentation/providers/reservations_provider.dart';
import 'package:sire/features/reservations/presentation/screens/reservation_detail_screen.dart';

class _MockReservationsRepository extends Mock
    implements ReservationsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(ReservationStatus.pending);
  });

  Widget buildSubject({
    required String status,
    List<Override> overrides = const [],
  }) {
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
        GoRoute(
          path: '/my-reservations',
          builder: (_, _) => const Scaffold(body: Text('Mis Reservas')),
        ),
      ],
    );
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(routerConfig: mockRouter),
    );
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

  testWidgets(
    'tap Cancelar reserva cuando falla muestra SnackBar de no disponible',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1080, 2400);

      final mockRepo = _MockReservationsRepository();
      when(() => mockRepo.cancelReservation(id: any(named: 'id'))).thenThrow(
        ServerException(code: 'ENDPOINT_NOT_AVAILABLE', message: 'no impl'),
      );

      await tester.pumpWidget(
        buildSubject(
          status: 'pendiente',
          overrides: [
            reservationsRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar reserva'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Función no disponible aún'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        FlutterError.onError = originalOnError;
      });
    },
  );
}
