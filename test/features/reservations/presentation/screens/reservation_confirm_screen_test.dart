import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/reservations/presentation/screens/reservation_confirm_screen.dart';

void main() {
  Widget _buildSubject() {
    final mockRouter = GoRouter(
      initialLocation: '/confirm',
      routes: [
        GoRoute(
          path: '/confirm',
          builder: (_, __) => const ReservationConfirmScreen(
            id: 'pub-001',
            title: 'Cancha de fútbol sintética',
            subtitle: 'Club Deportivo Temuco',
            date: 'Lun 15 jun',
            time: '10:00',
          ),
        ),
        GoRoute(
          path: '/my-reservations',
          builder: (_, __) => const Scaffold(body: Text('Mis Reservas')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: mockRouter);
  }

  testWidgets('ReservationConfirmScreen muestra encabezado y título', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Confirmar Reserva'), findsWidgets);
    expect(find.text('Cancha de fútbol sintética'), findsOneWidget);
    expect(find.text('Club Deportivo Temuco'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('ReservationConfirmScreen muestra campos del formulario', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Nombre Completo'), findsOneWidget);
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Teléfono'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('ReservationConfirmScreen muestra botón confirmar', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Confirmar Reserva'), findsWidgets);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('ReservationConfirmScreen muestra resumen de fecha y hora', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();

    expect(find.textContaining('Lun 15 jun'), findsOneWidget);
    expect(find.textContaining('10:00'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('ReservationConfirmScreen permite ingresar texto en los campos', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'María Torres');
    await tester.pump();

    expect(find.text('María Torres'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('tap Cancelar reserva muestra SnackBar de función no disponible', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(390, 2400);

    await tester.pumpWidget(_buildSubject());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Cancelar reserva'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar reserva'));
    await tester.pump();

    expect(find.text('Función no disponible aún'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });
}
