import 'package:flutter_test/flutter_test.dart';
import 'package:sire/features/publications/domain/entities/availability_config.dart';
import 'package:sire/features/publications/domain/entities/publication.dart';
import 'package:sire/features/publications/domain/entities/publication_summary_item.dart';
import 'package:sire/features/feed/domain/entities/feed_page.dart';
import 'package:sire/features/feed/domain/entities/publication_summary.dart';
import 'package:sire/features/auth/domain/entities/user_profile.dart';

void main() {
  const testAvailability = AvailabilityConfig(
    slotDurationMinutes: 60,
    sameScheduleAllDays: true,
    defaultSchedules: [DaySchedule(startTime: '09:00', endTime: '18:00')],
    dayOverrides: [],
  );

  group('AvailabilityConfig', () {
    test('constructor asigna todos los campos', () {
      const config = AvailabilityConfig(
        slotDurationMinutes: 30,
        sameScheduleAllDays: false,
        defaultSchedules: [DaySchedule(startTime: '10:00', endTime: '20:00')],
        dayOverrides: [],
      );
      expect(config.slotDurationMinutes, 30);
      expect(config.sameScheduleAllDays, false);
      expect(config.defaultSchedules.length, 1);
      expect(config.dayOverrides, isEmpty);
    });

    test('igualdad de valor funciona correctamente', () {
      const a = AvailabilityConfig(
        slotDurationMinutes: 60,
        sameScheduleAllDays: true,
        defaultSchedules: [DaySchedule(startTime: '09:00', endTime: '18:00')],
        dayOverrides: [],
      );
      const b = AvailabilityConfig(
        slotDurationMinutes: 60,
        sameScheduleAllDays: true,
        defaultSchedules: [DaySchedule(startTime: '09:00', endTime: '18:00')],
        dayOverrides: [],
      );
      expect(a, equals(b));
    });

    test('DaySchedule asigna startTime y endTime', () {
      const s = DaySchedule(startTime: '08:00', endTime: '16:00');
      expect(s.startTime, '08:00');
      expect(s.endTime, '16:00');
    });

    test('DayOverride asigna campos correctamente', () {
      const override = DayOverride(
        dayOfWeek: DayOfWeek.sunday,
        isClosed: true,
        schedules: [],
      );
      expect(override.dayOfWeek, DayOfWeek.sunday);
      expect(override.isClosed, true);
      expect(override.schedules, isEmpty);
    });
  });

  group('Publication', () {
    const pub = Publication(
      id: 'pub-1',
      title: 'Cancha de fútbol',
      description: 'Descripción de la cancha',
      region: 'Biobío',
      category: PublicationCategory.deporte,
      ownerId: 'owner-1',
      ownerName: 'Juan Pérez',
      isActive: true,
      availability: testAvailability,
      createdAt: '2026-01-01T00:00:00Z',
    );

    test('constructor asigna todos los campos requeridos', () {
      expect(pub.id, 'pub-1');
      expect(pub.title, 'Cancha de fútbol');
      expect(pub.category, PublicationCategory.deporte);
      expect(pub.isActive, true);
      expect(pub.imageUrl, isNull);
      expect(pub.city, isNull);
      expect(pub.rating, isNull);
    });

    test('props contiene todos los campos para igualdad', () {
      const same = Publication(
        id: 'pub-1',
        title: 'Cancha de fútbol',
        description: 'Descripción de la cancha',
        region: 'Biobío',
        category: PublicationCategory.deporte,
        ownerId: 'owner-1',
        ownerName: 'Juan Pérez',
        isActive: true,
        availability: testAvailability,
        createdAt: '2026-01-01T00:00:00Z',
      );
      expect(pub, equals(same));
    });

    test('PublicationCategory tiene valores esperados', () {
      expect(PublicationCategory.values, hasLength(4));
      expect(PublicationCategory.values, contains(PublicationCategory.deporte));
      expect(PublicationCategory.values, contains(PublicationCategory.eventos));
      expect(
        PublicationCategory.values,
        contains(PublicationCategory.recreacion),
      );
      expect(PublicationCategory.values, contains(PublicationCategory.otros));
    });
  });

  group('PublicationSummaryItem', () {
    const item = PublicationSummaryItem(
      id: 'ps-1',
      title: 'Yoga matinal',
      category: PublicationCategory.recreacion,
      region: 'Metropolitana',
      isActive: true,
      createdAt: '2026-02-01T00:00:00Z',
    );

    test('constructor asigna campos correctamente', () {
      expect(item.id, 'ps-1');
      expect(item.title, 'Yoga matinal');
      expect(item.category, PublicationCategory.recreacion);
      expect(item.isActive, true);
      expect(item.imageUrl, isNull);
    });

    test('instancias con mismo valor son iguales', () {
      const same = PublicationSummaryItem(
        id: 'ps-1',
        title: 'Yoga matinal',
        category: PublicationCategory.recreacion,
        region: 'Metropolitana',
        isActive: true,
        createdAt: '2026-02-01T00:00:00Z',
      );
      expect(item, equals(same));
    });

    test('instancias con valores distintos no son iguales', () {
      const different = PublicationSummaryItem(
        id: 'ps-2',
        title: 'Otra',
        category: PublicationCategory.otros,
        region: 'Sur',
        isActive: false,
        createdAt: '2026-03-01T00:00:00Z',
      );
      expect(item, isNot(equals(different)));
    });
  });

  group('PublicationSummary', () {
    const summary = PublicationSummary(
      id: 'ps-001',
      title: 'Evento Cultural',
      description: 'Evento de arte local',
      region: 'Valparaíso',
      category: PublicationCategory.eventos,
      ownerName: 'Ana López',
      ownerId: 'owner-ana',
      createdAt: '2026-03-15T00:00:00Z',
    );

    test('constructor asigna campos requeridos', () {
      expect(summary.id, 'ps-001');
      expect(summary.title, 'Evento Cultural');
      expect(summary.category, PublicationCategory.eventos);
      expect(summary.imageUrl, isNull);
      expect(summary.city, isNull);
      expect(summary.rating, isNull);
    });

    test('instancias con mismo valor son iguales', () {
      const same = PublicationSummary(
        id: 'ps-001',
        title: 'Evento Cultural',
        description: 'Evento de arte local',
        region: 'Valparaíso',
        category: PublicationCategory.eventos,
        ownerName: 'Ana López',
        ownerId: 'owner-ana',
        createdAt: '2026-03-15T00:00:00Z',
      );
      expect(summary, equals(same));
    });
  });

  group('FeedPage', () {
    const basePage = FeedPage(
      items: [],
      page: 1,
      limit: 20,
      total: 0,
      hasMore: false,
      currentRegion: 'Biobío',
      currentOrder: FeedOrder.recent,
    );

    test('constructor asigna todos los campos', () {
      expect(basePage.page, 1);
      expect(basePage.limit, 20);
      expect(basePage.total, 0);
      expect(basePage.hasMore, false);
      expect(basePage.currentRegion, 'Biobío');
      expect(basePage.currentCity, isNull);
      expect(basePage.currentCategory, isNull);
      expect(basePage.currentOrder, FeedOrder.recent);
    });

    test('copyWith actualiza page', () {
      final updated = basePage.copyWith(page: 2);
      expect(updated.page, 2);
      expect(updated.limit, 20);
      expect(updated.currentRegion, 'Biobío');
    });

    test('copyWith actualiza hasMore y total', () {
      final updated = basePage.copyWith(hasMore: true, total: 50);
      expect(updated.hasMore, true);
      expect(updated.total, 50);
      expect(updated.page, 1);
    });

    test('copyWith con clearCategory = true limpia la categoría', () {
      final withCat = basePage.copyWith(
        currentCategory: PublicationCategory.deporte,
      );
      expect(withCat.currentCategory, PublicationCategory.deporte);

      final cleared = withCat.copyWith(clearCategory: true);
      expect(cleared.currentCategory, isNull);
    });

    test('copyWith actualiza currentRegion', () {
      final updated = basePage.copyWith(currentRegion: 'Metropolitana');
      expect(updated.currentRegion, 'Metropolitana');
    });

    test('copyWith actualiza currentCity', () {
      final updated = basePage.copyWith(currentCity: 'Santiago');
      expect(updated.currentCity, 'Santiago');
    });

    test('FeedOrder tiene los valores esperados', () {
      expect(FeedOrder.values, hasLength(3));
      expect(FeedOrder.values, contains(FeedOrder.recent));
      expect(FeedOrder.values, contains(FeedOrder.rating));
      expect(FeedOrder.values, contains(FeedOrder.popular));
    });

    test('instancias con mismo valor son iguales', () {
      const same = FeedPage(
        items: [],
        page: 1,
        limit: 20,
        total: 0,
        hasMore: false,
        currentRegion: 'Biobío',
        currentOrder: FeedOrder.recent,
      );
      expect(basePage, equals(same));
    });
  });

  group('UserProfile', () {
    const profile = UserProfile(
      id: 'user-1',
      name: 'Emilia Toro',
      email: 'emilia@ufro.cl',
      accountStatus: AccountStatus.active,
      emailVerified: true,
    );

    test('constructor asigna campos requeridos', () {
      expect(profile.id, 'user-1');
      expect(profile.name, 'Emilia Toro');
      expect(profile.email, 'emilia@ufro.cl');
      expect(profile.accountStatus, AccountStatus.active);
      expect(profile.emailVerified, true);
      expect(profile.phone, isNull);
      expect(profile.avatarUrl, isNull);
    });

    test('constructor con campos opcionales', () {
      const withOptionals = UserProfile(
        id: 'user-2',
        name: 'Carlos',
        email: 'carlos@test.cl',
        accountStatus: AccountStatus.guest,
        emailVerified: false,
        phone: '+56912345678',
        avatarUrl: 'https://cdn.example.com/avatar.jpg',
      );
      expect(withOptionals.phone, '+56912345678');
      expect(withOptionals.avatarUrl, 'https://cdn.example.com/avatar.jpg');
      expect(withOptionals.accountStatus, AccountStatus.guest);
    });

    test('AccountStatus tiene los valores esperados', () {
      // `anon` es un tercer estado derivado en Flutter (sesión Supabase
      // anónima sin fila de perfil): no existe en la DB ni en fromJson.
      expect(AccountStatus.values, hasLength(3));
      expect(AccountStatus.values, contains(AccountStatus.guest));
      expect(AccountStatus.values, contains(AccountStatus.active));
      expect(AccountStatus.values, contains(AccountStatus.anon));
    });

    test('instancias con mismo valor son iguales', () {
      const same = UserProfile(
        id: 'user-1',
        name: 'Emilia Toro',
        email: 'emilia@ufro.cl',
        accountStatus: AccountStatus.active,
        emailVerified: true,
      );
      expect(profile, equals(same));
    });

    test('instancias con distinto id no son iguales', () {
      const other = UserProfile(
        id: 'user-9',
        name: 'Emilia Toro',
        email: 'emilia@ufro.cl',
        accountStatus: AccountStatus.active,
        emailVerified: true,
      );
      expect(profile, isNot(equals(other)));
    });
  });
}
