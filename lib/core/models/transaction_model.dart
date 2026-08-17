/// transaction_model.dart
///
/// Immutable domain model representing a single book issue/return event in the
/// Maktaba Ihsan library management system.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// TransactionStatus enum
// ---------------------------------------------------------------------------

/// Describes the current state of a library lending transaction.
enum TransactionStatus {
  /// The book has been issued and has not yet been returned; the due date
  /// has not passed.
  active,

  /// The book has been returned and the transaction is closed.
  returned,

  /// The book is still outstanding and the expected return date has passed.
  overdue,

  /// The book has been requested by a teacher but not yet approved/issued.
  requested,
}

/// Extension on [TransactionStatus] for database string conversion.
extension TransactionStatusX on TransactionStatus {
  /// Converts this [TransactionStatus] to its canonical database string.
  String toDbString() {
    switch (this) {
      case TransactionStatus.active:
        return 'Active';
      case TransactionStatus.returned:
        return 'Returned';
      case TransactionStatus.overdue:
        return 'Overdue';
      case TransactionStatus.requested:
        return 'Requested';
    }
  }

  /// Returns a human-readable label for display in the UI.
  String get displayLabel => toDbString();
}

/// Parses a raw [value] string into a [TransactionStatus].
///
/// Falls back to [TransactionStatus.active] when the value is unrecognised.
TransactionStatus transactionStatusFromString(String? value) {
  switch ((value ?? '').toLowerCase().trim()) {
    case 'returned':
      return TransactionStatus.returned;
    case 'overdue':
      return TransactionStatus.overdue;
    case 'requested':
      return TransactionStatus.requested;
    case 'active':
    default:
      return TransactionStatus.active;
  }
}

// ---------------------------------------------------------------------------
// Transaction model
// ---------------------------------------------------------------------------

/// An immutable value object representing one library lending transaction.
///
/// A transaction is created when a book is issued and updated when it is
/// returned or when its status changes to overdue.
@immutable
class LibraryTransaction extends Equatable {
  /// Creates a [LibraryTransaction] with all required and optional fields.
  const LibraryTransaction({
    required this.trxId,
    required this.accessionNo,
    required this.userId,
    required this.issueDate,
    required this.expectedReturn,
    required this.status,
    required this.lastUpdated,
    this.actualReturn,
    this.bookName,
    this.userName,
  });

  // ---------------------------------------------------------------------------
  // Fields — mirror the `transactions` table schema exactly.
  // ---------------------------------------------------------------------------

  /// Unique transaction identifier (UUID).
  final String trxId;

  /// Accession number of the book involved in this transaction.
  /// References `books.accession_no`.
  final String accessionNo;

  /// Identifier of the user who borrowed the book.
  /// References `users.user_id`.
  final String userId;

  /// Date and time when the book was issued.
  final DateTime issueDate;

  /// Date and time by which the book must be returned.
  final DateTime expectedReturn;

  /// Date and time when the book was actually returned.
  /// `null` while the book is still on loan.
  final DateTime? actualReturn;

  /// Current status of this transaction.
  final TransactionStatus status;

  /// Timestamp of the last modification to this record.
  final DateTime lastUpdated;

  /// Optional book name (populated via JOIN queries).
  final String? bookName;

  /// Optional user name (populated via JOIN queries).
  final String? userName;

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------

  /// Returns `true` when the transaction is still [TransactionStatus.active]
  /// and the current date-time is past [expectedReturn].
  ///
  /// This is a client-side convenience check. The authoritative overdue state
  /// is stored in the [status] field and should be reconciled periodically by
  /// a background job.
  bool get isOverdue =>
      status == TransactionStatus.active &&
      DateTime.now().isAfter(expectedReturn);

  /// Returns the number of days the book is overdue, or `0` if not overdue.
  int get overdueDays {
    if (!isOverdue) return 0;
    return DateTime.now().difference(expectedReturn).inDays;
  }

  // ---------------------------------------------------------------------------
  // Factory constructors
  // ---------------------------------------------------------------------------

  /// Creates a [LibraryTransaction] from a [Map] row returned by sqflite.
  ///
  /// Column names are expected to follow the `snake_case` database schema.
  factory LibraryTransaction.fromMap(Map<String, dynamic> map) {
    return LibraryTransaction(
      trxId: map['trx_id'] as String,
      accessionNo: map['accession_no'] as String,
      userId: map['user_id'] as String,
      issueDate: DateTime.tryParse(map['issue_date'] as String? ?? '') ??
          DateTime.now(),
      expectedReturn:
          DateTime.tryParse(map['expected_return'] as String? ?? '') ??
              DateTime.now(),
      actualReturn: (map['actual_return'] != null &&
              (map['actual_return'] as String).isNotEmpty)
          ? DateTime.tryParse(map['actual_return'] as String)
          : null,
      status: transactionStatusFromString(map['status'] as String?),
      lastUpdated: DateTime.tryParse(map['last_updated'] as String? ?? '') ??
          DateTime.now(),
      bookName: map['book_name'] as String?,
      userName: map['user_name'] as String?,
    );
  }

  /// Creates a [LibraryTransaction] from a JSON [Map] received from the
  /// Google Apps Script API sync endpoint.
  factory LibraryTransaction.fromJson(Map<String, dynamic> json) =>
      LibraryTransaction.fromMap(json);

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Converts this [LibraryTransaction] to a [Map] suitable for sqflite.
  ///
  /// All keys use `snake_case` to match the database column names.
  /// [DateTime] values are encoded as ISO 8601 strings.
  Map<String, dynamic> toMap() {
    return {
      'trx_id': trxId,
      'accession_no': accessionNo,
      'user_id': userId,
      'issue_date': issueDate.toIso8601String(),
      'expected_return': expectedReturn.toIso8601String(),
      'actual_return': actualReturn?.toIso8601String(),
      'status': status.toDbString(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  /// Converts this [LibraryTransaction] to a JSON-serializable [Map] for API
  /// sync.
  Map<String, dynamic> toJson() => toMap();

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  /// Returns a copy of this [LibraryTransaction] with specified fields replaced.
  LibraryTransaction copyWith({
    String? trxId,
    String? accessionNo,
    String? userId,
    DateTime? issueDate,
    DateTime? expectedReturn,
    DateTime? actualReturn,
    TransactionStatus? status,
    DateTime? lastUpdated,
    String? bookName,
    String? userName,
  }) {
    return LibraryTransaction(
      trxId: trxId ?? this.trxId,
      accessionNo: accessionNo ?? this.accessionNo,
      userId: userId ?? this.userId,
      issueDate: issueDate ?? this.issueDate,
      expectedReturn: expectedReturn ?? this.expectedReturn,
      actualReturn: actualReturn ?? this.actualReturn,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      bookName: bookName ?? this.bookName,
      userName: userName ?? this.userName,
    );
  }

  // ---------------------------------------------------------------------------
  // Equatable
  // ---------------------------------------------------------------------------

  @override
  List<Object?> get props => [
        trxId,
        accessionNo,
        userId,
        issueDate,
        expectedReturn,
        actualReturn,
        status,
        lastUpdated,
      ];

  @override
  String toString() => 'LibraryTransaction('
      'trxId: $trxId, '
      'accessionNo: $accessionNo, '
      'userId: $userId, '
      'status: $status)';
}
