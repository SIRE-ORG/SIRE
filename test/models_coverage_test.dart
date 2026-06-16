// test/models_coverage_test.dart
//
// Cobertura de modelos de datos de SIRE.
// Ejecutar con:
//   flutter test test/models_coverage_test.dart --coverage
//
// Modelos cubiertos:
//   - CreatePublicationRequestModel
//   - CreateReservationRequestModel
//   - UserProfileModel
//   - FeedResponseModel

import 'package:flutter_test/flutter_test.dart';
import 'package:sire/features/publications/data/models/create_publication_request_model.dart';
import 'package:sire/features/reservations/data/models/create_reservation_request_model.dart';
import 'package:sire/features/auth/data/models/user_profile_model.dart';
import 'package:sire/features/feed/data/models/feed_response_model.dart';
import 'package:sire/features/feed/data/models/publication_summary_model.dart';
import 'package:sire/features/publications/domain/entities/availability_config.dart';
import 'package:sire/features/publications/domain/entities/publication.dart';
import 'package:sire/features/auth/domain/entities/user_profile.dart';

void main() {
  // ─────────────────────────────────────────────────────────────
  // CreatePublicationRequestModel
  // ─────────────────────────────────────────────────────────────
  group('CreatePublicationRequestModel', () {
    const availability = AvailabilityConfig(
      slotDurationMinutes: 60,
      sameScheduleAllDays: true,
      defaultSchedules: [
        DaySchedule(startTime: '09:00', endTime: '17:00'),
      ],
      dayOverrides: [],
    );

    test('constructor asigna todos los campos requeridos', () {
      final model = CreatePublicationRequestModel(
        title: 'Corte de cabello',
        description: 'Servicio de barbería profesional',
        category: PublicationCategory.deporte,
        region: 'Biobío',
        availability: availability,
      );

      expect(model.title, 'Corte de cabello');
      expect(model.description, 'Servicio de barbería profesional');
      expect(model.category, PublicationCategory.deporte);
      expect(model.region, 'Biobío');
      expect(model.imageUrl, isNull);
      expect(model.city, isNull);
    });

    test('constructor asigna campos opcionales cuando se proveen', () {
      final model = CreatePublicationRequestModel(
        title: 'Masaje',
        description: 'Relajante',
        category: PublicationCategory.recreacion,
        imageUrl: 'https://example.com/img.jpg',
        region: 'Metropolitana',
        city: 'Santiago',
        availability: availability,
      );

      expect(model.imageUrl, 'https://example.com/img.jpg');
      expect(model.city, 'Santiago');
    });

    test('toJson incluye todos los campos esperados', () {
      final model = CreatePublicationRequestModel(
        title: 'Consulta médica',
        description: 'Consulta general',
        category: PublicationCategory.recreacion,
        region: 'Valparaíso',
        availability: availability,
      );

      final json = model.toJson();

      expect(json['title'], 'Consulta médica');
      expect(json['description'], 'Consulta general');
      expect(json['region'], 'Valparaíso');
      expect(json.containsKey('category'), isTrue);
      expect(json.containsKey('availability'), isTrue);
    });

    test('toJson incluye imageUrl y city cuando se proveen', () {
      final model = CreatePublicationRequestModel(
        title: 'Test',
        description: 'Desc',
        category: PublicationCategory.deporte,
        imageUrl: 'https://img.url/foto.png',
        region: 'Araucanía',
        city: 'Temuco',
        availability: availability,
      );

      final json = model.toJson();

      expect(json['imageUrl'], 'https://img.url/foto.png');
      expect(json['city'], 'Temuco');
    });

    test('toJson con city nula serializa sin lanzar excepción', () {
      final model = CreatePublicationRequestModel(
        title: 'Sin ciudad',
        description: 'Desc',
        category: PublicationCategory.deporte,
        region: 'Los Lagos',
        availability: availability,
      );

      expect(() => model.toJson(), returnsNormally);
      final json = model.toJson();
      expect(json['city'], isNull);
    });

    test('toJson serializa la categoría como string', () {
      final model = CreatePublicationRequestModel(
        title: 'Test',
        description: 'Desc',
        category: PublicationCategory.deporte,
        region: 'Test',
        availability: availability,
      );

      final json = model.toJson();
      expect(json['category'], isA<String>());
    });

    test('toJson incluye availability serializada como map', () {
      final model = CreatePublicationRequestModel(
        title: 'Test',
        description: 'Desc',
        category: PublicationCategory.recreacion,
        region: 'Test',
        availability: availability,
      );

      final json = model.toJson();
      expect(json['availability'], isA<Map>());
    });

    test('distintas categorías serializan correctamente', () {
      for (final category in PublicationCategory.values) {
        final model = CreatePublicationRequestModel(
          title: 'T',
          description: 'D',
          category: category,
          region: 'R',
          availability: availability,
        );
        final json = model.toJson();
        expect(json['category'], isA<String>());
        expect((json['category'] as String).isNotEmpty, isTrue);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────
  // CreateReservationRequestModel
  // ─────────────────────────────────────────────────────────────
  group('CreateReservationRequestModel', () {
    test('constructor asigna todos los campos', () {
      const model = CreateReservationRequestModel(
        publicationId: 'pub-123',
        date: '2026-06-15',
        startTime: '10:00',
        endTime: '11:00',
      );

      expect(model.publicationId, 'pub-123');
      expect(model.date, '2026-06-15');
      expect(model.startTime, '10:00');
      expect(model.endTime, '11:00');
    });

    test('toJson produce el mapa correcto', () {
      const model = CreateReservationRequestModel(
        publicationId: 'pub-abc',
        date: '2026-07-01',
        startTime: '14:00',
        endTime: '15:00',
      );

      final json = model.toJson();

      expect(json['publicationId'], 'pub-abc');
      expect(json['date'], '2026-07-01');
      expect(json['startTime'], '14:00');
      expect(json['endTime'], '15:00');
    });

    test('toJson tiene exactamente 4 claves', () {
      const model = CreateReservationRequestModel(
        publicationId: 'x',
        date: '2026-01-01',
        startTime: '08:00',
        endTime: '09:00',
      );

      expect(model.toJson().length, 4);
    });

    test('toJson no lanza excepciones con valores válidos', () {
      const model = CreateReservationRequestModel(
        publicationId: 'pub-999',
        date: '2026-12-31',
        startTime: '23:00',
        endTime: '23:59',
      );

      expect(() => model.toJson(), returnsNormally);
    });

    test('publicationId acepta cualquier string no vacío', () {
      const model = CreateReservationRequestModel(
        publicationId: 'cluid-1234abcd',
        date: '2026-06-01',
        startTime: '09:00',
        endTime: '10:00',
      );

      expect(model.toJson()['publicationId'], 'cluid-1234abcd');
    });

    test('múltiples instancias con datos distintos no comparten estado', () {
      const m1 = CreateReservationRequestModel(
        publicationId: 'a',
        date: '2026-01-01',
        startTime: '08:00',
        endTime: '09:00',
      );
      const m2 = CreateReservationRequestModel(
        publicationId: 'b',
        date: '2026-06-15',
        startTime: '13:00',
        endTime: '14:00',
      );

      expect(m1.publicationId, isNot(m2.publicationId));
      expect(m1.toJson()['publicationId'], 'a');
      expect(m2.toJson()['publicationId'], 'b');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // UserProfileModel
  // ─────────────────────────────────────────────────────────────
  group('UserProfileModel', () {
    // JSON que simula la respuesta del endpoint GET /users/me
    final fullJson = {
      'userId': 'user-001',
      'name': 'Emilia Toro',
      'email': 'emilia@ufro.cl',
      'phone': '+56912345678',
      'accountStatus': 'active',
      'emailVerified': true,
      'avatarUrl': 'https://cdn.example.com/avatar.png',
      'createdAt': '2026-03-01T00:00:00.000Z',
    };

    final minimalJson = {
      'userId': 'user-002',
      'name': 'Daniel Palma',
      'email': 'daniel@ufro.cl',
      'phone': null,
      'accountStatus': 'guest',
      'emailVerified': false,
      'avatarUrl': null,
      'createdAt': '2026-04-01T00:00:00.000Z',
    };

    // ── fromJson ──
    group('fromJson', () {
      test('parsea todos los campos del JSON completo', () {
        final model = UserProfileModel.fromJson(fullJson);

        expect(model.userId, 'user-001');
        expect(model.name, 'Emilia Toro');
        expect(model.email, 'emilia@ufro.cl');
        expect(model.phone, '+56912345678');
        expect(model.accountStatus, 'active');
        expect(model.emailVerified, isTrue);
        expect(model.avatarUrl, 'https://cdn.example.com/avatar.png');
        expect(model.createdAt, '2026-03-01T00:00:00.000Z');
      });

      test('parsea campos opcionales nulos correctamente', () {
        final model = UserProfileModel.fromJson(minimalJson);

        expect(model.phone, isNull);
        expect(model.avatarUrl, isNull);
        expect(model.emailVerified, isFalse);
        expect(model.accountStatus, 'guest');
      });

      test('emailVerified false se parsea correctamente', () {
        final model = UserProfileModel.fromJson(minimalJson);
        expect(model.emailVerified, isFalse);
      });
    });

    // ── fromBackendProfile ──
    group('fromBackendProfile', () {
      final backendJson = {
        'id': 'user-backend-001',
        'name': 'Cristóbal Sandoval',
        'email': 'cristobal@ufro.cl',
        'phone': null,
        'accountStatus': 'active',
        'avatarUrl': null,
        'createdAt': '2026-03-15T00:00:00.000Z',
      };

      test('mapea id → userId correctamente', () {
        final model = UserProfileModel.fromBackendProfile(
          backendJson,
          emailVerified: true,
        );
        expect(model.userId, 'user-backend-001');
      });

      test('inyecta emailVerified desde parámetro', () {
        final verified = UserProfileModel.fromBackendProfile(
          backendJson,
          emailVerified: true,
        );
        final unverified = UserProfileModel.fromBackendProfile(
          backendJson,
          emailVerified: false,
        );

        expect(verified.emailVerified, isTrue);
        expect(unverified.emailVerified, isFalse);
      });

      test('name nulo en JSON se convierte a string vacío', () {
        final jsonSinName = Map<String, dynamic>.from(backendJson)
          ..['name'] = null;

        final model = UserProfileModel.fromBackendProfile(
          jsonSinName,
          emailVerified: false,
        );

        expect(model.name, '');
      });

      test('name no nulo se preserva', () {
        final model = UserProfileModel.fromBackendProfile(
          backendJson,
          emailVerified: false,
        );
        expect(model.name, 'Cristóbal Sandoval');
      });

      test('campos opcionales nulos se mapean como null', () {
        final model = UserProfileModel.fromBackendProfile(
          backendJson,
          emailVerified: false,
        );
        expect(model.phone, isNull);
        expect(model.avatarUrl, isNull);
      });
    });

    // ── toEntity ──
    group('toEntity', () {
      test('convierte accountStatus active → AccountStatus.active', () {
        final model = UserProfileModel.fromJson(fullJson);
        final entity = model.toEntity();

        expect(entity.accountStatus, AccountStatus.active);
      });

      test('convierte accountStatus guest → AccountStatus.guest', () {
        final model = UserProfileModel.fromJson(minimalJson);
        final entity = model.toEntity();

        expect(entity.accountStatus, AccountStatus.guest);
      });

      test('mapea userId → entity.id', () {
        final model = UserProfileModel.fromJson(fullJson);
        final entity = model.toEntity();

        expect(entity.id, 'user-001');
      });

      test('mapea nombre, email y phone correctamente', () {
        final model = UserProfileModel.fromJson(fullJson);
        final entity = model.toEntity();

        expect(entity.name, 'Emilia Toro');
        expect(entity.email, 'emilia@ufro.cl');
        expect(entity.phone, '+56912345678');
      });

      test('phone null se mantiene null en la entidad', () {
        final model = UserProfileModel.fromJson(minimalJson);
        final entity = model.toEntity();

        expect(entity.phone, isNull);
      });

      test('emailVerified se preserva en la entidad', () {
        final model = UserProfileModel.fromJson(fullJson);
        expect(model.toEntity().emailVerified, isTrue);

        final modelFalse = UserProfileModel.fromJson(minimalJson);
        expect(modelFalse.toEntity().emailVerified, isFalse);
      });

      test('avatarUrl se preserva en la entidad', () {
        final model = UserProfileModel.fromJson(fullJson);
        expect(
          model.toEntity().avatarUrl,
          'https://cdn.example.com/avatar.png',
        );
      });

      test('avatarUrl null se mantiene null en la entidad', () {
        final model = UserProfileModel.fromJson(minimalJson);
        expect(model.toEntity().avatarUrl, isNull);
      });

      test('retorna una instancia de UserProfile', () {
        final model = UserProfileModel.fromJson(fullJson);
        expect(model.toEntity(), isA<UserProfile>());
      });
    });

    // ── constructor directo ──
    test('constructor asigna todos los campos', () {
      const model = UserProfileModel(
        userId: 'u1',
        name: 'Test User',
        email: 'test@example.com',
        accountStatus: 'active',
        emailVerified: true,
        createdAt: '2026-01-01T00:00:00.000Z',
      );

      expect(model.userId, 'u1');
      expect(model.name, 'Test User');
      expect(model.email, 'test@example.com');
      expect(model.phone, isNull);
      expect(model.avatarUrl, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // FeedResponseModel
  // ─────────────────────────────────────────────────────────────
  group('FeedResponseModel', () {
    // JSON completo simulando respuesta real del backend
    final fullFeedJson = {
      'pagination': {
        'page': 2,
        'limit': 10,
        'total': 45,
        'hasMore': true,
      },
      'data': [
        {
          'id': 'pub-001',
          'title': 'Barbería Premium',
          'description': 'Cortes modernos',
          'category': 'beauty',
          'region': 'Biobío',
          'imageUrl': null,
          'publisherName': 'Carlos R.',
          'publisherId': 'usr-001',
        },
        {
          'id': 'pub-002',
          'title': 'Consulta General',
          'description': 'Médico de familia',
          'category': 'health',
          'region': 'Biobío',
          'imageUrl': 'https://img.url/med.png',
          'publisherName': 'Dra. Ana M.',
          'publisherId': 'usr-002',
        },
      ],
    };

    test('fromJson parsea paginación correctamente', () {
      final model = FeedResponseModel.fromJson(fullFeedJson);

      expect(model.page, 2);
      expect(model.limit, 10);
      expect(model.total, 45);
      expect(model.hasMore, isTrue);
    });

    test('fromJson parsea lista de items', () {
      final model = FeedResponseModel.fromJson(fullFeedJson);

      expect(model.items.length, 2);
      expect(model.items, isA<List<PublicationSummaryModel>>());
    });

    test('fromJson con JSON vacío usa valores por defecto', () {
      final model = FeedResponseModel.fromJson({});

      expect(model.page, 1);
      expect(model.limit, 20);
      expect(model.total, 0);
      expect(model.hasMore, isFalse);
      expect(model.items, isEmpty);
    });

    test('fromJson con pagination vacía usa valores por defecto', () {
      final model = FeedResponseModel.fromJson({
        'pagination': {},
        'data': [],
      });

      expect(model.page, 1);
      expect(model.limit, 20);
      expect(model.total, 0);
      expect(model.hasMore, isFalse);
    });

    test('fromJson con data vacía retorna lista vacía', () {
      final model = FeedResponseModel.fromJson({
        'pagination': {'page': 1, 'limit': 20, 'total': 0, 'hasMore': false},
        'data': [],
      });

      expect(model.items, isEmpty);
    });

    test('fromJson hasMore false se parsea correctamente', () {
      final json = {
        'pagination': {
          'page': 3,
          'limit': 10,
          'total': 25,
          'hasMore': false,
        },
        'data': [],
      };

      final model = FeedResponseModel.fromJson(json);
      expect(model.hasMore, isFalse);
      expect(model.page, 3);
    });

    test('constructor asigna todos los campos', () {
      final model = FeedResponseModel(
        items: const [],
        page: 1,
        limit: 20,
        total: 0,
        hasMore: false,
      );

      expect(model.items, isEmpty);
      expect(model.page, 1);
      expect(model.limit, 20);
      expect(model.total, 0);
      expect(model.hasMore, isFalse);
    });

    test('fromJson primera página con items y hasMore true', () {
      final json = {
        'pagination': {
          'page': 1,
          'limit': 5,
          'total': 30,
          'hasMore': true,
        },
        'data': [
          {
            'id': 'pub-x',
            'title': 'Test Pub',
            'description': 'Desc',
            'category': 'beauty',
            'region': 'Biobío',
            'imageUrl': null,
            'publisherName': 'Emilia T.',
            'publisherId': 'usr-x',
          },
        ],
      };

      final model = FeedResponseModel.fromJson(json);

      expect(model.items.length, 1);
      expect(model.page, 1);
      expect(model.total, 30);
      expect(model.hasMore, isTrue);
    });

    test('fromJson con data nula no lanza excepción', () {
      final json = <String, dynamic>{
        'pagination': {'page': 1, 'limit': 20, 'total': 0, 'hasMore': false},
        'data': null,
      };

      expect(() => FeedResponseModel.fromJson(json), returnsNormally);
    });

    test('fromJson con pagination nula no lanza excepción', () {
      final json = <String, dynamic>{
        'pagination': null,
        'data': [],
      };

      expect(() => FeedResponseModel.fromJson(json), returnsNormally);
    });
  });
}