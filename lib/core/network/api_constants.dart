import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  // Auth
  static const String authRegisterGuest = '/auth/register-guest';
  static const String authAccountStatus = '/auth/account-status';

  // Users
  static const String usersMe = '/users/me';

  // Publications
  static const String publications = '/publications';
  static const String publicationsMine = '/publications/mine';

  // Feed
  static const String feed = '/feed';

  // Reservations
  static const String reservations = '/reservations';
  static const String reservationsMine = '/reservations/mine';
  static const String reservationsReceived = '/reservations/received';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';
}
