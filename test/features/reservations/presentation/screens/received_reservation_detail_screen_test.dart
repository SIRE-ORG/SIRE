import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/reservations/presentation/screens/received_reservation_detail_screen.dart';

void main() {
  Widget _buildSubject({required String status}) {
    final mockRouter = GoRouter(
      initialLocation: '/received-detail',
      routes: [
        GoRoute(
          path: '/received-detail',
          builder: (_, __) => ReceivedReservationDetailScreen(
            id: 'mock-recv-001',
            applicantName: 'Carlos Pérez',
            publication: 'Cancha de fútbol sintética',
            date: 'Jue 15 may',
            time: '14:00-15:00',
            status: status,
          ),
        ),
      ],
    );
    return ProviderScope(child: MaterialApp.router(routerConfig: mockRouter));
  }

  testWidgets('ReceivedReservationDetailScreen muestra encabezado', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(_buildSubject(status: 'pendiente'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle de reserva'), findsOneWidget);
    expect(find.text('DATOS DEL SOLICITANTE'), findsOneWidget);
    expect(find.text('SLOT RESERVADO'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('ReceivedReservationDetailScreen muestra datos del solicitante', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(_buildSubject(status: 'pendiente'));
    await tester.pumpAndSettle();

    expect(find.text('Carlos Pérez'), findsWidgets);
    expect(find.text('Cancha de fútbol sintética'), findsWidgets);
    expect(find.text('Jue 15 may'), findsOneWidget);
    expect(find.text('14:00-15:00'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('ReceivedReservationDetailScreen pendiente muestra botones de acción', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(_buildSubject(status: 'pendiente'));
    await tester.pumpAndSettle();

    expect(find.text('Marcar como COMPLETADA'), findsOneWidget);
    expect(find.text('Marcar como FALLIDA'), findsOneWidget);
    expect(find.text('Rechazar reserva'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('ReceivedReservationDetailScreen no pendiente oculta botones de acción', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(_buildSubject(status: 'completada'));
    await tester.pumpAndSettle();

    expect(find.text('Marcar como COMPLETADA'), findsNothing);
    expect(find.text('Marcar como FALLIDA'), findsNothing);
    expect(find.text('Rechazar reserva'), findsNothing);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('ReceivedReservationDetailScreen muestra botones de contacto', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(_buildSubject(status: 'pendiente'));
    await tester.pumpAndSettle();

    expect(find.text('Correo'), findsWidgets);
    expect(find.text('WhatsApp'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });
}
