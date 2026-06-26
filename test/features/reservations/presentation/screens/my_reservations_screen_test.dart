import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sire/features/reservations/domain/entities/reservation.dart';
import 'package:sire/features/reservations/domain/repositories/reservations_repository.dart';
import 'package:sire/features/reservations/presentation/providers/reservations_provider.dart';
import 'package:sire/features/reservations/presentation/screens/my_reservations_screen.dart';

class _MockRepo extends Mock implements ReservationsRepository {}

const _pending = Reservation(
  id: '1',
  publicationId: 'pub-1',
  date: 'Hoy',
  startTime: '11:00',
  endTime: '12:00',
  status: ReservationStatus.pending,
  createdAt: '2026-01-01',
  publicationTitle: 'Cancha de fútbol sintética',
);

const _completed = Reservation(
  id: '2',
  publicationId: 'pub-2',
  date: 'Mar 5 may',
  startTime: '11:00',
  endTime: '12:00',
  status: ReservationStatus.completed,
  createdAt: '2026-01-01',
  publicationTitle: 'Consultorio de kinesiología',
);

void main() {
  setUpAll(() {
    registerFallbackValue(ReservationStatus.pending);
  });

  Widget _buildSubject({List<Reservation> seed = const []}) {
    final repo = _MockRepo();
    when(() => repo.getMyReservations()).thenAnswer((_) async => seed);

    final mockRouter = GoRouter(
      initialLocation: '/my-reservations',
      routes: [
        GoRoute(
          path: '/my-reservations',
          builder: (_, __) => const MyReservationsScreen(),
        ),
        GoRoute(
          path: '/feed',
          builder: (_, __) => const Scaffold(body: Text('Feed')),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const Scaffold(body: Text('Perfil')),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const Scaffold(body: Text('Dashboard')),
        ),
        GoRoute(
          path: '/reservation/:id',
          builder: (_, __) => const Scaffold(body: Text('Detalle Reserva')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        reservationsRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp.router(routerConfig: mockRouter),
    );
  }

  testWidgets('MyReservationsScreen muestra título y pestañas', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Mis Reservas'), findsWidgets);
    expect(find.text('Activas'), findsOneWidget);
    expect(find.text('Historial'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('MyReservationsScreen muestra reservas activas por defecto', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(_buildSubject(seed: [_pending, _completed]));
    await tester.pumpAndSettle();

    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Cancha de fútbol sintética'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('MyReservationsScreen cambia a pestaña Historial', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(_buildSubject(seed: [_pending, _completed]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();

    expect(find.text('Completada'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('MyReservationsScreen muestra iconos de navegación', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('MyReservationsScreen toca tarjeta de reserva activa', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(_buildSubject(seed: [_pending]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pendiente').first);
    await tester.pumpAndSettle();

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });
}
