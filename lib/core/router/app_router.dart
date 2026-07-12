import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/domain/entities/user_profile.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/location_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/activate_account_screen.dart';
import '../../features/auth/presentation/screens/verify_otp_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/feed/presentation/screens/publication_detail_screen.dart';
import '../../features/publications/presentation/screens/my_publications_screen.dart';
import '../../features/publications/presentation/screens/create_publication_screen.dart';
import '../../features/publications/presentation/screens/edit_publication_screen.dart';
import '../../features/reservations/presentation/screens/my_reservations_screen.dart';
import '../../features/reservations/presentation/screens/reservation_detail_screen.dart';
import '../../features/reservations/presentation/screens/reservation_confirm_screen.dart';
import '../../features/reservations/presentation/screens/received_reservations_screen.dart';
import '../../features/reservations/presentation/screens/received_reservation_detail_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/publications/presentation/screens/dashboard_screen.dart';

part 'app_router.g.dart';

// ---------------------------------------------------------------------------
// Guards de navegación por estado de cuenta (regla de negocio del flujo de 3
// fases ANON → GUEST → ACTIVE). Las rutas se clasifican por plantilla
// (`GoRouterState.fullPath`, ej. `/publication/:id/edit`), no por URL
// resuelta, para que los path params no rompan la comparación.
// ---------------------------------------------------------------------------

/// No requieren ningún tipo de sesión.
const _publicPaths = {
  '/',
  '/location',
  '/feed',
  '/publication/:id',
  '/login',
  '/register',
  '/verify-otp',
  '/activate-account',
  '/forgot-password',
};

/// Requieren sesión (una sesión anónima de Supabase basta) — confirmar una
/// reserva puede hacerlo un anónimo, que completa el form de invitado ahí
/// mismo.
const _requiresSessionPaths = {'/publication/:id/confirm'};

/// Requieren `AccountStatus.active` (lado publicador: gestión de
/// publicaciones y de las reservas que recibe).
const _requiresActivePaths = {
  '/dashboard',
  '/my-publications',
  '/publication/create',
  '/publication/:id/edit',
  '/received-reservations',
  '/received-reservation/detail',
};

/// Requieren un perfil ya creado (`guest` o `active`); una sesión anónima
/// sin perfil no basta.
const _requiresProfilePaths = {
  '/my-reservations',
  '/reservation/:id',
  '/notifications',
  '/profile',
  '/profile/edit',
};

/// Decide el destino de redirect para [path] (la plantilla de ruta, no la
/// URL resuelta) dado el [status] actual. `null` significa "no redirigir".
/// Expuesta (sin prefijo `_`) solo para poder testear la tabla de
/// decisiones de forma aislada y rápida; no es parte de la superficie
/// pública del router.
@visibleForTesting
String? decideRedirect(String path, AccountStatus? status) {
  if (_publicPaths.contains(path)) return null;

  final hasSession = status != null;
  final hasProfile =
      status == AccountStatus.guest || status == AccountStatus.active;
  final isActive = status == AccountStatus.active;

  if (_requiresSessionPaths.contains(path)) {
    return hasSession ? null : '/login';
  }
  if (_requiresActivePaths.contains(path)) {
    // Sin una pantalla dedicada de "activa tu cuenta", /profile es donde
    // hoy se ve el estado de la cuenta (guest/active).
    return isActive ? null : '/profile';
  }
  if (_requiresProfilePaths.contains(path)) {
    return hasProfile ? null : '/login';
  }

  // Ruta no clasificada: no se bloquea (fail-open) para no romper
  // navegación de pantallas nuevas que aún no se hayan catalogado acá.
  return null;
}

Future<String?> _redirect(Ref ref, GoRouterState state) async {
  final path = state.fullPath ?? state.matchedLocation;

  AccountStatus? status;
  try {
    status = await ref.read(authStatusProvider.future);
  } catch (_) {
    // Fail-closed: si no se pudo verificar la cuenta (p. ej. error de red),
    // se trata como "sin sesión verificada" en vez de dejar pasar.
    status = null;
  }

  return decideRedirect(path, status);
}

/// Notifica a GoRouter cuando cambia `authStatusProvider` para que
/// re-evalúe `redirect` sin necesidad de una navegación explícita (p. ej. un
/// guest que activa su cuenta mientras sigue en la misma pantalla).
class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authStatusProvider, (_, _) => notifyListeners());
  }
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refreshNotifier = _GoRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      GoRoute(
        path: '/location',
        builder: (context, state) => const LocationScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/feed', builder: (context, state) => const FeedScreen()),
      GoRoute(
        path: '/my-reservations',
        builder: (context, state) => const MyReservationsScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/my-publications',
        builder: (context, state) => const MyPublicationsScreen(),
      ),
      GoRoute(
        path: '/publication/create',
        builder: (context, state) => const CreatePublicationScreen(),
      ),
      GoRoute(
        path: '/publication/:id/edit',
        builder: (context, state) =>
            EditPublicationScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/publication/:id',
        builder: (context, state) =>
            PublicationDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reservation/:id',
        builder: (context, state) => ReservationDetailScreen(
          id: state.pathParameters['id']!,
          title:
              state.uri.queryParameters['title'] ??
              'Cancha de fútbol sintética',
          publisher:
              state.uri.queryParameters['publisher'] ?? 'Club Deportivo Temuco',
          date: state.uri.queryParameters['date'] ?? 'Hoy',
          time: state.uri.queryParameters['time'] ?? '11:00 - 12:00',
          status: state.uri.queryParameters['status'] ?? 'Pendiente',
        ),
      ),
      GoRoute(
        path: '/publication/:id/confirm',
        builder: (context, state) => ReservationConfirmScreen(
          id: state.pathParameters['id']!,
          title: state.uri.queryParameters['title'] ?? '',
          subtitle: state.uri.queryParameters['subtitle'] ?? '',
          date: state.uri.queryParameters['date'] ?? '',
          time: state.uri.queryParameters['time'] ?? '',
        ),
      ),
      GoRoute(
        path: '/received-reservations',
        builder: (context, state) => const ReceivedReservationsScreen(),
      ),
      GoRoute(
        path: '/received-reservation/detail',
        builder: (context, state) => ReceivedReservationDetailScreen(
          id: state.uri.queryParameters['id'] ?? '',
          applicantName: state.uri.queryParameters['name'] ?? '',
          publication: state.uri.queryParameters['pub'] ?? '',
          date: state.uri.queryParameters['date'] ?? '',
          time: state.uri.queryParameters['time'] ?? '',
          status: state.uri.queryParameters['status'] ?? 'Pendiente',
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) => const VerifyOtpScreen(),
      ),
      GoRoute(
        path: '/activate-account',
        builder: (context, state) => const ActivateAccountScreen(),
      ),
    ],
  );
}
