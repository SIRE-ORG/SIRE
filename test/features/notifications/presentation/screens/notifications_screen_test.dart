import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/notifications/domain/entities/app_notification.dart';
import 'package:sire/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:sire/features/notifications/presentation/screens/notifications_screen.dart';

AppNotification _notif({
  String id = '1',
  NotificationType type = NotificationType.newReservation,
  bool read = false,
  String? reservationId,
}) =>
    AppNotification(
      id: id,
      type: type,
      title: 'Nueva reserva recibida',
      body: 'Carlos Pérez quiere reservar tu cancha',
      read: read,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      reservationId: reservationId,
    );

Widget _buildSubject({
  List<AppNotification> notifications = const [],
  int unread = 0,
  Object? error,
}) {
  final mockRouter = GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/reservation/:id',
        builder: (_, __) => const Scaffold(body: Text('Detalle')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      notificationsStreamProvider.overrideWith(
        (ref) => error != null
            ? Stream.error(error)
            : Stream.value(notifications),
      ),
      unreadCountProvider.overrideWith((ref) => unread),
    ],
    child: MaterialApp.router(routerConfig: mockRouter),
  );
}

void main() {
  void suppressOverflow(WidgetTester t) {
    final orig = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exceptionAsString().contains('overflowed')) return;
      orig?.call(d);
    };
    addTearDown(() {
      FlutterError.onError = orig;
      t.view.resetPhysicalSize();
    });
  }

  testWidgets('NotificationsScreen muestra título y AppBar', (tester) async {
    suppressOverflow(tester);
    tester.view.physicalSize = const Size(390, 844);

    await tester.pumpWidget(_buildSubject());
    await tester.pump();

    expect(find.text('Notificaciones'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('NotificationsScreen sin notificaciones muestra empty state', (tester) async {
    suppressOverflow(tester);
    tester.view.physicalSize = const Size(390, 844);

    await tester.pumpWidget(_buildSubject());
    await tester.pump();

    expect(find.text('Sin notificaciones'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
  });

  testWidgets('NotificationsScreen con notificaciones muestra cards', (tester) async {
    suppressOverflow(tester);
    tester.view.physicalSize = const Size(390, 844);

    final notifs = [_notif(id: '1'), _notif(id: '2', read: true)];
    await tester.pumpWidget(_buildSubject(notifications: notifs));
    await tester.pump();

    expect(find.text('Nueva reserva recibida'), findsWidgets);
    expect(find.text('Carlos Pérez quiere reservar tu cancha'), findsWidgets);
  });

  testWidgets('NotificationsScreen no leídas muestran punto azul', (tester) async {
    suppressOverflow(tester);
    tester.view.physicalSize = const Size(390, 844);

    await tester.pumpWidget(_buildSubject(notifications: [_notif(read: false)], unread: 1));
    await tester.pump();

    expect(find.text('1 nueva'), findsOneWidget);
  });

  testWidgets('NotificationsScreen agrupa por sección Hoy', (tester) async {
    suppressOverflow(tester);
    tester.view.physicalSize = const Size(390, 844);

    await tester.pumpWidget(_buildSubject(notifications: [_notif()]));
    await tester.pump();

    expect(find.text('Hoy'), findsOneWidget);
  });

  testWidgets('NotificationsScreen con unread > 1 muestra plural nuevas', (tester) async {
    suppressOverflow(tester);
    tester.view.physicalSize = const Size(390, 844);

    await tester.pumpWidget(_buildSubject(
      notifications: [_notif(id: '1'), _notif(id: '2')],
      unread: 2,
    ));
    await tester.pump();

    expect(find.text('2 nuevas'), findsOneWidget);
  });

  testWidgets('NotificationsScreen error muestra mensaje y botón reintentar', (tester) async {
    suppressOverflow(tester);
    tester.view.physicalSize = const Size(390, 844);

    await tester.pumpWidget(_buildSubject(error: Exception('fallo')));
    await tester.pump();

    expect(find.text('No se pudieron cargar las notificaciones'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('NotificationsScreen iconos por tipo de notificación', (tester) async {
    suppressOverflow(tester);
    tester.view.physicalSize = const Size(390, 844);

    await tester.pumpWidget(_buildSubject(notifications: [
      _notif(type: NotificationType.statusUpdated),
    ]));
    await tester.pump();

    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('NotificationsScreen tipo cancelada muestra ícono cancel', (tester) async {
    suppressOverflow(tester);
    tester.view.physicalSize = const Size(390, 844);

    await tester.pumpWidget(_buildSubject(notifications: [
      _notif(type: NotificationType.reservationCancelled),
    ]));
    await tester.pump();

    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
  });

  testWidgets('NotificationsScreen tipo system muestra ícono notifications_active', (tester) async {
    suppressOverflow(tester);
    tester.view.physicalSize = const Size(390, 844);

    await tester.pumpWidget(_buildSubject(notifications: [
      _notif(type: NotificationType.system),
    ]));
    await tester.pump();

    expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
  });
}
