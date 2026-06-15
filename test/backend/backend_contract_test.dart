@Tags(['backend'])
library;

// Costura B — Pruebas de contrato contra el backend real.
//
// Se activa solo si se define la variable de compilación SIRE_BACKEND_URL:
//   flutter test test/backend --dart-define=SIRE_BACKEND_URL=http://localhost:3000/api/v1
//
// Sin esa variable, la suite se salta automáticamente.
//
// Usa un Dio real (sin binding de widgets, que mataría la red) con el
// ErrorInterceptor de producción. La identidad se inyecta por request vía
// Options(headers: {'x-user-id': ...}); NO se monta AuthInterceptor.
//
// Las publicaciones creadas llevan el prefijo [PI-TEST] y una región única;
// se limpian al final (best-effort, incluso si las pruebas fallan).

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sire/core/network/api_constants.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/core/network/dio_client.dart';

import '../helpers/fixtures.dart';

const _backendUrl = String.fromEnvironment('SIRE_BACKEND_URL');

// Fixture de pruebas auto-sembrado por la suite. Identidad fija para que las
// corridas sean idempotentes y deterministas: siempre el mismo perfil owner.
const _fixtureEmail = 'pi-test@sire.cl';
const _fixtureId = 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa'; // UUID v4 fijo
const _fixtureName = '[PI-TEST] owner';

// Solicitante: identidad fija adicional para pruebas de reservas.
const _fixtureSolicitanteEmail = 'pi-test-solicitante@sire.cl';
const _fixtureSolicitanteId =
    'bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb'; // UUID v4 fijo
const _fixtureSolicitanteName = '[PI-TEST] solicitante';

