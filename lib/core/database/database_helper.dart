/// database_helper.dart
///
/// SQLite database helper for Maktaba Ihsan library management system.
/// Uses sqflite for mobile platforms and sqflite_common_ffi for desktop.
/// Implements the Singleton pattern to ensure a single database connection
/// throughout the application's lifecycle.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../constants/app_constants.dart';

/// The name of the SQLite database file.
const String kDatabaseName = 'maktaba_ihsan.db';

/// The current schema version of the database.
const int kDatabaseVersion = 2;

// ---------------------------------------------------------------------------
// Table name constants
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Singleton DatabaseHelper
// ---------------------------------------------------------------------------

/// [DatabaseHelper] provides a single, shared access point to the SQLite
/// database used by Maktaba Ihsan.
///
/// Usage:
/// ```dart
/// final db = DatabaseHelper.instance;
/// final books = await db.query('books');
/// ```
class DatabaseHelper {
  // Private named constructor to prevent direct instantiation.
  DatabaseHelper._internal();

  /// The single, shared instance of [DatabaseHelper].
  static final DatabaseHelper instance = DatabaseHelper._internal();

  /// The underlying [Database] object.
  /// Lazily initialized on first access via [database].
  Database? _database;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Returns the open [Database], initializing it if necessary.
  ///
  /// On Windows, Linux, and macOS the `sqflite_common_ffi` factory is used
  /// so that the native SQLite library can be loaded correctly on desktop.
  /// On mobile (Android / iOS) the standard `sqflite` factory is used.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes and opens the SQLite database.
  ///
  /// Detects the current platform and configures the appropriate database
  /// factory before opening the file.
  Future<Database> _initDatabase() async {
    // Configure sqflite for desktop/web platforms.
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Resolve the platform-specific path to the database file.
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, kDatabaseName);

    return openDatabase(
      path,
      version: kDatabaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      // Enable foreign key enforcement for every connection.
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Schema creation
  // ---------------------------------------------------------------------------

  /// Called when the database is created for the first time.
  ///
  /// Creates all tables and indexes required by Maktaba Ihsan.
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // -------------------------------------------------------------------------
    // Books table
    // Stores the library catalogue. Each row represents a physical book copy.
    // -------------------------------------------------------------------------
    batch.execute('''
      CREATE TABLE $kBooksTable (
        accession_no      TEXT PRIMARY KEY,
        book_name         TEXT NOT NULL,
        volume_no         TEXT,
        subject_category  TEXT,
        author            TEXT,
        translator        TEXT,
        publisher         TEXT,
        address           TEXT,
        shelf_no          TEXT,
        status            TEXT NOT NULL DEFAULT 'Available',
        remarks           TEXT,
        last_updated      TEXT NOT NULL
      );
    ''');

    // -------------------------------------------------------------------------
    // Users table
    // Stores library members: admins, teachers, and students.
    // -------------------------------------------------------------------------
    batch.execute('''
      CREATE TABLE $kUsersTable (
        user_id      TEXT PRIMARY KEY,
        name         TEXT NOT NULL,
        type         TEXT NOT NULL,
        phone        TEXT,
        pin          TEXT,
        class_jamat  TEXT,
        status       TEXT NOT NULL DEFAULT 'Active',
        last_updated TEXT NOT NULL
      );
    ''');

    // -------------------------------------------------------------------------
    // Transactions table
    // Records every book issue / return event.
    // -------------------------------------------------------------------------
    batch.execute('''
      CREATE TABLE $kTransactionsTable (
        trx_id          TEXT PRIMARY KEY,
        accession_no    TEXT NOT NULL,
        user_id         TEXT NOT NULL,
        issue_date      TEXT NOT NULL,
        expected_return TEXT NOT NULL,
        actual_return   TEXT,
        status          TEXT NOT NULL DEFAULT 'Active',
        last_updated    TEXT NOT NULL,
        FOREIGN KEY (accession_no) REFERENCES $kBooksTable (accession_no),
        FOREIGN KEY (user_id)      REFERENCES $kUsersTable (user_id)
      );
    ''');

    // -------------------------------------------------------------------------
    // Indexes — improve query performance on frequently filtered columns.
    // -------------------------------------------------------------------------

    // Book indexes
    batch.execute('CREATE INDEX idx_books_status ON $kBooksTable (status);');
    batch.execute(
        'CREATE INDEX idx_books_category ON $kBooksTable (subject_category);');
    batch.execute('CREATE INDEX idx_books_shelf ON $kBooksTable (shelf_no);');

    // User indexes
    batch.execute('CREATE INDEX idx_users_type ON $kUsersTable (type);');
    batch.execute('CREATE INDEX idx_users_status ON $kUsersTable (status);');

    // Transaction indexes
    batch.execute(
        'CREATE INDEX idx_trx_status ON $kTransactionsTable (status);');
    batch
        .execute('CREATE INDEX idx_trx_user ON $kTransactionsTable (user_id);');
    batch.execute(
        'CREATE INDEX idx_trx_book ON $kTransactionsTable (accession_no);');

    await batch.commit(noResult: true);
  }

