/// note_folder.dart
///
/// Hive model representing a folder used to organize [TeacherNote] objects.
///
/// LOCAL ONLY — this model is never synced to any remote server or Google Apps
/// Script endpoint. Folder data exists exclusively on the local device.
///
/// Run the build_runner to regenerate the adapter whenever this file changes:
///   flutter pub run build_runner build --delete-conflicting-outputs
library;

import 'package:hive/hive.dart';

part 'note_folder.g.dart';

/// [NoteFolder] represents a named, colored container for grouping
/// [TeacherNote] records in the local Hive database.
///
/// Teachers can create as many folders as needed, each with a distinct color
/// to aid quick visual identification in the UI.
@HiveType(typeId: 1)
class NoteFolder extends HiveObject {
  /// Creates a [NoteFolder].
  NoteFolder({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.createdAt,
  });

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// Unique identifier for this folder (UUID v4).
  @HiveField(0)
  String id;

  /// Display name of the folder as entered by the teacher.
  @HiveField(1)
  String name;

  /// Hex color string used to visually distinguish this folder in the UI.
  ///
  /// Must be a valid 6-digit hex color prefixed with `#`, e.g. `'#FF5733'`.
  /// The UI layer is responsible for parsing and rendering this value.
  @HiveField(2)
  String colorHex;

  /// Date and time when this folder was created.
  @HiveField(3)
  DateTime createdAt;

  @override
  String toString() => 'NoteFolder(id: $id, name: $name, colorHex: $colorHex)';
}
