/// ---------------------------------------------------------------------------
/// book_repository.dart
/// ---------------------------------------------------------------------------
/// Repository that abstracts all local SQLite read/write operations for the
/// Books catalogue, and enqueues remote sync operations after every write.
///
/// All SQL queries are parameterised (never concatenated) to prevent SQL
/// injection, even though the current inputs come from trusted UI controls.
///
/// Dependencies:
///   • [DatabaseHelper] — sqflite wrapper
///   • [SyncQueueNotifier] — offline sync queue
/// ---------------------------------------------------------------------------
library;

import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/book_model.dart';
import '../services/sync_queue_service.dart';

/// Repository for all Book-related database operations.
///
/// Inject via a Riverpod provider so that [DatabaseHelper] and
/// [SyncQueueNotifier] are shared singletons.
class BookRepository {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  final DatabaseHelper _db;
  final SyncQueueNotifier _syncQueue;

  const BookRepository({
    required DatabaseHelper db,
    required SyncQueueNotifier syncQueue,
  })  : _db = db,
        _syncQueue = syncQueue;

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  String _normalizeNumbers(String input) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    String result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(arabic[i], english[i]);
      result = result.replaceAll(bengali[i], english[i]);
    }
    return result;
  }

  /// Full-text search across the most useful book fields.
  ///
  /// Matches [query] (case-insensitive on most SQLite builds) against:
  ///   • `book_name`
  ///   • `author`
  ///   • `accession_no` (exact match only for numbers)
  ///   • `subject_category`
  ///
  /// Results are ordered by `book_name` ascending.
  Future<List<Book>> searchBooks(String query) async {
    final db = await _db.database;
    final normalizedQuery = _normalizeNumbers(query.trim());
    final pattern = '%$normalizedQuery%';

    final rows = await db.query(
      kBooksTable,
      where: '''
        book_name        LIKE ? OR
        author           LIKE ? OR
        accession_no     = ? OR
        subject_category LIKE ?
      ''',
      whereArgs: [pattern, pattern, normalizedQuery, pattern],
      orderBy: "book_name = '' ASC, book_name ASC",
    );

    return rows.map(Book.fromMap).toList();
  }

  /// Returns all books with optional pagination.
  ///
  /// Pass [limit] and [offset] to page through large catalogues without
  /// loading every row into memory at once.
  Future<List<Book>> getAllBooks({int? limit, int? offset}) async {
    final db = await _db.database;

    final rows = await db.query(
      kBooksTable,
      orderBy: "book_name = '' ASC, book_name ASC",
      limit: limit,
      offset: offset,
    );

    return rows.map(Book.fromMap).toList();
  }

  /// Fetches the book identified by [accessionNo], or `null` if not found.
  Future<Book?> getBookByAccessionNo(String accessionNo) async {
    final db = await _db.database;

    final rows = await db.query(
      kBooksTable,
      where: 'accession_no = ?',
      whereArgs: [accessionNo],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return Book.fromMap(rows.first);
  }

  /// Returns all books whose `status` column matches [status].
  ///
  /// Useful for showing "Available", "Lent", or "Archived" sub-lists.
  Future<List<Book>> getBooksByStatus(BookStatus status) async {
    final db = await _db.database;

    final rows = await db.query(
      kBooksTable,
      where: 'status = ?',
      whereArgs: [status.name],
      orderBy: 'book_name ASC',
    );

    return rows.map(Book.fromMap).toList();
  }

  /// Returns all books belonging to [category].
  Future<List<Book>> getBooksByCategory(String category) async {
    final db = await _db.database;

    final rows = await db.query(
      kBooksTable,
      where: 'subject_category = ?',
      whereArgs: [category],
      orderBy: 'book_name ASC',
    );

    return rows.map(Book.fromMap).toList();
  }

  /// Returns all books located on shelf [shelfNo].
  Future<List<Book>> getBooksByShelf(String shelfNo) async {
    final db = await _db.database;

    final rows = await db.query(
      kBooksTable,
      where: 'shelf_no = ?',
      whereArgs: [shelfNo],
      orderBy: 'accession_no ASC',
    );

    return rows.map(Book.fromMap).toList();
  }

  /// Returns the total number of book records in the local database.
  Future<int> getTotalBooksCount() async {
    final db = await _db.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM $kBooksTable',
    );

    return (result.first['count'] as int?) ?? 0;
  }

  /// Returns a map of `{ statusName: count }` for dashboard summary cards.
  ///
  /// Example result:
  /// ```dart
  /// {'Available': 142, 'Lent': 23, 'Archived': 5}
  /// ```
  Future<Map<String, int>> getBookStatusCounts() async {
    final db = await _db.database;

    final rows = await db.rawQuery(
      'SELECT status, COUNT(*) AS count FROM $kBooksTable GROUP BY status',
    );

    return {
      for (final row in rows)
        (row['status'] as String? ?? 'Unknown'): (row['count'] as int? ?? 0),
    };
  }

  /// Returns a sorted, deduplicated list of all subject categories present
  /// in the local database.  Used to populate filter chips.
  Future<List<String>> getAllCategories() async {
    final db = await _db.database;

    final rows = await db.rawQuery(
      '''
      SELECT DISTINCT TRIM(subject_category) AS subject_category
      FROM   $kBooksTable
      WHERE  subject_category IS NOT NULL AND TRIM(subject_category) != ''
      ORDER  BY subject_category ASC
      ''',
    );

    return rows
        .map((r) => (r['subject_category'] as String).trim())
        .where((c) => c.isNotEmpty)
        .toList();
  }

  /// Returns a sorted, deduplicated list of all shelf numbers.
  /// Used to populate the shelf-filter chip row.
  Future<List<String>> getAllShelves() async {
    final db = await _db.database;

    final rows = await db.rawQuery(
      '''
      SELECT DISTINCT TRIM(shelf_no) AS shelf_no
      FROM   $kBooksTable
      WHERE  shelf_no IS NOT NULL AND TRIM(shelf_no) != ''
      ORDER  BY shelf_no ASC
      ''',
    );

    return rows
        .map((r) => (r['shelf_no'] as String).trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Returns a sorted, deduplicated list of all authors.
  Future<List<String>> getAllAuthors() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT TRIM(author) AS author
      FROM   $kBooksTable
      WHERE  author IS NOT NULL AND TRIM(author) != ''
      ORDER  BY author ASC
    ''');
    return rows
        .map((r) => (r['author'] as String).trim())
        .where((a) => a.isNotEmpty)
        .toList();
  }

  /// Returns a map of author to book count, ordered by highest count.
  Future<Map<String, int>> getAuthorCounts() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT TRIM(author) AS author, COUNT(*) AS count
      FROM   $kBooksTable
      WHERE  author IS NOT NULL AND TRIM(author) != ''
      GROUP  BY TRIM(author)
      ORDER  BY count DESC, author ASC
    ''');
    return {
      for (final r in rows)
        (r['author'] as String): (r['count'] as int? ?? 0)
    };
  }

  /// Returns a sorted, deduplicated list of all publishers.
  Future<List<String>> getAllPublishers() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT TRIM(publisher) AS publisher
      FROM   $kBooksTable
      WHERE  publisher IS NOT NULL AND TRIM(publisher) != ''
      ORDER  BY publisher ASC
    ''');
    return rows
        .map((r) => (r['publisher'] as String).trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  /// Returns a map of publisher to book count, ordered by highest count.
  Future<Map<String, int>> getPublisherCounts() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT TRIM(publisher) AS publisher, COUNT(*) AS count
      FROM   $kBooksTable
      WHERE  publisher IS NOT NULL AND TRIM(publisher) != ''
      GROUP  BY TRIM(publisher)
      ORDER  BY count DESC, publisher ASC
    ''');
    return {
      for (final r in rows)
        (r['publisher'] as String): (r['count'] as int? ?? 0)
    };
  }

  /// Returns a map of category to book count, ordered by highest count.
  Future<Map<String, int>> getCategoryCounts() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT TRIM(subject_category) AS subject_category, COUNT(*) AS count
      FROM   $kBooksTable
      WHERE  subject_category IS NOT NULL AND TRIM(subject_category) != ''
      GROUP  BY TRIM(subject_category)
      ORDER  BY count DESC, subject_category ASC
    ''');
    return {
      for (final r in rows)
        (r['subject_category'] as String): (r['count'] as int? ?? 0)
    };
  }

  /// Returns a map of shelf to book count, ordered by shelf name.
  Future<Map<String, int>> getShelfCounts() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT TRIM(shelf_no) AS shelf_no, COUNT(*) AS count
      FROM   $kBooksTable
      WHERE  shelf_no IS NOT NULL AND TRIM(shelf_no) != ''
      GROUP  BY TRIM(shelf_no)
      ORDER  BY shelf_no ASC
    ''');
    return {
      for (final r in rows)
        (r['shelf_no'] as String): (r['count'] as int? ?? 0)
    };
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Inserts or replaces [book] in the local database, then enqueues a remote
  /// `upsert` operation so the change is replicated to GAS when online.
  Future<void> upsertBook(Book book) async {
    final db = await _db.database;

    // Use INSERT OR REPLACE (SQLite conflict resolution) so callers don't need
    // to distinguish between insert and update paths.
    await db.insert(
      kBooksTable,
      book.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Enqueue for remote sync — this is a fire-and-forget from the
    // repository's perspective; [SyncQueueNotifier] handles retry logic.
    _syncQueue.enqueue(
      SyncOperation.create(
        sheet: 'Books',
        action: 'upsert',
        payload: book.toMap(),
      ),
    );
  }

  /// Changes the `status` column for the book identified by [accessionNo]
  /// and enqueues the corresponding remote sync.
  ///
  /// Also bumps `updated_at` to the current UTC time so delta-sync watermarks
  /// correctly pick up the change.
  Future<void> updateBookStatus(
    String accessionNo,
    BookStatus status,
  ) async {
    final db = await _db.database;
    final now = DateTime.now().toUtc().toIso8601String();

    await db.update(
      kBooksTable,
      {'status': status.name, 'updated_at': now},
      where: 'accession_no = ?',
      whereArgs: [accessionNo],
    );

    _syncQueue.enqueue(
      SyncOperation.create(
        sheet: 'Books',
        action: 'upsert',
        payload: {
          'Accession_No': accessionNo,
          'Status': status.name,
          'Updated_At': now,
        },
      ),
    );
  }
}
