/// book_model.dart
///
/// Immutable domain model representing a single book copy in the Maktaba Ihsan
/// catalogue, together with its current status in the library system.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// BookStatus enum
// ---------------------------------------------------------------------------

/// Represents the availability state of a library book copy.
enum BookStatus {
  /// The book is on the shelf and available for borrowing.
  available,

  /// The book has been issued to a user and is currently on loan.
  lent,

  /// The book has been reported as permanently lost.
  lost,

  /// The book is physically present but in a damaged / unusable condition.
  damaged,

  /// The book may only be read within the library and cannot be borrowed.
  referenceOnly,
}

/// Extension on [BookStatus] that handles conversion to and from the string
/// values stored in the SQLite `books.status` column.
extension BookStatusX on BookStatus {
  /// Converts this [BookStatus] to the canonical database string.
  String toDbString() {
    switch (this) {
      case BookStatus.available:
        return 'Available';
      case BookStatus.lent:
        return 'Lent';
      case BookStatus.lost:
        return 'Lost';
      case BookStatus.damaged:
        return 'Damaged';
      case BookStatus.referenceOnly:
        return 'Reference Only';
    }
  }

  /// Returns a human-readable label suitable for display in the UI.
  String get displayLabel => toDbString();
}

/// Parses a raw [value] string (from the database or API) into a [BookStatus].
///
/// Falls back to [BookStatus.available] when the value is unrecognised.
BookStatus bookStatusFromString(String? value) {
  switch ((value ?? '').toLowerCase().trim()) {
    case 'lent':
      return BookStatus.lent;
    case 'lost':
      return BookStatus.lost;
    case 'damaged':
      return BookStatus.damaged;
    case 'reference only':
      return BookStatus.referenceOnly;
    case 'available':
    default:
      return BookStatus.available;
  }
}

// ---------------------------------------------------------------------------
// Numeral Conversion
// ---------------------------------------------------------------------------

extension NumeralConversion on String {
  String get toEnglishNumerals {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    
    String result = this;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(arabic[i], english[i])
                     .replaceAll(bengali[i], english[i]);
    }
    return result;
  }
}

// ---------------------------------------------------------------------------
// Book model
// ---------------------------------------------------------------------------

/// An immutable value object representing a single book copy.
///
/// Field names use camelCase Dart conventions; [fromMap] / [toMap] handle the
/// snake_case column names used in the SQLite schema.
///
/// Equality is determined by [Equatable] using all declared fields, which
/// makes it safe to compare books and use them as map keys.
@immutable
class Book extends Equatable {
  /// Creates a [Book] with all required and optional fields.
  const Book({
    required this.accessionNo,
    required this.bookName,
    required this.lastUpdated,
    required this.status,
    this.volumeNo,
    this.subjectCategory,
    this.author,
    this.translator,
    this.publisher,
    this.address,
    this.shelfNo,
    this.remarks,
  });

  // ---------------------------------------------------------------------------
  // Fields — mirror the `books` table schema exactly.
  // ---------------------------------------------------------------------------

  /// Unique accession number assigned to this book copy by the library.
  /// Maps to the `accession_no` PRIMARY KEY column.
  final String accessionNo;

  /// Full title of the book.
  final String bookName;

  /// Volume number for multi-volume works (nullable).
  final String? volumeNo;

  /// Subject or discipline category used for catalogue classification.
  final String? subjectCategory;

  /// Name of the author(s).
  final String? author;

  /// Name of the translator or editor.
  final String? translator;

  /// Name of the publishing house.
  final String? publisher;

  /// Place of publication.
  final String? address;

  /// Physical shelf location within the library.
  final String? shelfNo;

  /// Current availability status of this book copy.
  final BookStatus status;

  /// Free-text remarks or notes about this copy (e.g., condition notes).
  final String? remarks;

  /// Timestamp of the last modification to this record.
  final DateTime lastUpdated;

  // ---------------------------------------------------------------------------
  // Factory constructors
  // ---------------------------------------------------------------------------

  /// Creates a [Book] from a [Map] row returned by sqflite.
  ///
  /// Column names are expected to follow the `snake_case` database schema.
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      accessionNo: map['accession_no'] as String,
      bookName: map['book_name'] as String,
      volumeNo: map['volume_no'] as String?,
      subjectCategory: map['subject_category'] as String?,
      author: map['author'] as String?,
      translator: map['translator'] as String?,
      publisher: map['publisher'] as String?,
      address: map['address'] as String?,
      shelfNo: map['shelf_no'] as String?,
      status: bookStatusFromString(map['status'] as String?),
      remarks: map['remarks'] as String?,
      lastUpdated: DateTime.tryParse(map['last_updated'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Creates a [Book] from a JSON [Map] received from the Google Apps Script
  /// API sync endpoint.
  ///
  /// The key names are expected to match those used in [toJson].
  factory Book.fromJson(Map<String, dynamic> json) => Book.fromMap(json);

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Converts this [Book] to a [Map] suitable for insertion into sqflite.
  ///
  /// All keys use `snake_case` to match the database column names.
  Map<String, dynamic> toMap() {
    return {
      'accession_no': accessionNo,
      'book_name': bookName,
      'volume_no': volumeNo,
      'subject_category': subjectCategory,
      'author': author,
      'translator': translator,
      'publisher': publisher,
      'address': address,
      'shelf_no': shelfNo,
      'status': status.toDbString(),
      'remarks': remarks,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  /// Converts this [Book] to a JSON-serializable [Map] for API sync.
  ///
  /// Mirrors [toMap] — the GAS endpoint consumes the same column names.
  Map<String, dynamic> toJson() => toMap();

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  /// Returns a copy of this [Book] with the specified fields replaced.
  ///
  /// Fields that are not provided retain their current values.
  Book copyWith({
    String? accessionNo,
    String? bookName,
    String? volumeNo,
    String? subjectCategory,
    String? author,
    String? translator,
    String? publisher,
    String? address,
    String? shelfNo,
    BookStatus? status,
    String? remarks,
    DateTime? lastUpdated,
  }) {
    return Book(
      accessionNo: accessionNo ?? this.accessionNo,
      bookName: bookName ?? this.bookName,
      volumeNo: volumeNo ?? this.volumeNo,
      subjectCategory: subjectCategory ?? this.subjectCategory,
      author: author ?? this.author,
      translator: translator ?? this.translator,
      publisher: publisher ?? this.publisher,
      address: address ?? this.address,
      shelfNo: shelfNo ?? this.shelfNo,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // ---------------------------------------------------------------------------
  // Equatable
  // ---------------------------------------------------------------------------

  @override
  List<Object?> get props => [
        accessionNo,
        bookName,
        volumeNo,
        subjectCategory,
        author,
        translator,
        publisher,
        address,
        shelfNo,
        status,
        remarks,
        lastUpdated,
      ];

  @override
  String toString() =>
      'Book(accessionNo: $accessionNo, bookName: $bookName, status: $status)';
}
