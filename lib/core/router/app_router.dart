import 'package:go_router/go_router.dart';
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

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
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
