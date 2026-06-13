// Builders de JSON con la forma exacta que devuelve el backend en dev.
// Centralizados para que un cambio de contrato se corrija en un solo lugar.

/// Agenda en el formato JSON que persiste Prisma (columna availability).
Map<String, dynamic> availabilityJson({int slotDuration = 60}) => {
  'slotDurationMinutes': slotDuration,
  'sameScheduleAllDays': true,
  'defaultSchedules': [
    {'startTime': '09:00', 'endTime': '18:00'},
  ],
  'dayOverrides': [
    {'dayOfWeek': 'SUNDAY', 'isClosed': true, 'schedules': <dynamic>[]},
  ],
};

/// Publicación como la devuelve GET /publications/:id (owner incluido)
/// o POST /publications (sin owner) según [withOwner].
Map<String, dynamic> publicationJson({
  String id = 'pub-1',
  String title = 'Cancha Los Alerces',
  String category = 'DEPORTE',
  String region = 'Araucania',
  String ownerId = 'owner-9',
  String? ownerName = 'Club Andes',
  bool isActive = true,
  bool withOwner = true,
  Map<String, dynamic>? availability,
}) => {
  'id': id,
  'title': title,
  'description': 'Cancha de futbol 7 con luz nocturna',
  'category': category,
  'imageUrl': null,
  'region': region,
  'city': 'Temuco',
  'isActive': isActive,
  'availability': availability ?? availabilityJson(),
  'createdAt': '2026-06-01T12:00:00.000Z',
  'ownerId': ownerId,
  if (withOwner) 'owner': {'name': ownerName, 'avatarUrl': null},
};

/// Perfil como lo devuelve GET /auth/me (shape de la tabla profiles).
Map<String, dynamic> profileJson({
  String id = 'user-1',
  String email = 'dani@sire.cl',
  String? name = 'Dani',
  String accountStatus = 'guest',
}) => {
  'id': id,
  'email': email,
  'name': name,
  'phone': '+56911111111',
  'accountStatus': accountStatus,
  'avatarUrl': null,
  'createdAt': '2026-05-10T00:00:00.000Z',
};

/// Cuerpo de error estándar del contrato.
Map<String, dynamic> errorBody(
  String code,
  String message, {
  Map<String, dynamic>? fields,
}) => {
  'error': {'code': code, 'message': message, 'fields': ?fields},
};
