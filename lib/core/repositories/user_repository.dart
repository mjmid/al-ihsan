/// ---------------------------------------------------------------------------
/// user_repository.dart
/// ---------------------------------------------------------------------------
/// Repository for all local SQLite read/write operations on library members
/// (students, teachers, staff).
///
/// Security note on PIN storage:
///   PINs are **never stored in plain text** either locally or remotely.
///   The repository stores and compares SHA-256 hashes only.
///   The static [UserRepository.hashPin] method is the single canonical
///   hashing entry point used by both registration and authentication.
///
/// Dependency note:
///   Add the `crypto` package to pubspec.yaml:
///   ```yaml
///   dependencies:
///     crypto: ^3.0.3
///   ```
/// ---------------------------------------------------------------------------

import 'dart:convert'; // utf8

import 'package:crypto/crypto.dart'; // sha256 — add crypto: ^3.0.3 to pubspec
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../services/sync_queue_service.dart';

/// Repository for User (library member) database operations.
class UserRepository {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  final DatabaseHelper _db;
  final SyncQueueNotifier _syncQueue;

  const UserRepository({
    required DatabaseHelper db,
    required SyncQueueNotifier syncQueue,
  })  : _db = db,
        _syncQueue = syncQueue;

  // ---------------------------------------------------------------------------
  // PIN hashing
  // ---------------------------------------------------------------------------

  /// Returns the SHA-256 hex-digest of [pin].
  ///
  /// This is a **static** method so that it can be called from the
  /// registration flow (outside a repository context) without needing a
  /// repository instance.
  ///
  /// Example:
  /// ```dart
  /// final hash = UserRepository.hashPin('1234');
  /// // → 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3'
  /// ```
  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  /// Attempts to authenticate a user by matching [nameOrPhone] + [pin].
  ///
  /// The PIN is hashed before comparison — the plain-text PIN is never stored
  /// or compared.  Both `full_name` and `phone` are searched so that teachers
  /// can log in with either.
  ///
  /// [nameOrPhone] must match either `full_name` or `phone`.
  /// [pin] must match the `pin_hash` when hashed.
  /// Only Active users can authenticate.
  Future<User?> authenticateUser(
    String nameOrPhone,
    String pin,
  ) async {
    final db = await _db.database;
    final hashedPin = hashPin(pin);

    final rows = await db.query(
      kUsersTable,
      where: '''
        (name = ? OR phone = ?)
        AND pin   = ?
        AND status     = 'Active'
      ''',
      whereArgs: [nameOrPhone, nameOrPhone, hashedPin],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// Returns all users, with optional filtering by [status] and/or [type].
  ///
  /// Results are ordered by `full_name` ascending.
  Future<List<User>> getAllUsers({
    UserStatus? status,
    UserType? type,
  }) async {
    final db = await _db.database;

    final conditions = <String>[];
    final args = <dynamic>[];

    if (status != null) {
      conditions.add('status = ?');
      args.add(status.toDbString());
    }
    if (type != null) {
      conditions.add('type = ?');
      args.add(type.toDbString());
    }

    final where = conditions.isEmpty ? null : conditions.join(' AND ');

    final rows = await db.query(
      kUsersTable,
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name ASC',
    );

    return rows.map(User.fromMap).toList();
  }

  /// Returns the user identified by [userId], or `null` if not found.
  Future<User?> getUserById(String userId) async {
    final db = await _db.database;

    final rows = await db.query(
      kUsersTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  /// Returns the total count of users, optionally scoped to a [type].
  ///
  /// Useful for dashboard summary cards ("Total Students: 120").
  Future<int> getTotalUsersCount({UserType? type}) async {
    final db = await _db.database;

    if (type == null) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM $kUsersTable WHERE status != ?',
        ['Archived'],
      );
      return (result.first['count'] as int?) ?? 0;
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM $kUsersTable WHERE type = ? AND status != ?',
      [type.toDbString(), 'Archived'],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Inserts or replaces [user] in the local database, then enqueues a remote
  /// sync operation.
  ///
  /// **PIN handling**: the caller is responsible for providing a [User] whose
  /// `pinHash` field is already the result of [hashPin].  This repository
  /// never hashes PINs itself to avoid double-hashing bugs.
  Future<void> upsertUser(User user) async {
    final db = await _db.database;

    await db.insert(
      kUsersTable,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _syncQueue.enqueue(
      SyncOperation.create(
        sheet: 'Users',
        action: 'upsert',
        payload: user.toMap(),
      ),
    );
  }

  /// Soft-deletes the user identified by [userId] by setting `status` to
  /// `'Archived'` and bumping `updated_at`.
  ///
  /// The row is **not** physically deleted from SQLite so that historical
  /// transaction records remain referentially consistent.
  Future<void> archiveUser(String userId) async {
    final db = await _db.database;
    final now = DateTime.now().toUtc().toIso8601String();

    await db.update(
      kUsersTable,
      {'status': UserStatus.archived.toDbString(), 'last_updated': now},
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    // Enqueue a soft-delete sync so GAS also marks the row as Archived.
    _syncQueue.enqueue(
      SyncOperation.create(
        sheet: 'Users',
        action: 'delete',
        payload: {
          'user_id': userId,
          'status': UserStatus.archived.toDbString(),
          'last_updated': now,
        },
      ),
    );
  }
}
