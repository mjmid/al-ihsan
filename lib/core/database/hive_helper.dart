/// hive_helper.dart
///
/// Hive database helper for Maktaba Ihsan library management system.
///
/// IMPORTANT: All boxes managed here are LOCAL ONLY.
/// They are NEVER synced to Google Apps Script or any remote server.
/// They exist purely for offline-first, device-local features such as:
///   - Teacher personal notes
///   - Class routine entries
///   - Application settings / preferences
///   - Note folder organization
library;

import 'package:hive_flutter/hive_flutter.dart';

import '../models/hive_models/note_folder.dart';
import '../models/hive_models/routine_entry.dart';
import '../models/hive_models/teacher_note.dart';

// ---------------------------------------------------------------------------
// Box name constants
// ---------------------------------------------------------------------------

/// Hive box that stores [TeacherNote] objects.
const String kTeacherNotesBox = 'teacher_notes';

/// Hive box that stores [RoutineEntry] objects.
const String kRoutineBox = 'routine_v2';

/// Hive box that stores application settings as key-value pairs.
const String kSettingsBox = 'settings';

/// Hive box that stores [NoteFolder] objects.
const String kNoteFoldersBox = 'note_folders';

// ---------------------------------------------------------------------------
// HiveHelper
// ---------------------------------------------------------------------------

/// [HiveHelper] centralizes all Hive initialization, adapter registration,
/// and box management for Maktaba Ihsan.
///
/// Call [initialize] once at app startup (before [runApp]) and then access
/// typed boxes through the static getters.
///
/// Example:
/// ```dart
/// await HiveHelper.initialize();
/// final note = HiveHelper.notesBox.get('some-id');
/// ```
class HiveHelper {
  // Prevent instantiation — all members are static.
  HiveHelper._();

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes Hive, registers all TypeAdapters, and opens all boxes.
  ///
  /// Must be called exactly once before any box is accessed.
  /// Typically invoked from `main()` before [runApp].
  static Future<void> initialize() async {
    // Initialize Hive with Flutter path provider integration so that the
    // storage directory is resolved correctly on every platform.
    await Hive.initFlutter();

    // -------------------------------------------------------------------------
    // Register TypeAdapters
    // Each adapter is only registered if it has not been registered before,
    // which prevents duplicate registration errors during hot-restart in debug.
    // -------------------------------------------------------------------------

    if (!Hive.isAdapterRegistered(TeacherNoteAdapter().typeId)) {
      Hive.registerAdapter(TeacherNoteAdapter());
    }

    if (!Hive.isAdapterRegistered(NoteFolderAdapter().typeId)) {
      Hive.registerAdapter(NoteFolderAdapter());
    }

    if (!Hive.isAdapterRegistered(RoutineEntryAdapter().typeId)) {
      Hive.registerAdapter(RoutineEntryAdapter());
    }

    // -------------------------------------------------------------------------
    // Open boxes
    // All boxes are opened upfront so that synchronous access via getters
    // works correctly at any point after initialization.
    // -------------------------------------------------------------------------

    await Future.wait([
      Hive.openBox<TeacherNote>(kTeacherNotesBox),
      Hive.openBox<NoteFolder>(kNoteFoldersBox),
      Hive.openBox<RoutineEntry>(kRoutineBox),
      Hive.openBox<dynamic>(kSettingsBox),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Typed box getters
  // ---------------------------------------------------------------------------

  /// Returns the open [Box] containing [TeacherNote] objects.
  ///
  /// Throws a [HiveError] if [initialize] has not been called yet.
  static Box<TeacherNote> get notesBox =>
      Hive.box<TeacherNote>(kTeacherNotesBox);

  /// Returns the open [Box] containing [RoutineEntry] objects.
  ///
  /// Throws a [HiveError] if [initialize] has not been called yet.
  static Box<RoutineEntry> get routineBox =>
      Hive.box<RoutineEntry>(kRoutineBox);

  /// Returns the open [Box] storing application settings as dynamic values.
  ///
  /// Throws a [HiveError] if [initialize] has not been called yet.
  static Box<dynamic> get settingsBox => Hive.box<dynamic>(kSettingsBox);

  /// Returns the open [Box] containing [NoteFolder] objects.
  ///
  /// Throws a [HiveError] if [initialize] has not been called yet.
  static Box<NoteFolder> get foldersBox =>
      Hive.box<NoteFolder>(kNoteFoldersBox);

  // ---------------------------------------------------------------------------
  // Settings convenience methods
  // ---------------------------------------------------------------------------

  /// Reads a setting value from the settings box.
  ///
  /// Returns [defaultValue] when the key is absent or the stored value cannot
  /// be cast to [T].
  ///
  /// Example:
  /// ```dart
  /// final isDark = HiveHelper.getSetting<bool>('darkMode', false);
  /// ```
  static T getSetting<T>(String key, T defaultValue) {
    final value = settingsBox.get(key);
    if (value is T) return value;
    return defaultValue;
  }

  /// Persists a setting value to the settings box.
  ///
  /// Example:
  /// ```dart
  /// await HiveHelper.setSetting<bool>('darkMode', true);
  /// ```
  static Future<void> setSetting<T>(String key, T value) async {
    await settingsBox.put(key, value);
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Flushes and closes all open Hive boxes.
  ///
  /// Call this when the application is shutting down to ensure all pending
  /// writes are flushed to disk.
  static Future<void> closeAll() async {
    await Hive.close();
  }
}
