import '../../domain/entities/availability_config.dart';
import '../../domain/entities/publication.dart';

PublicationCategory publicationCategoryFromString(String raw) {
  switch (raw.toLowerCase()) {
    case 'deporte':
      return PublicationCategory.deporte;
    case 'eventos':
      return PublicationCategory.eventos;
    case 'recreacion':
    case 'recreación':
      return PublicationCategory.recreacion;
    default:
      return PublicationCategory.otros;
  }
}

String publicationCategoryToString(PublicationCategory category) =>
    category.name.toUpperCase();

DayOfWeek _dayOfWeekFromString(String raw) {
  try {
    return DayOfWeek.values.byName(raw.toLowerCase());
  } catch (_) {
    return DayOfWeek.monday;
  }
}

class DayScheduleModel {
  const DayScheduleModel({required this.startTime, required this.endTime});

  final String startTime;
  final String endTime;

  factory DayScheduleModel.fromJson(Map<String, dynamic> json) {
    return DayScheduleModel(
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'startTime': startTime, 'endTime': endTime};

  DaySchedule toEntity() => DaySchedule(startTime: startTime, endTime: endTime);

  factory DayScheduleModel.fromEntity(DaySchedule entity) =>
      DayScheduleModel(startTime: entity.startTime, endTime: entity.endTime);
}

class DayOverrideModel {
  const DayOverrideModel({
    required this.dayOfWeek,
    required this.isClosed,
    required this.schedules,
  });

  final String dayOfWeek;
  final bool isClosed;
  final List<DayScheduleModel> schedules;

  factory DayOverrideModel.fromJson(Map<String, dynamic> json) {
    return DayOverrideModel(
      dayOfWeek: json['dayOfWeek'] as String,
      isClosed: json['isClosed'] as bool? ?? false,
      schedules: ((json['schedules'] as List?) ?? const [])
          .map((e) => DayScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'isClosed': isClosed,
    'schedules': schedules.map((s) => s.toJson()).toList(),
  };

  DayOverride toEntity() => DayOverride(
    dayOfWeek: _dayOfWeekFromString(dayOfWeek),
    isClosed: isClosed,
    schedules: schedules.map((s) => s.toEntity()).toList(),
  );

  factory DayOverrideModel.fromEntity(DayOverride entity) => DayOverrideModel(
    dayOfWeek: entity.dayOfWeek.name.toUpperCase(),
    isClosed: entity.isClosed,
    schedules: entity.schedules.map(DayScheduleModel.fromEntity).toList(),
  );
}

class AvailabilityConfigModel {
  const AvailabilityConfigModel({
    required this.slotDurationMinutes,
    required this.sameScheduleAllDays,
    required this.defaultSchedules,
    required this.dayOverrides,
  });

  final int slotDurationMinutes;
  final bool sameScheduleAllDays;
  final List<DayScheduleModel> defaultSchedules;
  final List<DayOverrideModel> dayOverrides;

  factory AvailabilityConfigModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityConfigModel(
      slotDurationMinutes: json['slotDurationMinutes'] as int,
      sameScheduleAllDays: json['sameScheduleAllDays'] as bool? ?? true,
      defaultSchedules: ((json['defaultSchedules'] as List?) ?? const [])
          .map((e) => DayScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      dayOverrides: ((json['dayOverrides'] as List?) ?? const [])
          .map((e) => DayOverrideModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'slotDurationMinutes': slotDurationMinutes,
    'sameScheduleAllDays': sameScheduleAllDays,
    'defaultSchedules': defaultSchedules.map((s) => s.toJson()).toList(),
    'dayOverrides': dayOverrides.map((o) => o.toJson()).toList(),
  };

  AvailabilityConfig toEntity() => AvailabilityConfig(
    slotDurationMinutes: slotDurationMinutes,
    sameScheduleAllDays: sameScheduleAllDays,
    defaultSchedules: defaultSchedules.map((s) => s.toEntity()).toList(),
    dayOverrides: dayOverrides.map((o) => o.toEntity()).toList(),
  );

  factory AvailabilityConfigModel.fromEntity(AvailabilityConfig entity) =>
      AvailabilityConfigModel(
        slotDurationMinutes: entity.slotDurationMinutes,
        sameScheduleAllDays: entity.sameScheduleAllDays,
        defaultSchedules: entity.defaultSchedules
            .map(DayScheduleModel.fromEntity)
            .toList(),
        dayOverrides: entity.dayOverrides
            .map(DayOverrideModel.fromEntity)
            .toList(),
      );
}

class PublicationDetailModel {
  const PublicationDetailModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.region,
    this.city,
    required this.category,
    required this.ownerId,
    required this.ownerName,
    this.rating,
    required this.isActive,
    required this.availability,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String region;
  final String? city;
  final String category;
  final String ownerId;
  final String ownerName;
  final double? rating;
  final bool isActive;
  final AvailabilityConfigModel availability;
  final String createdAt;

  factory PublicationDetailModel.fromJson(Map<String, dynamic> json) {
    return PublicationDetailModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      region: json['region'] as String? ?? '',
      city: json['city'] as String?,
      category: json['category'] as String? ?? 'OTROS',
      ownerId: json['ownerId'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      availability: AvailabilityConfigModel.fromJson(
        (json['availability'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Publication toEntity() => Publication(
    id: id,
    title: title,
    description: description,
    imageUrl: imageUrl,
    region: region,
    city: city,
    category: publicationCategoryFromString(category),
    ownerId: ownerId,
    ownerName: ownerName,
    rating: rating,
    isActive: isActive,
    availability: availability.toEntity(),
    createdAt: createdAt,
  );
}
