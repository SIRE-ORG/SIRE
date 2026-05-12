import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => _stub('Home')),
      GoRoute(path: '/feed', builder: (context, state) => _stub('Feed')),
      GoRoute(path: '/login', builder: (context, state) => _stub('Login')),
      GoRoute(
        path: '/activate-account',
        builder: (context, state) => _stub('Activate Account'),
      ),
      GoRoute(
        path: '/publication/create',
        builder: (context, state) => _stub('Create Publication'),
      ),
      GoRoute(
        path: '/publication/:id',
        builder: (context, state) => _stub('Publication Detail'),
      ),
      GoRoute(
        path: '/publication/:id/slots',
        builder: (context, state) => _stub('Publication Slots'),
      ),
      GoRoute(
        path: '/publication/:id/edit',
        builder: (context, state) => _stub('Edit Publication'),
      ),
      GoRoute(
        path: '/my-publications',
        builder: (context, state) => _stub('My Publications'),
      ),
      GoRoute(
        path: '/my-reservations',
        builder: (context, state) => _stub('My Reservations'),
      ),
      GoRoute(
        path: '/received-reservations',
        builder: (context, state) => _stub('Received Reservations'),
      ),
      GoRoute(
        path: '/reservation/:id',
        builder: (context, state) => _stub('Reservation Detail'),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => _stub('Notifications'),
      ),
      GoRoute(path: '/profile', builder: (context, state) => _stub('Profile')),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => _stub('Edit Profile'),
      ),
    ],
    // redirect conectará authStatusProvider en Sprint 5
  );

  static Widget _stub(String name) => Scaffold(body: Center(child: Text(name)));
}
