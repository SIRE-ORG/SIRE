import 'package:equatable/equatable.dart';

enum DayOfWeek {
  sunday,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
}

class DaySchedule extends Equatable {
  const DaySchedule({required this.startTime, required this.endTime});

  final String startTime;
  final String endTime;

  @override
  List<Object?> get props => [startTime, endTime];
}

class DayOverride extends Equatable {
  const DayOverride({
    required this.dayOfWeek,
    required this.isClosed,
    required this.schedules,
  });

  final DayOfWeek dayOfWeek;
  final bool isClosed;
  final List<DaySchedule> schedules;

  @override
  List<Object?> get props => [dayOfWeek, isClosed, schedules];
}

class AvailabilityConfig extends Equatable {
  const AvailabilityConfig({
    required this.slotDurationMinutes,
    required this.sameScheduleAllDays,
    required this.defaultSchedules,
    required this.dayOverrides,
  });

  final int slotDurationMinutes;
  final bool sameScheduleAllDays;
  final List<DaySchedule> defaultSchedules;
  final List<DayOverride> dayOverrides;

  @override
  List<Object?> get props => [
    slotDurationMinutes,
    sameScheduleAllDays,
    defaultSchedules,
    dayOverrides,
  ];
}