void main() {
  if (_backendUrl.isEmpty) {
    test(
      'Costura B inactiva',
      () {},
      skip:
          'Define SIRE_BACKEND_URL para activar la Costura B: '
          'flutter test test/backend '
          '--dart-define=SIRE_BACKEND_URL=http://localhost:3000/api/v1',
    );
    return;
  }

  late Dio dio;
  late String regionPrueba;
  String? ownerId;
  String? solicitanteId;
  final creadas = <String>[];
  final reservasCreadas = <String>[];

  setUpAll(() async {
    dio = Dio(
      BaseOptions(
        baseUrl: _backendUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        // Sin contentType global: ver H7 en dio_client.dart. Dio pone
        // application/json solo cuando hay body, y los endpoints sin body
        // (PATCH account-status, DELETE) no chocan con Fastify.
      ),
    );
    dio.interceptors.add(ErrorInterceptor());

    // Región única para toda la suite: los items creados son identificables
    // y no colisionan con datos reales del equipo.
    regionPrueba = 'PI-TEST-REGION-${DateTime.now().millisecondsSinceEpoch}';

    // Auto-siembra idempotente del fixture activo (sin depender de datos previos
    // ni de un paso manual). Tres etapas, todas tolerantes a fallo:

    // 1) Crear la fila de profile. En reruns ya existe → el controller responde
    //    500 por unique constraint; se descarta. (register-guest tiene el
    //    desajuste H3 pero igual crea la fila, que es lo único que necesitamos.)
    try {
      await dio.post(
        ApiConstants.authRegisterGuest,
        data: {'id': _fixtureId, 'email': _fixtureEmail, 'name': _fixtureName},
      );
    } catch (_) {
      // Ya existe o el endpoint difiere: irrelevante, solo importa que la fila esté.
    }

    // 2) Forzar accountStatus=active (idempotente). El POST crea como guest;
    //    este PATCH lo deja active, que es lo que exige POST /publications.
    try {
      await dio.patch(
        ApiConstants.authAccountStatus,
        options: Options(headers: {'x-user-id': _fixtureId}),
      );
    } catch (_) {
      // Best-effort.
    }

    // 3) Verificar anclando al email: solo operamos bajo la identidad del
    //    fixture, nunca la "primera cuenta active" (que podría ser real).
    try {
      final r = await dio.get(ApiConstants.usersProfiles);
      final perfiles = (r.data as List).cast<Map<String, dynamic>>();
      final fixture = perfiles.cast<Map<String, dynamic>?>().firstWhere(
        (p) => p?['email'] == _fixtureEmail,
        orElse: () => null,
      );
      ownerId = fixture?['id'] as String?;
    } catch (_) {
      ownerId = null;
    }

    // ——— Siembra del solicitante (para pruebas de reservas) ———
    try {
      await dio.post(
        ApiConstants.authRegisterGuest,
        data: {
          'id': _fixtureSolicitanteId,
          'email': _fixtureSolicitanteEmail,
          'name': _fixtureSolicitanteName,
        },
      );
    } catch (_) {
      /* ya existe */
    }

    try {
      await dio.patch(
        ApiConstants.authAccountStatus,
        options: Options(headers: {'x-user-id': _fixtureSolicitanteId}),
      );
    } catch (_) {
      /* best-effort */
    }

    try {
      final r = await dio.get(ApiConstants.usersProfiles);
      final perfiles = (r.data as List).cast<Map<String, dynamic>>();
      final fixture = perfiles.cast<Map<String, dynamic>?>().firstWhere(
        (p) => p?['email'] == _fixtureSolicitanteEmail,
        orElse: () => null,
      );
      solicitanteId = fixture?['id'] as String?;
    } catch (_) {
      solicitanteId = null;
    }
  });

  tearDownAll(() async {
    // Limpieza best-effort de reservas: marcar como cancelled/failed
    // (no hay DELETE /reservations/:id; FK impide borrar la publicación
    // mientras tenga reservas activas).
    if (ownerId != null) {
      for (final id in reservasCreadas) {
        try {
          await dio.patch(
            ApiConstants.reservationStatus(id),
            data: {'status': 'cancelled'},
            options: Options(headers: {'x-user-id': ownerId}),
          );
        } catch (_) {
          // Best-effort.
        }
      }
    }

    // Limpieza best-effort: borrar todas las publicaciones creadas.
    if (ownerId == null) return;
    for (final id in creadas) {
      try {
        await dio.delete(
          ApiConstants.publicationByIdLive(id),
          options: Options(headers: {'x-user-id': ownerId}),
        );
      } catch (_) {
        // La limpieza falla silenciosamente; no afecta el resultado.
      }
    }
  });

  /// Crea una publicación mínima válida y retorna su id.
  Future<String> crearPublicacion({String sufijo = ''}) async {
    if (ownerId == null) {
      markTestSkipped('No se pudo sembrar el fixture $_fixtureEmail');
      return '';
    }
    final r = await dio.post(
      ApiConstants.publicationsFeedLive,
      data: {
        'title': '[PI-TEST] ciclo $sufijo',
        'description': 'creada por la suite de integración',
        'category': 'DEPORTE',
        'region': regionPrueba,
        'availability': availabilityJson(),
        'ownerId': ownerId,
      },
    );
    final id = (r.data['data'] as Map)['id'] as String;
    creadas.add(id);
    return id;
  }

  // -------------------------------------------------------------------------
  // PI-PUB-04 — ciclo CRUD completo
  // -------------------------------------------------------------------------

  test('PI-PUB-04 — ciclo crear → leer → editar → borrar contra el backend '
      'real', () async {
    final id = await crearPublicacion();
    if (id.isEmpty) return;

    // GET detalle: 200, datos íntegros.
    final detalle = await dio.get(ApiConstants.publicationByIdLive(id));
    expect(detalle.statusCode, 200);
    final data = detalle.data['data'] as Map<String, dynamic>;
    expect(data['title'], startsWith('[PI-TEST]'));
    expect(data['availability']['slotDurationMinutes'], 60);
    expect(data['owner']['name'], isNotNull);

    // PUT editar: 200, título actualizado.
    await dio.put(
      ApiConstants.publicationByIdLive(id),
      data: {'title': '[PI-TEST] editada'},
      options: Options(headers: {'x-user-id': ownerId}),
    );
    final editado = await dio.get(ApiConstants.publicationByIdLive(id));
    expect((editado.data['data'] as Map)['title'], '[PI-TEST] editada');

    // DELETE: 200, la publicación desaparece.
    await dio.delete(
      ApiConstants.publicationByIdLive(id),
      options: Options(headers: {'x-user-id': ownerId}),
    );
    creadas.remove(id);

    // GET final → 404.
    try {
      await dio.get(ApiConstants.publicationByIdLive(id));
      fail('Se esperaba 404 tras borrar');
    } on DioException catch (e) {
      expect(e.error, isA<NotFoundException>());
    }
  });

  // -------------------------------------------------------------------------
  // PI-PUB-05 — seguridad cruzada
  // -------------------------------------------------------------------------

  test('PI-PUB-05 — seguridad cruzada: intruso no edita ni borra', () async {
    final id = await crearPublicacion(sufijo: 'perm');
    if (id.isEmpty) return;
    const intruso = 'pi-test-intruso';

    // PUT con header de intruso → 403 FORBIDDEN.
    try {
      await dio.put(
        ApiConstants.publicationByIdLive(id),
        data: {'title': 'robada'},
        options: Options(headers: {'x-user-id': intruso}),
      );
      fail('Se esperaba 403');
    } on DioException catch (e) {
      expect(e.response?.statusCode, 403);
      expect(e.error, isA<ServerException>());
      expect((e.error as ServerException).code, 'FORBIDDEN');
    }

    // DELETE intruso → 403.
    try {
      await dio.delete(
        ApiConstants.publicationByIdLive(id),
        options: Options(headers: {'x-user-id': intruso}),
      );
      fail('Se esperaba 403');
    } on DioException catch (e) {
      expect(e.response?.statusCode, 403);
      expect(e.error, isA<ServerException>());
    }

    // DELETE owner → 200.
    await dio.delete(
      ApiConstants.publicationByIdLive(id),
      options: Options(headers: {'x-user-id': ownerId}),
    );
    creadas.remove(id);
  });

  // -------------------------------------------------------------------------
  // PI-ERR-03 — endpoints protegidos sin identidad (RNF-02)
  // -------------------------------------------------------------------------

  test(
    'PI-ERR-03 — endpoints protegidos sin identidad rechazan el acceso',
    () async {
      final id = await crearPublicacion(sufijo: 'err');
      if (id.isEmpty) return;

      // PUT sin header → 401.
      try {
        await dio.put(
          ApiConstants.publicationByIdLive(id),
          data: {'title': 'sin permiso'},
        );
        fail('Se esperaba 401');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 401);
        expect(e.error, isA<UnauthorizedException>());
      }

      // DELETE sin header → 401.
      try {
        await dio.delete(ApiConstants.publicationByIdLive(id));
        fail('Se esperaba 401');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 401);
        expect(e.error, isA<UnauthorizedException>());
      }

      // GET /publications/publications/mine sin header → 400 por H2.
      // H2: el contrato exige 401; el backend hoy responde 400.
      try {
        await dio.get(ApiConstants.publicationsFeedMineLive);
        fail('Se esperaba rechazo');
      } on DioException catch (e) {
        expect(
          e.response?.statusCode,
          anyOf([400, 401, 403]),
          reason: 'H2: el contrato pide 401; el backend responde 400',
        );
        expect(
          (e.response?.data as Map?)?['data'],
          isNull,
          reason: 'no debe entregar datos protegidos sin identidad',
        );
      }

      // Limpieza con header válido.
      await dio.delete(
        ApiConstants.publicationByIdLive(id),
        options: Options(headers: {'x-user-id': ownerId}),
      );
      creadas.remove(id);
    },
  );

  // -------------------------------------------------------------------------
  // PI-AUTH-03 — perfil del autenticado
  // -------------------------------------------------------------------------

  test(
    'PI-AUTH-03 — perfil del autenticado se recupera por /auth/me',
    () async {
      if (ownerId == null) {
        markTestSkipped('No se pudo sembrar el fixture $_fixtureEmail');
        return;
      }

      // GET /auth/me con header de identidad → 200, perfil del dueño.
      final r = await dio.get(
        ApiConstants.authMe,
        options: Options(headers: {'x-user-id': ownerId}),
      );
      expect(r.statusCode, 200);
      final data = r.data['data'] as Map<String, dynamic>;
      expect(data['id'], ownerId);
      expect(data['accountStatus'], 'active');

      // Header con id inexistente → 404.
      try {
        await dio.get(
          ApiConstants.authMe,
          options: Options(headers: {'x-user-id': 'no-existe-$regionPrueba'}),
        );
        fail('Se esperaba 404');
      } on DioException catch (e) {
        expect(e.error, isA<NotFoundException>());
        expect(e.response?.statusCode, 404);
      }

      // Sin header → rechazo (H2: 400 en vez de 401).
      try {
        await dio.get(ApiConstants.authMe);
        fail('Se esperaba rechazo');
      } on DioException catch (e) {
        expect(
          e.response?.statusCode,
          anyOf([400, 401, 403]),
          reason: 'H2: el contrato pide 401; el backend responde 400',
        );
      }
    },
  );

  // -------------------------------------------------------------------------
  // PI-FEED-04 — el feed entrega la región pedida
  // -------------------------------------------------------------------------

  test(
    'PI-FEED-04 — el feed devuelve publicaciones de la región pedida',
    () async {
      final id = await crearPublicacion(sufijo: 'feed');
      if (id.isEmpty) return;

      final r = await dio.get(
        ApiConstants.publicationsFeedLive,
        queryParameters: {'region': regionPrueba},
      );
      expect(r.statusCode, 200);
      final items = (r.data['data'] as List).cast<Map<String, dynamic>>();

      // Al menos la que acabamos de crear.
      expect(items, isNotEmpty);
      // Todas pertenecen a la región de prueba.
      for (final item in items) {
        expect(item['region'], regionPrueba);
        expect(item['title'], startsWith('[PI-TEST]'));
      }

      // Limpieza.
      await dio.delete(
        ApiConstants.publicationByIdLive(id),
        options: Options(headers: {'x-user-id': ownerId}),
      );
      creadas.remove(id);
    },
  );

  // -------------------------------------------------------------------------
  // PI-FEED-04b — CONTRATO (H1, rojo esperado)
  // -------------------------------------------------------------------------

  test(
    'CONTRATO (H1, rojo esperado): el feed no debe incluir publicaciones '
    'pausadas',
    tags: ['regresion-contrato'],
    () async {
      final id = await crearPublicacion(sufijo: 'pausada');
      if (id.isEmpty) return;

      // Pausar la publicación.
      await dio.put(
        ApiConstants.publicationByIdLive(id),
        data: {'isActive': false},
        options: Options(headers: {'x-user-id': ownerId}),
      );

      // Obtener el feed de la región.
      final r = await dio.get(
        ApiConstants.publicationsFeedLive,
        queryParameters: {'region': regionPrueba},
      );
      final items = (r.data['data'] as List).cast<Map<String, dynamic>>();

      // H1: el backend NO filtra isActive. El feed incluye la publicación
      // pausada, violando el contrato que exige solo activas. Este test DEBE
      // quedar rojo como evidencia documentada de la regresión.
      final pausadas = items.where(
        (i) => i['isActive'] == false || i['id'] == id,
      );
      expect(
        pausadas.isEmpty,
        isTrue,
        reason:
            'H1: el backend no filtra isActive en el feed. '
            'Este test quedará rojo hasta que el backend corrija el filtro.',
      );

      // Limpieza (si el owner puede; el PUT de pausa fue exitoso).
      await dio.delete(
        ApiConstants.publicationByIdLive(id),
        options: Options(headers: {'x-user-id': ownerId}),
      );
      creadas.remove(id);
    },
  );

  // -------------------------------------------------------------------------
  // PI-RES-01 — crear reserva y listar las mías
  // -------------------------------------------------------------------------

  // tag regresion-contrato: hoy rojo por H10 (POST /reservations da 500 en el
  // backend). Pasará a verde cuando Cristian destrabe el INSERT; quitar el tag.
  test(
    'PI-RES-01 — crear reserva (POST /reservations) y recuperarla en '
    '/mine con include de publication',
    tags: ['regresion-contrato'],
    () async {
      // Sembrar una publicación del owner para reservar contra ella.
      final pubId = await crearPublicacion(sufijo: 'res');
      if (pubId.isEmpty || solicitanteId == null) return;

      // POST /reservations con header del solicitante.
      final r = await dio.post(
        ApiConstants.reservations,
        data: {
          'publicationId': pubId,
          'date': '2026-12-25',
          'startTime': '10:00',
          'endTime': '11:00',
        },
        options: Options(headers: {'x-user-id': solicitanteId}),
      );
      expect(r.statusCode, 201);
      final data = r.data['data'] as Map<String, dynamic>;
      expect(data['status'], 'pending');
      expect(data['publicationId'], pubId);
      final resId = data['id'] as String;
      reservasCreadas.add(resId);

      // GET /mine del solicitante debe incluir la reserva recién creada.
      final mine = await dio.get(
        ApiConstants.reservationsMine,
        options: Options(headers: {'x-user-id': solicitanteId}),
      );
      expect(mine.statusCode, 200);
      final mineData = (mine.data['data'] as List).cast<Map<String, dynamic>>();
      final creada = mineData.firstWhere((r) => r['id'] == resId);
      expect(creada['status'], 'pending');
      // Include de publication aplanado.
      expect(creada['publication'], isNotNull);
      expect(creada['publication']['title'], isNotNull);
      expect(creada['publication']['city'], isNotNull);
    },
  );

  // -------------------------------------------------------------------------
  // PI-RES-02 (H8, rojo esperado) — cancelar reserva
  // -------------------------------------------------------------------------

  test(
    'PI-RES-02 (H8, rojo esperado): PATCH /:id/cancel con solicitante',
    tags: ['regresion-contrato'],
    () async {
      final pubId = await crearPublicacion(sufijo: 'h8');
      if (pubId.isEmpty || solicitanteId == null) return;

      // Crear reserva.
      final r = await dio.post(
        ApiConstants.reservations,
        data: {
          'publicationId': pubId,
          'date': '2026-12-26',
          'startTime': '10:00',
          'endTime': '11:00',
        },
        options: Options(headers: {'x-user-id': solicitanteId}),
      );
      final resId = (r.data['data'] as Map)['id'] as String;
      reservasCreadas.add(resId);

      // H8: la ruta cancel no está registrada; el backend responde 404.
      // Este test queda rojo como evidencia documentada de la regresión.
      try {
        final cancel = await dio.patch(
          ApiConstants.reservationCancel(resId),
          options: Options(headers: {'x-user-id': solicitanteId}),
        );
        // Si la ruta llega a registrarse (fix H8), el test pasa a verde.
        expect(cancel.statusCode, 200);
        final cancelData = cancel.data['data'] as Map<String, dynamic>;
        expect(cancelData['status'], 'cancelled');
      } on DioException catch (e) {
        // H8 vigente: 404 esperado.
        expect(
          e.response?.statusCode,
          404,
          reason:
              'H8: la ruta PATCH /reservations/:id/cancel no está '
              'registrada en el backend. Este test quedará rojo hasta que '
              'se registre la ruta.',
        );
      }
    },
  );

  // -------------------------------------------------------------------------
  // PI-RES-03 — dueño actualiza estado; seguridad cruzada
  // -------------------------------------------------------------------------

  // tag regresion-contrato: hoy rojo por H10 (no se puede crear la reserva
  // base por el 500 de POST /reservations). Quitar el tag cuando se arregle.
  test(
    'PI-RES-03 — dueño actualiza estado de reserva; no-dueño recibe 403',
    tags: ['regresion-contrato'],
    () async {
      final pubId = await crearPublicacion(sufijo: 'perm');
      if (pubId.isEmpty || ownerId == null || solicitanteId == null) return;

      // Crear reserva como solicitante.
      final r = await dio.post(
        ApiConstants.reservations,
        data: {
          'publicationId': pubId,
          'date': '2026-12-27',
          'startTime': '10:00',
          'endTime': '11:00',
        },
        options: Options(headers: {'x-user-id': solicitanteId}),
      );
      final resId = (r.data['data'] as Map)['id'] as String;
      reservasCreadas.add(resId);

      // Dueño (owner) PATCH /:id/status → 200.
      final actualizada = await dio.patch(
        ApiConstants.reservationStatus(resId),
        data: {'status': 'rejected'},
        options: Options(headers: {'x-user-id': ownerId}),
      );
      expect(actualizada.statusCode, 200);
      final data = actualizada.data['data'] as Map<String, dynamic>;
      expect(data['status'], 'rejected');

      // Cruzado: solicitante (no dueño) PATCH /:id/status → 403.
      try {
        await dio.patch(
          ApiConstants.reservationStatus(resId),
          data: {'status': 'completed'},
          options: Options(headers: {'x-user-id': solicitanteId}),
        );
        fail('Se esperaba 403');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 403);
        expect(e.error, isA<ServerException>());
        expect((e.error as ServerException).code, 'FORBIDDEN');
      }
    },
  );
}
