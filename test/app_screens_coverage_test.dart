import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:sire/features/profile/presentation/screens/profile_screen.dart';
import 'package:sire/features/reservations/presentation/screens/my_reservations_screen.dart';
import 'package:sire/features/publications/presentation/screens/my_publications_screen.dart';
import 'package:sire/features/publications/presentation/screens/create_publication_screen.dart';
import 'package:sire/features/publications/presentation/screens/dashboard_screen.dart';

void main() {
  testWidgets('Renderizado general de pantallas y navegacion', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    final mockRouter = GoRouter(
      initialLocation: '/1',
      routes: [
        GoRoute(path: '/1', builder: (_, __) => const NotificationsScreen()),
        GoRoute(path: '/2', builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/3', builder: (_, __) => const MyReservationsScreen()),
        GoRoute(path: '/4', builder: (_, __) => const MyPublicationsScreen()),
        GoRoute(path: '/5', builder: (_, __) => const CreatePublicationScreen()),
        GoRoute(path: '/6', builder: (_, __) => const DashboardScreen()),
      ],
    );

    await tester.pumpWidget(ProviderScope(child: MaterialApp.router(routerConfig: mockRouter)));
    await tester.pumpAndSettle();

    mockRouter.go('/2');
    await tester.pumpAndSettle();

    mockRouter.go('/3');
    await tester.pumpAndSettle();

    mockRouter.go('/4');
    await tester.pumpAndSettle();

    mockRouter.go('/5');
    await tester.pumpAndSettle();

    mockRouter.go('/6');
    await tester.pumpAndSettle();

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });
}