/// user_model.dart
///
/// Immutable domain model representing a library member (admin, teacher, or
/// student) in the Maktaba Ihsan system.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// UserType enum
// ---------------------------------------------------------------------------

/// Describes the role / privilege level of a library user.
enum UserType {
  /// Full system administrator with unrestricted access.
  admin,

  /// A teaching staff member; may access teacher-specific features.
  teacher,

  /// A student / madrasa pupil; has borrowing privileges only.
  student,
}

/// Extension on [UserType] that handles conversion to and from the string
/// values stored in the SQLite `users.type` column.
extension UserTypeX on UserType {
  /// Converts this [UserType] to its canonical database string representation.
  String toDbString() {
    switch (this) {
      case UserType.admin:
        return 'Admin';
      case UserType.teacher:
        return 'Teacher';
      case UserType.student:
        return 'Student';
    }
  }

  /// Returns a human-readable label for display in the UI.
  String get displayLabel => toDbString();
}

/// Parses a raw [value] string into a [UserType].
///
/// Falls back to [UserType.student] when the value is unrecognised.
UserType userTypeFromString(String? value) {
  switch ((value ?? '').toLowerCase().trim()) {
    case 'admin':
      return UserType.admin;
    case 'teacher':
      return UserType.teacher;
    case 'student':
    default:
      return UserType.student;
  }
}

// ---------------------------------------------------------------------------
// UserStatus enum
// ---------------------------------------------------------------------------

/// Represents whether a user account is active or has been archived.
enum UserStatus {
  /// The account is in good standing and the user may borrow books.
  active,

  /// The account has been deactivated / archived; borrowing is disabled.
  archived,
}

/// Extension on [UserStatus] for database string conversion.
extension UserStatusX on UserStatus {
  /// Converts this [UserStatus] to its canonical database string.
  String toDbString() {
    switch (this) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.archived:
        return 'Archived';
    }
  }

  /// Returns a human-readable label for display in the UI.
  String get displayLabel => toDbString();
}

/// Parses a raw [value] string into a [UserStatus].
///
/// Falls back to [UserStatus.active] when the value is unrecognised.
UserStatus userStatusFromString(String? value) {
  switch ((value ?? '').toLowerCase().trim()) {
    case 'archived':
      return UserStatus.archived;
    case 'active':
    default:
      return UserStatus.active;
  }
}

// ---------------------------------------------------------------------------
// User model
// ---------------------------------------------------------------------------

/// An immutable value object representing a single library member.
///
/// The [pin] field holds a **hashed** value — the raw PIN is never stored in
/// plain text. Always hash before setting and verify by comparing hashes.
@immutable
class User extends Equatable {
  /// Creates a [User] with all required and optional fields.
  const User({
    required this.userId,
    required this.name,
    required this.type,
    required this.status,
    required this.lastUpdated,
    this.phone,
    this.pin,
    this.classJamat,
  });

  // ---------------------------------------------------------------------------
  // Fields — mirror the `users` table schema exactly.
  // ---------------------------------------------------------------------------

  /// Unique identifier for this user (UUID or custom ID).
  final String userId;

  /// Full name of the user as it appears on their registration record.
  final String name;

  /// Role of the user within the library system.
  final UserType type;

  /// Contact phone number (nullable; not required for students).
  final String? phone;

  /// Hashed PIN used for quick PIN-based authentication.
  ///
  /// **SECURITY NOTE**: This field stores the HASHED form of the PIN only.
  /// The raw numeric PIN must never be persisted anywhere in the app.
  /// Use a suitable one-way hash (e.g. SHA-256 with a salt) before storing.
  final String? pin;

  /// Class or Jamat (year group) for student users; nullable for staff.
  final String? classJamat;

  /// Current account status.
  final UserStatus status;

  /// Timestamp of the last modification to this record.
  final DateTime lastUpdated;

  // ---------------------------------------------------------------------------
  // Factory constructors
  // ---------------------------------------------------------------------------

  /// Creates a [User] from a [Map] row returned by sqflite.
  ///
  /// Column names are expected to follow the `snake_case` database schema.
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'] as String,
      name: map['name'] as String,
      type: userTypeFromString(map['type'] as String?),
      phone: map['phone'] as String?,
      pin: map['pin'] as String?,
      classJamat: map['class_jamat'] as String?,
      status: userStatusFromString(map['status'] as String?),
      lastUpdated: DateTime.tryParse(map['last_updated'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Creates a [User] from a JSON [Map] received from the Google Apps Script
  /// API sync endpoint.
  factory User.fromJson(Map<String, dynamic> json) => User.fromMap(json);

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Converts this [User] to a [Map] suitable for insertion into sqflite.
  ///
  /// All keys use `snake_case` to match the database column names.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'type': type.toDbString(),
      'phone': phone,
      'pin': pin,
      'class_jamat': classJamat,
      'status': status.toDbString(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  /// Converts this [User] to a JSON-serializable [Map] for API sync.
  ///
  /// Note: [pin] is included intentionally for sync purposes only.
  /// Ensure the transport layer is encrypted (HTTPS) at all times.
  Map<String, dynamic> toJson() => toMap();

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  /// Returns a copy of this [User] with the specified fields replaced.
  User copyWith({
    String? userId,
    String? name,
    UserType? type,
    String? phone,
    String? pin,
    String? classJamat,
    UserStatus? status,
    DateTime? lastUpdated,
  }) {
    return User(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      phone: phone ?? this.phone,
      pin: pin ?? this.pin,
      classJamat: classJamat ?? this.classJamat,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // ---------------------------------------------------------------------------
  // Equatable
  // ---------------------------------------------------------------------------

  @override
  List<Object?> get props => [
        userId,
        name,
        type,
        phone,
        pin,
        classJamat,
        status,
        lastUpdated,
      ];

  @override
  String toString() =>
      'User(userId: $userId, name: $name, type: $type, status: $status)';
}
