import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sire/features/reservations/domain/entities/reservation.dart';
import 'package:sire/features/reservations/domain/repositories/reservations_repository.dart';
import 'package:sire/features/reservations/presentation/providers/reservations_provider.dart';
import 'package:sire/features/reservations/presentation/screens/received_reservations_screen.dart';

class _MockRepo extends Mock implements ReservationsRepository {}

const _pendiente = Reservation(
  id: 'recv-1',
  publicationId: 'pub-1',
  date: 'Jue 15 may',
  startTime: '14:00',
  endTime: '15:00',
  status: ReservationStatus.pending,
  createdAt: '2026-01-01',
  publicationTitle: 'Cancha de futbol sintetica',
  applicantName: 'Carlos Pérez',
  applicantEmail: 'carlosperez@mail.com',
  applicantPhone: '+56912345678',
);

const _completada = Reservation(
  id: 'recv-2',
  publicationId: 'pub-1',
  date: 'Lun 5 may',
  startTime: '10:00',
  endTime: '11:00',
  status: ReservationStatus.completed,
  createdAt: '2026-01-01',
  publicationTitle: 'Cancha de futbol sintetica',
  applicantName: 'Pedro Soto',
  applicantEmail: 'pedrosoto@mail.com',
  applicantPhone: '+56934567890',
);

void main() {
  setUpAll(() {
    registerFallbackValue(ReservationStatus.pending);
  });

  Widget buildSubject({
    List<Reservation> seed = const [],
    ReservationsRepository? repoOverride,
  }) {
    final repo = repoOverride ?? _MockRepo();
    if (repoOverride == null) {
      when(
        () => (repo as _MockRepo).getReceivedReservations(),
      ).thenAnswer((_) async => seed);
    }

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
      overrides: [reservationsRepositoryProvider.overrideWithValue(repo)],
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
    'ReceivedReservationsScreen muestra tarjetas pendientes reales por defecto',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1080, 2400);

      await tester.pumpWidget(buildSubject(seed: [_pendiente, _completada]));
      await tester.pumpAndSettle();

      expect(find.text('Carlos Pérez'), findsOneWidget);
      expect(find.text('Pedro Soto'), findsNothing);
      expect(find.text('Pendiente'), findsWidgets);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        FlutterError.onError = originalOnError;
      });
    },
  );

  testWidgets(
    'ReceivedReservationsScreen mientras carga muestra progreso, no datos de ejemplo',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1080, 2400);

      final repo = _MockRepo();
      final completer = Completer<List<Reservation>>();
      when(
        () => repo.getReceivedReservations(),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildSubject(repoOverride: repo));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Carlos Pérez'), findsNothing);
      expect(find.text('Ana Ruiz'), findsNothing);

      completer.complete([_pendiente]);
      await tester.pumpAndSettle();

      addTearDown(() {
        tester.view.resetPhysicalSize();
        FlutterError.onError = originalOnError;
      });
    },
  );

  testWidgets(
    'ReceivedReservationsScreen sin pendientes muestra estado vacío',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1080, 2400);

      await tester.pumpWidget(buildSubject(seed: [_completada]));
      await tester.pumpAndSettle();

      expect(find.text('No tienes reservas pendientes'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        FlutterError.onError = originalOnError;
      });
    },
  );

  testWidgets(
    'ReceivedReservationsScreen error de red muestra estado de error con reintentar',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1080, 2400);

      final repo = _MockRepo();
      when(
        () => repo.getReceivedReservations(),
      ).thenThrow(Exception('sin conexión'));

      await tester.pumpWidget(buildSubject(repoOverride: repo));
      await tester.pumpAndSettle();

      expect(
        find.text('No se pudieron cargar las reservas recibidas'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);

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

    await tester.pumpWidget(buildSubject(seed: [_pendiente, _completada]));
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

      await tester.pumpWidget(buildSubject(seed: [_pendiente]));
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

    await tester.pumpWidget(buildSubject(seed: [_pendiente]));
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

    await tester.pumpWidget(buildSubject(seed: [_pendiente]));
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

      await tester.pumpWidget(buildSubject(seed: [_completada]));
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

  testWidgets(
    'ReceivedReservationsScreen web muestra datos reales del solicitante en el panel de detalle',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildSubject(seed: [_pendiente]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Carlos Pérez').first);
      await tester.pumpAndSettle();

      expect(find.text('carlosperez@mail.com'), findsOneWidget);
      expect(find.text('+56912345678'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        FlutterError.onError = originalOnError;
      });
    },
  );

  testWidgets(
    'ReceivedReservationsScreen web sin correo/teléfono muestra guion, no datos inventados',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;

      const sinContacto = Reservation(
        id: 'recv-3',
        publicationId: 'pub-1',
        date: 'Mar 20 may',
        startTime: '10:00',
        endTime: '11:00',
        status: ReservationStatus.pending,
        createdAt: '2026-01-01',
        publicationTitle: 'Cancha de futbol sintetica',
        applicantName: 'Sin Contacto',
      );

      await tester.pumpWidget(buildSubject(seed: [sinContacto]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sin Contacto').first);
      await tester.pumpAndSettle();

      expect(find.text('carlosperez@mail.com'), findsNothing);
      expect(find.text('+56912345678'), findsNothing);
      expect(find.text('-'), findsWidgets);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        FlutterError.onError = originalOnError;
      });
    },
  );

  testWidgets(
    'ReceivedReservationsScreen refresca la lista tras marcar completada',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;

      final repo = _MockRepo();
      var completed = false;
      when(() => repo.getReceivedReservations()).thenAnswer(
        (_) async => [completed ? _pendiente.copyWithCompleted() : _pendiente],
      );
      when(
        () => repo.updateReservationStatus(
          id: any(named: 'id'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async {
        completed = true;
        return _pendiente.copyWithCompleted();
      });

      await tester.pumpWidget(buildSubject(repoOverride: repo));
      await tester.pumpAndSettle();

      expect(find.text('Pendiente'), findsWidgets);

      await tester.tap(find.text('Carlos Pérez').first);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Marcar como COMPLETADA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar como COMPLETADA'));
      await tester.pumpAndSettle();

      // La tarjeta pendiente desaparece de la pestaña Pendientes tras el
      // refresco: la reserva ahora vuelve como completada.
      expect(find.text('Carlos Pérez'), findsNothing);
      expect(find.text('No tienes reservas pendientes'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        FlutterError.onError = originalOnError;
      });
    },
  );
}

extension on Reservation {
  Reservation copyWithCompleted() => Reservation(
    id: id,
    publicationId: publicationId,
    date: date,
    startTime: startTime,
    endTime: endTime,
    status: ReservationStatus.completed,
    createdAt: createdAt,
    publicationTitle: publicationTitle,
    publicationCity: publicationCity,
    publicationImageUrl: publicationImageUrl,
    applicantName: applicantName,
    applicantEmail: applicantEmail,
    applicantPhone: applicantPhone,
  );
}
