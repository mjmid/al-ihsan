/// ---------------------------------------------------------------------------
/// transaction_repository.dart
/// ---------------------------------------------------------------------------
/// Repository for book issue / return transactions.
///
/// Key design decisions:
///
///   1. **Atomicity** — every operation that touches two tables (transactions
///      + books) is wrapped in a sqflite `db.transaction(...)` block.  If
///      either update fails, the whole operation rolls back automatically.
///
///   2. **Offline-first** — successful local writes immediately enqueue a
///      remote sync operation via [SyncQueueNotifier].
///
///   3. **Overdue detection** — `getOverdueTransactions` uses a pure SQLite
///      date comparison (`expected_return < CURRENT_DATE`) so it works
///      correctly even without an internet connection.
/// ---------------------------------------------------------------------------

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/book_model.dart';
import '../models/transaction_model.dart';
import '../services/sync_queue_service.dart';

/// Repository for all Transaction-related local database operations.
class TransactionRepository {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  final DatabaseHelper _db;
  final SyncQueueNotifier _syncQueue;

  const TransactionRepository({
    required DatabaseHelper db,
    required SyncQueueNotifier syncQueue,
  })  : _db = db,
        _syncQueue = syncQueue;

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Issues [accessionNo] to [userId] with a due date of [expectedReturn].
  ///
  /// Atomically:
  ///   1. Verifies the book exists and is `'Available'`.
  ///   2. Creates a new transaction row with `status = 'Active'`.
  ///   3. Updates the book's `status` to `'Lent'` and decrements
  ///      `available_copies` by 1.
  ///
  /// Returns the newly created [LibraryTransaction], or `null` if the book is
  /// not found or already lent out.
  Future<LibraryTransaction?> issueBook(
    String accessionNo,
    String userId,
    DateTime expectedReturn,
  ) async {
    final db = await _db.database;

    return db.transaction<LibraryTransaction?>((txn) async {
      // 1. Check the book is available.
      final bookRows = await txn.query(
        kBooksTable,
        where: 'accession_no = ? AND status = ?',
        whereArgs: [accessionNo, BookStatus.available.toDbString()],
        limit: 1,
      );

      if (bookRows.isEmpty) {
        // Book not found or not available — caller should check null return.
        return null;
      }

      final now = DateTime.now().toUtc();
      final nowStr = now.toIso8601String();
      final trxId = const Uuid().v4();

      // 2. Insert the transaction.
      final transaction = LibraryTransaction(
        trxId: trxId,
        accessionNo: accessionNo,
        userId: userId,
        issueDate: now,
        expectedReturn: expectedReturn,
        actualReturn: null,
        status: TransactionStatus.active,
        lastUpdated: now,
      );

      await txn.insert(
        kTransactionsTable,
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 3. Update book status to Lent.
      await txn.update(
        kBooksTable,
        {'status': BookStatus.lent.toDbString(), 'last_updated': nowStr},
        where: 'accession_no = ?',
        whereArgs: [accessionNo],
      );

      // 4. Enqueue remote syncs (both tables).
      _syncQueue.enqueue(
        SyncOperation.create(
          sheet: 'Transactions',
          action: 'upsert',
          payload: transaction.toMap(),
        ),
      );
      _syncQueue.enqueue(
        SyncOperation.create(
          sheet: 'Books',
          action: 'upsert',
          payload: {
            'Accession_No': accessionNo,
            'Status': BookStatus.lent.toDbString(),
            'Updated_At': nowStr,
          },
        ),
      );

      return transaction;
    });
  }

  /// Inserts a generic transaction (e.g. requested status) directly into the DB.
  Future<void> insertTransaction(LibraryTransaction tx) async {
    final db = await _db.database;
    await db.insert(kTransactionsTable, tx.toMap());

    // Sync to backend
    _syncQueue.enqueue(
      SyncOperation.create(
        sheet: 'Transactions',
        action: 'upsert',
        payload: tx.toMap(),
      ),
    );
  }

  /// Approves a requested transaction by changing it to active
  Future<LibraryTransaction?> approveRequest(
      String trxId, DateTime issueDate, DateTime expectedReturn) async {
    final db = await _db.database;

    return db.transaction<LibraryTransaction?>((txn) async {
      final txRows = await txn.query(
        kTransactionsTable,
        where: 'trx_id = ? AND status = ?',
        whereArgs: [trxId, TransactionStatus.requested.toDbString()],
      );

      if (txRows.isEmpty) return null;
      final txRow = txRows.first;
      final accessionNo = txRow['accession_no'] as String;

      final nowStr = DateTime.now().toIso8601String();
      await txn.update(
        kTransactionsTable,
        {
          'status': TransactionStatus.active.toDbString(),
          'issue_date': issueDate.toIso8601String(),
          'expected_return': expectedReturn.toIso8601String(),
          'last_updated': nowStr,
        },
        where: 'trx_id = ?',
        whereArgs: [trxId],
      );

      await txn.update(
        kBooksTable,
        {'status': BookStatus.lent.toDbString(), 'last_updated': nowStr},
        where: 'accession_no = ?',
        whereArgs: [accessionNo],
      );

      final updatedTxRows = await txn.query(
        kTransactionsTable,
        where: 'trx_id = ?',
        whereArgs: [trxId],
      );
      final updatedTx = LibraryTransaction.fromMap(updatedTxRows.first);

      _syncQueue.enqueue(
        SyncOperation.create(
          sheet: 'Transactions',
          action: 'upsert',
          payload: updatedTx.toMap(),
        ),
      );
      _syncQueue.enqueue(
        SyncOperation.create(
          sheet: 'Books',
          action: 'upsert',
          payload: {
            'Accession_No': accessionNo,
            'Status': BookStatus.lent.toDbString(),
            'Updated_At': nowStr,
          },
        ),
      );

      return updatedTx;
    });
  }

  /// Records the return of the book associated with transaction [trxId].
  ///
  /// Atomically:
  ///   1. Finds the active transaction.
  ///   2. Sets `actual_return` to now and `status` to `'Returned'`.
  ///   3. Updates the book's `status` to `'Available'` and increments
  ///      `available_copies` by 1.
  ///
  /// Returns the updated [LibraryTransaction], or `null` if the transaction
  /// does not exist or is already closed.
  Future<LibraryTransaction?> returnBook(String trxId) async {
    final db = await _db.database;

    return db.transaction<LibraryTransaction?>((txn) async {
      // 1. Fetch the active transaction.
      final rows = await txn.query(
        kTransactionsTable,
        where: 'trx_id = ? AND status = ?',
        whereArgs: [trxId, TransactionStatus.active.toDbString()],
        limit: 1,
      );

      if (rows.isEmpty) return null;

      final existing = LibraryTransaction.fromMap(rows.first);
      final now = DateTime.now().toUtc();
      final nowStr = now.toIso8601String();

      // 2. Update the transaction.
      final updated = existing.copyWith(
        actualReturn: now,
        status: TransactionStatus.returned,
      );

      await txn.update(
        kTransactionsTable,
        updated.toMap(),
        where: 'trx_id = ?',
        whereArgs: [trxId],
      );

      // 3. Update the book back to Available.
      await txn.update(
        kBooksTable,
        {'status': BookStatus.available.toDbString(), 'last_updated': nowStr},
        where: 'accession_no = ?',
        whereArgs: [existing.accessionNo],
      );

      // 4. Enqueue remote syncs.
      _syncQueue.enqueue(
        SyncOperation.create(
          sheet: 'Transactions',
          action: 'upsert',
          payload: updated.toMap(),
        ),
      );
      _syncQueue.enqueue(
        SyncOperation.create(
          sheet: 'Books',
          action: 'upsert',
          payload: {
            'Accession_No': existing.accessionNo,
            'Status': BookStatus.available.toDbString(),
            'Updated_At': nowStr,
          },
        ),
      );

      return updated;
    });
  }

  /// Deletes a transaction completely.
  /// Typically used by Admins to reject/delete a request.
  Future<void> deleteTransaction(String trxId) async {
    final db = await _db.database;

    await db.delete(
      kTransactionsTable,
      where: 'trx_id = ?',
      whereArgs: [trxId],
    );

    // Enqueue remote sync (assumes GAS script handles action: 'delete')
    _syncQueue.enqueue(
      SyncOperation.create(
        sheet: 'Transactions',
        action: 'delete',
        payload: {'trx_id': trxId},
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// Returns all currently active (unreturned) transactions.
  ///
  /// If [userId] is provided, results are scoped to that borrower.
  Future<List<LibraryTransaction>> getActiveTransactions(
      {String? userId}) async {
    final db = await _db.database;

    final where =
        userId != null ? 't.status = ? AND t.user_id = ?' : 't.status = ?';
    final args = userId != null
        ? [TransactionStatus.active.toDbString(), userId]
        : [TransactionStatus.active.toDbString()];

    final rows = await db.rawQuery('''
      SELECT t.*, b.book_name, u.name as user_name 
      FROM $kTransactionsTable t
      LEFT JOIN $kBooksTable b ON t.accession_no = b.accession_no
      LEFT JOIN $kUsersTable u ON t.user_id = u.user_id
      WHERE $where
      ORDER BY t.expected_return ASC
    ''', args);

    return rows.map(LibraryTransaction.fromMap).toList();
  }

  /// Returns all transactions whose `expected_return` is in the past and
  /// whose `status` is still `'Active'` (not yet returned).
  ///
  /// SQLite's `date()` function compares ISO-8601 date strings lexicographically,
  /// which is numerically correct for ISO-8601 format.
  Future<List<LibraryTransaction>> getOverdueTransactions() async {
    final db = await _db.database;

    final rows = await db.rawQuery('''
      SELECT t.*, b.book_name, u.name as user_name 
      FROM $kTransactionsTable t
      LEFT JOIN $kBooksTable b ON t.accession_no = b.accession_no
      LEFT JOIN $kUsersTable u ON t.user_id = u.user_id
      WHERE t.status = ? AND date(t.expected_return) < date('now')
      ORDER BY t.expected_return ASC
    ''', [TransactionStatus.active.toDbString()]);

    return rows.map(LibraryTransaction.fromMap).toList();
  }

  /// Returns the full transaction history with optional filters.
  ///
  /// [userId]      — scope to a single borrower's history
  /// [accessionNo] — scope to a single book's history
  /// [limit]       — cap results for paginated list views
  Future<List<LibraryTransaction>> getTransactionHistory({
    String? userId,
    String? accessionNo,
    int? limit,
  }) async {
    final db = await _db.database;

    final conditions = <String>[];
    final args = <dynamic>[];

    if (userId != null) {
      conditions.add('t.user_id = ?');
      args.add(userId);
    }
    if (accessionNo != null) {
      conditions.add('t.accession_no = ?');
      args.add(accessionNo);
    }

    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final limitClause = limit != null ? 'LIMIT $limit' : '';

    final rows = await db.rawQuery('''
      SELECT t.*, b.book_name, u.name as user_name 
      FROM $kTransactionsTable t
      LEFT JOIN $kBooksTable b ON t.accession_no = b.accession_no
      LEFT JOIN $kUsersTable u ON t.user_id = u.user_id
      $where
      ORDER BY t.issue_date DESC
      $limitClause
    ''', args.isEmpty ? null : args);

    return rows.map(LibraryTransaction.fromMap).toList();
  }

  /// Returns the currently active transaction for the book identified by
  /// [accessionNo], or `null` if the book is not currently lent out.
  ///
  /// Use this to find out *who* currently has a particular book.
  Future<LibraryTransaction?> getActiveTransactionForBook(
    String accessionNo,
  ) async {
    final db = await _db.database;

    final rows = await db.query(
      kTransactionsTable,
      where: 'accession_no = ? AND status = ?',
      whereArgs: [accessionNo, TransactionStatus.active.toDbString()],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return LibraryTransaction.fromMap(rows.first);
  }

  /// Returns a summary map of transaction counts for the dashboard.
  ///
  /// Keys: `'active'`, `'returned'`, `'overdue'`
  ///
  /// `'overdue'` is a subset of `'active'` (active + past due date).
  Future<Map<String, int>> getTransactionStats() async {
    final db = await _db.database;

    // Active (all unreturned).
    final activeResult = await db.rawQuery(
      "SELECT COUNT(*) AS count FROM $kTransactionsTable WHERE status = ?",
      [TransactionStatus.active.toDbString()],
    );

    // Returned.
    final returnedResult = await db.rawQuery(
      "SELECT COUNT(*) AS count FROM $kTransactionsTable WHERE status = ?",
      [TransactionStatus.returned.toDbString()],
    );

    // Overdue (active AND past due date).
    final overdueResult = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM   $kTransactionsTable
      WHERE  status = ?
        AND  date(expected_return) < date('now')
      ''',
      [TransactionStatus.active.toDbString()],
    );

    return {
      'active': (activeResult.first['count'] as int?) ?? 0,
      'returned': (returnedResult.first['count'] as int?) ?? 0,
      'overdue': (overdueResult.first['count'] as int?) ?? 0,
    };
  }
}
