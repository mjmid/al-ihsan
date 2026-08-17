/// routine_entry.dart
///
/// Hive model representing a class routine (timetable) slot for one or more days.
///
/// LOCAL ONLY — this model is never synced to any remote server or Google Apps
/// Script endpoint. Routine data exists exclusively on the local device.
///
/// Run the build_runner to regenerate the adapter whenever this file changes:
///   flutter pub run build_runner build --delete-conflicting-outputs
library;

import 'package:hive/hive.dart';

part 'routine_entry.g.dart';

/// [RoutineEntry] describes a single period in the class timetable.
///
/// Each entry covers one subject during a defined time window.
/// It supports multiple days in a week via [daysOfWeek].
///
/// Day-of-week follows the ISO 8601 convention used by [DateTime.weekday]:
///   1 = Monday … 7 = Sunday
@HiveType(typeId: 2)
class RoutineEntry extends HiveObject {
  /// Creates a [RoutineEntry].
  RoutineEntry({
    required this.id,
    required this.daysOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subjectName,
    required this.className,
    this.roomNumber,
    this.reminderMinutes,
    this.nightBeforeAlarm = false,
    this.nightBeforeAlarmTime,
    this.linkedBookAccessionNo,
    this.linkedBookName,
    this.notes,
  });

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// Unique identifier for this routine slot (UUID v4).
  @HiveField(0)
  String id;

  /// Start time of the period in 24-hour `HH:mm` format, e.g. `'08:00'`.
  @HiveField(2)
  String startTime;

  /// End time of the period in 24-hour `HH:mm` format, e.g. `'09:00'`.
  @HiveField(3)
  String endTime;

  /// Name of the subject or topic taught during this period.
  @HiveField(4)
  String subjectName;

  /// Name or identifier of the class / Jamat group being taught.
  @HiveField(5)
  String className;

  /// Accession number of the library book this routine references (optional).
  @HiveField(6)
  String? linkedBookAccessionNo;

  /// Title of the linked book for UI display (optional).
  @HiveField(7)
  String? linkedBookName;

  /// Personal notes or remarks for this class (optional).
  @HiveField(8)
  String? notes;

  /// List of ISO 8601 day-of-week indices when this routine applies.
  ///   1 = Monday, 2 = Tuesday, … 7 = Sunday.
  @HiveField(9)
  List<int> daysOfWeek;

  /// Room number where the class takes place (optional).
  @HiveField(10)
  String? roomNumber;

  /// Minutes before class to trigger an alarm (e.g. 10 or 15).
  @HiveField(11)
  int? reminderMinutes;

  /// Whether to trigger an alarm on the night before the class.
  @HiveField(12)
  bool nightBeforeAlarm;

  /// Time for the night before alarm in HH:mm format, e.g. "21:00"
  @HiveField(13)
  String? nightBeforeAlarmTime;
}
