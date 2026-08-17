/// teacher_note.dart
///
/// Hive model representing a personal note created by a teacher.
///
/// IMPORTANT: This model is stored in Hive ONLY — it is NEVER synced to the
/// server (Google Apps Script or any remote endpoint). All data lives
/// exclusively on the local device. Clearing app data will permanently delete
/// all notes.
///
/// The generated adapter file is referenced via the `part` directive below.
/// Run the build_runner command to regenerate it whenever this file changes:
///   flutter pub run build_runner build --delete-conflicting-outputs
library;

import 'package:hive/hive.dart';

part 'teacher_note.g.dart';

/// [TeacherNote] holds a single personal note authored by a teacher.
///
/// Notes can optionally be linked to a library book via [linkedBookAccessionNo]
/// and are organized into folders identified by [folderId].
///
/// Supports voice-typing output: [content] is plain text and may be large.
@HiveType(typeId: 0)
class TeacherNote extends HiveObject {
  /// Creates a [TeacherNote].
  TeacherNote({
    required this.id,
    required this.folderId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.linkedBookAccessionNo,
  });

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// Unique identifier for this note (UUID v4).
  @HiveField(0)
  String id;

  /// Identifier of the [NoteFolder] this note belongs to.
  /// References `NoteFolder.id` stored in the `note_folders` Hive box.
  @HiveField(1)
  String folderId;

  /// Short descriptive title of the note.
  @HiveField(2)
  String title;

  /// Full body content of the note in plain text.
  ///
  /// Designed to store voice-typing output and manual keyboard input.
  /// No maximum length is enforced — Hive handles arbitrary-length strings.
  @HiveField(3)
  String content;

  /// Accession number of the library book this note references (optional).
  ///
  /// When set, the UI can display a direct link to the associated book record
  /// in the catalogue. This reference is stored as a plain string and is NOT
  /// a Hive relation — it is the consumer's responsibility to resolve it.
  @HiveField(4)
  String? linkedBookAccessionNo;

  /// Date and time when this note was first created.
  @HiveField(5)
  DateTime createdAt;

  /// Date and time when this note was last modified.
  @HiveField(6)
  DateTime updatedAt;

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  /// Returns a new [TeacherNote] with the specified fields replaced.
  ///
  /// Useful for producing an updated copy without mutating the original
  /// (e.g., before persisting a change to the Hive box).
  TeacherNote copyWith({
    String? id,
    String? folderId,
    String? title,
    String? content,
    String? linkedBookAccessionNo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeacherNote(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      content: content ?? this.content,
      linkedBookAccessionNo:
          linkedBookAccessionNo ?? this.linkedBookAccessionNo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'TeacherNote(id: $id, title: $title, folderId: $folderId)';
}
