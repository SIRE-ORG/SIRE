import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/location_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/reservations/presentation/screens/my_reservations_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/location', builder: (context, state) => const LocationScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/feed', builder: (context, state) => const FeedScreen()),
      GoRoute(path: '/my-reservations', builder: (context, state) => const MyReservationsScreen()),
      GoRoute(path: '/activate-account', builder: (context, state) => _stub('Activate Account')),
      GoRoute(path: '/publication/create', builder: (context, state) => _stub('Create Publication')),
      GoRoute(path: '/publication/:id', builder: (context, state) => _stub('Publication Detail')),
      GoRoute(path: '/publication/:id/slots', builder: (context, state) => _stub('Publication Slots')),
      GoRoute(path: '/publication/:id/edit', builder: (context, state) => _stub('Edit Publication')),
      GoRoute(path: '/my-publications', builder: (context, state) => _stub('My Publications')),
      GoRoute(path: '/received-reservations', builder: (context, state) => _stub('Received Reservations')),
      GoRoute(path: '/reservation/:id', builder: (context, state) => _stub('Reservation Detail')),
      GoRoute(path: '/notifications', builder: (context, state) => _stub('Notifications')),
      GoRoute(path: '/profile', builder: (context, state) => _stub('Profile')),
      GoRoute(path: '/profile/edit', builder: (context, state) => _stub('Edit Profile')),
    ],
  );

  static Widget _stub(String name) => Scaffold(body: Center(child: Text(name)));
}