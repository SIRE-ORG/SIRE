import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  // Auth
  static const String authRegisterGuest = '/auth/register-guest';
  static const String authAccountStatus = '/auth/account-status';
  static const String authMe = '/auth/me';

  // Users
  static const String usersMe = '/users/me';
  // Temporal: lista todos los perfiles (usado por AuthRemoteDatasourceRealImpl
  // para simular GET /users/me hasta que el backend lo implemente).
  static const String usersProfiles = '/users/profiles';

  // Publications (contrato futuro: GET /publications, GET /publications/mine)
  static const String publications = '/publications';
  static const String publicationsMine = '/publications/mine';
  // Bug conocido en backend v0: publication.routes.ts registra '/publications'
  // como ruta local pero el prefix en app.ts ya es '/api/v1/publications',
  // resultando en paths efectivos /publications/publications[/mine].
  // Documentado en claude/comentarios_backend.txt sección C.
  static const String publicationsFeedLive = '/publications/publications';
  static const String publicationsFeedMineLive =
      '/publications/publications/mine';
  // Las rutas por id NO arrastran el doble segmento: publication.routes.ts
  // las registra como '/:id' directamente bajo el prefix /api/v1/publications.
  // Al corregirse el bug C hay que unificar este formato con los de arriba.
  static String publicationByIdLive(String id) => '/publications/$id';

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