  // ---------------------------------------------------------------------------
  // Schema migration
  // ---------------------------------------------------------------------------

  /// Called when the database version is incremented.
  ///
  /// Add `ALTER TABLE` or other DDL statements here for each version bump.
  /// Example:
  /// ```dart
  /// if (oldVersion < 2) {
  ///   await db.execute('ALTER TABLE books ADD COLUMN notes TEXT;');
  /// }
  /// ```
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $kBooksTable ADD COLUMN translator TEXT;');
    }
  }

  // ---------------------------------------------------------------------------
  // Generic CRUD helpers
  // ---------------------------------------------------------------------------

  /// Queries [table] and returns a list of row maps.
  ///
  /// Optional parameters:
  /// - [where]: SQL WHERE clause, e.g. `'status = ?'`
  /// - [whereArgs]: Arguments bound to `?` placeholders in [where].
  /// - [orderBy]: SQL ORDER BY clause, e.g. `'book_name ASC'`
  /// - [limit]: Maximum number of rows to return.
  /// - [offset]: Number of rows to skip before returning results.
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Inserts [data] into [table].
  ///
  /// Uses [ConflictAlgorithm.replace] so that duplicate primary keys result in
  /// an upsert rather than an error.
  ///
  /// Returns the row ID of the inserted row.
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Updates rows in [table] that match [where] / [whereArgs].
  ///
  /// Returns the number of rows affected.
  Future<int> update(
    String table,
    Map<String, dynamic> data,
    String where,
    List<dynamic> whereArgs,
  ) async {
    final db = await database;
    return db.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes rows from [table] that match [where] / [whereArgs].
  ///
  /// Returns the number of rows deleted.
  Future<int> delete(
    String table,
    String where,
    List<dynamic> whereArgs,
  ) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// Executes a raw SQL SELECT statement and returns the result rows.
  ///
  /// Use this for complex JOIN queries or aggregates that cannot be expressed
  /// through the typed [query] helper.
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? args,
  ]) async {
    final db = await database;
    return db.rawQuery(sql, args);
  }

  /// Repairs data inconsistencies between Books and Transactions.
  /// If a transaction is Active, the corresponding book MUST be Lent.
  /// If no Active transaction exists, the book MUST NOT be Lent.
  Future<void> repairBookStatuses() async {
    final db = await database;
    
    // Fix books that should be Lent
    await db.rawUpdate('''
      UPDATE $kBooksTable 
      SET status = 'Lent' 
      WHERE accession_no IN (
        SELECT accession_no FROM $kTransactionsTable WHERE status = 'Active'
      ) AND status != 'Lent'
    ''');

    // Fix books that should be Available (were stuck as Lent)
    await db.rawUpdate('''
      UPDATE $kBooksTable 
      SET status = 'Available' 
      WHERE status = 'Lent' AND accession_no NOT IN (
        SELECT accession_no FROM $kTransactionsTable WHERE status = 'Active'
      )
    ''');
  }

  /// Executes a raw SQL INSERT / UPDATE / DELETE statement.
  ///
  /// Returns the number of rows changed (for INSERT, the last inserted row ID).
  Future<int> rawInsert(String sql, [List<dynamic>? args]) async {
    final db = await database;
    return db.rawInsert(sql, args);
  }

  /// Performs a batch upsert of [rows] into [table].
  ///
  /// Each row in [rows] is inserted using [ConflictAlgorithm.replace].
  /// All inserts are executed inside a single batch for maximum performance,
  /// avoiding the overhead of individual round-trips.
  ///
  /// [primaryKey] is accepted as a parameter for documentation clarity but
  /// the actual conflict resolution is handled by `REPLACE` semantics on the
  /// table's declared PRIMARY KEY.
  Future<void> batchUpsert(
    String table,
    List<Map<String, dynamic>> rows,
    String primaryKey,
  ) async {
    if (rows.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final row in rows) {
      batch.insert(
        table,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Closes the database connection and releases resources.
  ///
  /// After calling this method [_database] is set to null so that subsequent
  /// calls to [database] will re-open the file.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
