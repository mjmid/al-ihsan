import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import '../constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/book_model.dart';

/// Represents a validation error on a specific row of the imported CSV.
class CsvRowError {
  final int rowNumber;
  final String rawContent;
  final String reason;

  const CsvRowError({
    required this.rowNumber,
    required this.rawContent,
    required this.reason,
  });

  @override
  String toString() => 'Row $rowNumber: $reason';
}

/// Holds the parsed analysis result of an uploaded CSV file.
class CsvImportPreviewResult {
  /// All books that passed validation and are ready to be imported.
  final List<Book> validBooks;

  /// Books that will be newly added (accession_no not currently in the database).
  final List<Book> newBooks;

  /// Books whose accession_no already exists and will be updated.
  final List<Book> updateBooks;

  /// Rows that failed validation or had missing required fields.
  final List<CsvRowError> errors;

  /// Detected column headers from the CSV.
  final List<String> detectedHeaders;

  /// Total data rows processed (excluding header row).
  final int totalDataRows;

  const CsvImportPreviewResult({
    required this.validBooks,
    required this.newBooks,
    required this.updateBooks,
    required this.errors,
    required this.detectedHeaders,
    required this.totalDataRows,
  });

  bool get hasValidBooks => validBooks.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}

/// Service that handles parsing, validation, and sample generation for bulk book CSVs.
class CsvBookImportService {
  final DatabaseHelper _dbHelper;

  CsvBookImportService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Cleans and decodes raw byte content into a string, handling UTF-8 BOM,
  /// Windows-1252/Latin-1 fallbacks, and newline normalizations.
  static String decodeCsvBytes(Uint8List bytes) {
    String content;
    try {
      // Check and strip UTF-8 BOM (0xEF, 0xBB, 0xBF)
      if (bytes.length >= 3 &&
          bytes[0] == 0xEF &&
          bytes[1] == 0xBB &&
          bytes[2] == 0xBF) {
        content = utf8.decode(bytes.sublist(3));
      } else {
        content = utf8.decode(bytes);
      }
    } catch (_) {
      // Fallback to latin1 if not valid UTF-8
      content = latin1.decode(bytes);
    }

    // Strip leading zero-width spaces / BOM if still present in string
    if (content.startsWith('\uFEFF')) {
      content = content.substring(1);
    }

    return content;
  }

  /// Normalizes a header title for robust matching across Bengali and English variations.
  static String _normalizeHeader(String header) {
    return header
        .trim()
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .replaceAll('\t', '')
        .replaceAll('.', '')
        .replaceAll(':', '');
  }

  /// Identifies which book field corresponds to a given header string.
  static String? _mapHeaderToField(String rawHeader) {
    final h = _normalizeHeader(rawHeader);
    if (h.isEmpty) return null;

    // 1. Accession No
    if (h == 'accessionno' ||
        h == 'accession' ||
        h == 'accno' ||
        h == 'bookid' ||
        h == 'id' ||
        h == 'sl' ||
        h == 'slno' ||
        h == 'serial' ||
        h == 'serialno' ||
        h == 'কিতাবনম্বর' ||
        h == 'কিতাবনং' ||
        h == 'বইনম্বর' ||
        h == 'বইনং' ||
        h == 'অ্যাকসেশননম্বর' ||
        h == 'অ্যাকসেশননং' ||
        h == 'অ্যাকসেশন' ||
        h == 'ক্যাটালগনম্বর' ||
        h == 'ক্যাটালগনং' ||
        h == 'ক্রমিকনম্বর' ||
        h == 'ক্রমিকনং' ||
        h == 'ক্রমিক' ||
        h == 'সিরিয়াল' ||
        h == 'সিরিয়াল') {
      return 'accession_no';
    }

    // 2. Book Name
    if (h == 'bookname' ||
        h == 'name' ||
        h == 'title' ||
        h == 'booktitle' ||
        h == 'book' ||
        h == 'কিতাবেরনাম' ||
        h == 'কিতাব' ||
        h == 'বইয়েরনাম' ||
        h == 'বইয়েরনাম' ||
        h == 'বই' ||
        h == 'নাম') {
      return 'book_name';
    }

    // 3. Volume No
    if (h == 'volumeno' ||
        h == 'volume' ||
        h == 'vol' ||
        h == 'part' ||
        h == 'partno' ||
        h == 'jild' ||
        h == 'খণ্ড' ||
        h == 'খন্ড' ||
        h == 'জিল্দ' ||
        h == 'ভাগ' ||
        h == 'পার্ট') {
      return 'volume_no';
    }

    // 4. Author
    if (h == 'author' ||
        h == 'writer' ||
        h == 'musannif' ||
        h == 'লেখক' ||
        h == 'মুসান্নিফ' ||
        h == 'মুসান্নিফ/লেখক' ||
        h == 'রচয়িতা' ||
        h == 'রচিয়তা') {
      return 'author';
    }

    // 5. Translator
    if (h == 'translator' ||
        h == 'mutarjim' ||
        h == 'অনুবাদক' ||
        h == 'মুতারজিম' ||
        h == 'অনুবাদ') {
      return 'translator';
    }

    // 6. Publisher
    if (h == 'publisher' ||
        h == 'maktaba' ||
        h == 'press' ||
        h == 'publication' ||
        h == 'প্রকাশনী' ||
        h == 'মাকতাবা' ||
        h == 'প্রকাশক' ||
        h == 'মুদ্রণ') {
      return 'publisher';
    }

    // 7. Address
    if (h == 'address' ||
        h == 'place' ||
        h == 'location' ||
        h == 'city' ||
        h == 'ঠিকানা' ||
        h == 'স্থান' ||
        h == 'প্রকাশনারস্থান') {
      return 'address';
    }

    // 8. Subject Category
    if (h == 'subjectcategory' ||
        h == 'subject' ||
        h == 'category' ||
        h == 'fan' ||
        h == 'discipline' ||
        h == 'বিষয়' ||
        h == 'বিষয়' ||
        h == 'ক্যাটাগরি' ||
        h == 'বিভাগ' ||
        h == ' শাখা' ||
        h == 'ফান' ||
        h == 'ফন') {
      return 'subject_category';
    }

    // 9. Shelf No
    if (h == 'shelfno' ||
        h == 'shelf' ||
        h == 'rack' ||
        h == 'almari' ||
        h == 'শেলফ' ||
        h == 'শেলফনম্বর' ||
        h == 'শেলফনং' ||
        h == 'আলমারি' ||
        h == 'আলমারিনং' ||
        h == 'রেক' ||
        h == 'তাক') {
      return 'shelf_no';
    }

    // 10. Status
    if (h == 'status' ||
        h == 'state' ||
        h == 'অবস্থা' ||
        h == 'স্ট্যাটাস') {
      return 'status';
    }

    // 11. Remarks
    if (h == 'remarks' ||
        h == 'remark' ||
        h == 'notes' ||
        h == 'note' ||
        h == 'comment' ||
        h == 'comments' ||
        h == 'description' ||
        h == 'মন্তব্য' ||
        h == 'নোট' ||
        h == 'বিবরণ') {
      return 'remarks';
    }

    return null;
  }

  /// Parses status strings in English or Bengali into a valid [BookStatus].
  static BookStatus _parseStatus(String? raw) {
    if (raw == null || raw.trim().isEmpty) return BookStatus.available;
    final s = raw.trim().toLowerCase();

    if (s == 'lent' || s.contains('ধার') || s.contains('ইস্যু') || s.contains('লেন্ট')) {
      return BookStatus.lent;
    }
    if (s == 'lost' || s.contains('হারিয়ে') || s.contains('হারানো')) {
      return BookStatus.lost;
    }
    if (s == 'damaged' || s.contains('নষ্ট') || s.contains('ছেঁড়া') || s.contains('ছেড়া')) {
      return BookStatus.damaged;
    }
    if (s == 'reference only' ||
        s == 'reference' ||
        s.contains('রেফারেন্স') ||
        s.contains('শুধুমাত্র')) {
      return BookStatus.referenceOnly;
    }

    return BookStatus.available;
  }

  /// Detects whether the delimiter is Tab (\t), Semicolon (;), or Comma (,).
  static String _detectDelimiter(String text) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .take(5)
        .toList();
    if (lines.isEmpty) return ',';

    int tabCount = 0;
    int commaCount = 0;
    int semiCount = 0;

    for (final line in lines) {
      tabCount += '\t'.allMatches(line).length;
      commaCount += ','.allMatches(line).length;
      semiCount += ';'.allMatches(line).length;
    }

    if (tabCount > 0 && tabCount >= commaCount && tabCount >= semiCount) {
      return '\t';
    }
    if (semiCount > commaCount && semiCount > tabCount) {
      return ';';
    }
    return ',';
  }

  /// Analyzes CSV or TSV content, validates fields, and categorizes into new vs update.
  Future<CsvImportPreviewResult> analyzeCsv(String csvContent) async {
    // 1. Convert CSV content to rows with auto-detected delimiter
    final delimiter = _detectDelimiter(csvContent);
    final converter = CsvToListConverter(
      fieldDelimiter: delimiter,
      eol: '\n',
      shouldParseNumbers: false,
      allowInvalid: true,
    );

    // Normalize Windows CRLF to standard LF
    final normalizedContent = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final List<List<dynamic>> rows = converter.convert(normalizedContent);

    if (rows.isEmpty) {
      return const CsvImportPreviewResult(
        validBooks: [],
        newBooks: [],
        updateBooks: [],
        errors: [
          CsvRowError(
            rowNumber: 1,
            rawContent: '',
            reason: 'ফাইলটি ফাঁকা, কোনো তথ্য পাওয়া যায়নি।',
          ),
        ],
        detectedHeaders: [],
        totalDataRows: 0,
      );
    }

    // 2. Extract and match header row
    final headerRow = rows.first;
    final Map<int, String> colToField = {};
    final List<String> rawHeaders = [];

    for (int col = 0; col < headerRow.length; col++) {
      final headerStr = headerRow[col]?.toString().trim() ?? '';
      rawHeaders.add(headerStr);
      final field = _mapHeaderToField(headerStr);
      if (field != null) {
        colToField[col] = field;
      }
    }

    bool hasHeaderRow = colToField.values.contains('accession_no') &&
        colToField.values.contains('book_name');
    int startRowIndex = 1;

    // If row 0 doesn't have required header words, check if row 0 is already a data row
    // (e.g. user copied only the book rows directly from Google Sheets without Row 1)
    if (!hasHeaderRow && headerRow.length >= 2) {
      final firstCell = headerRow[0]?.toString().trim() ?? '';
      final secondCell = headerRow[1]?.toString().trim() ?? '';

      final isKnownHeaderWord = _mapHeaderToField(firstCell) != null ||
          _mapHeaderToField(secondCell) != null;

      final isFirstCellNumeric = int.tryParse(firstCell.toEnglishNumerals) != null ||
          RegExp(r'^[0-9\u09E6-\u09EF\u0660-\u0669]').hasMatch(firstCell);

      if (!isKnownHeaderWord &&
          firstCell.isNotEmpty &&
          secondCell.isNotEmpty &&
          isFirstCellNumeric) {
        // Row 0 is actual book data! Map standard Google Sheets columns in order
        hasHeaderRow = true;
        startRowIndex = 0; // Include row 0 in parsed books
        colToField.clear();
        rawHeaders.clear();

        const defaultColumns = [
          'accession_no',
          'book_name',
          'volume_no',
          'author',
          'translator',
          'publisher',
          'address',
          'subject_category',
          'shelf_no',
          'remarks',
          'status',
          'last_updated',
        ];

        for (int c = 0; c < headerRow.length && c < defaultColumns.length; c++) {
          colToField[c] = defaultColumns[c];
          rawHeaders.add(defaultColumns[c]);
        }
      }
    }

    // Verify required fields exist
    if (!hasHeaderRow) {
      return CsvImportPreviewResult(
        validBooks: const [],
        newBooks: const [],
        updateBooks: const [],
        errors: [
          CsvRowError(
            rowNumber: 1,
            rawContent: headerRow.join(delimiter == '\t' ? '\t' : ', '),
            reason:
                'কলামের নাম (accession_no বা book_name) পাওয়া যায়নি। গুগল শিট থেকে কপি করার সময় কলামের নামসহ (Row 1 সহ) কপি করুন অথবা কিতাব নম্বর ও কিতাবের নাম প্রথম দুই কলামে রাখুন।',
          ),
        ],
        detectedHeaders: rawHeaders,
        totalDataRows: rows.length,
      );
    }

    // 3. Fetch existing accession numbers from database to identify new vs update
    final Set<String> existingAccessionNos = {};
    try {
      final db = await _dbHelper.database;
      final existingRows = await db.query(
        kBooksTable,
        columns: ['accession_no'],
      );
      for (final r in existingRows) {
        final acc = r['accession_no']?.toString().trim();
        if (acc != null && acc.isNotEmpty) {
          existingAccessionNos.add(acc);
        }
      }
    } catch (_) {
      // If db read fails, proceed gracefully
    }

    // 4. Parse data rows
    final List<Book> validBooks = [];
    final List<Book> newBooks = [];
    final List<Book> updateBooks = [];
    final List<CsvRowError> errors = [];
    final Set<String> batchAccessionTracker = {};
    final now = DateTime.now();

    int totalDataRows = 0;

    for (int rowIndex = startRowIndex; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];

      // Skip completely empty rows
      final bool isEmptyRow = row.every((c) => c?.toString().trim().isEmpty ?? true);
      if (isEmptyRow) continue;

      totalDataRows++;

      // Extract values according to mapped columns
      String accessionNo = '';
      String bookName = '';
      String? volumeNo;
      String? author;
      String? translator;
      String? publisher;
      String? address;
      String? subjectCategory;
      String? shelfNo;
      BookStatus status = BookStatus.available;
      String? remarks;

      for (int col = 0; col < row.length; col++) {
        final field = colToField[col];
        if (field == null) continue;

        final rawVal = row[col]?.toString().trim() ?? '';
        if (rawVal.isEmpty) continue;

        switch (field) {
          case 'accession_no':
            // Convert Bengali/Arabic numerals to standard digits
            accessionNo = rawVal.toEnglishNumerals.trim();
            break;
          case 'book_name':
            bookName = rawVal;
            break;
          case 'volume_no':
            volumeNo = rawVal.toEnglishNumerals.trim();
            break;
          case 'author':
            author = rawVal;
            break;
          case 'translator':
            translator = rawVal;
            break;
          case 'publisher':
            publisher = rawVal;
            break;
          case 'address':
            address = rawVal;
            break;
          case 'subject_category':
            subjectCategory = rawVal;
            break;
          case 'shelf_no':
            shelfNo = rawVal;
            break;
          case 'status':
            status = _parseStatus(rawVal);
            break;
          case 'remarks':
            remarks = rawVal;
            break;
        }
      }

      // Validation: Accession No and Book Name are required
      if (accessionNo.isEmpty) {
        errors.add(
          CsvRowError(
            rowNumber: rowIndex + 1,
            rawContent: row.join(', '),
            reason: 'কিতাব নম্বর (Accession No) খালি রাখা যাবে না।',
          ),
        );
        continue;
      }

      if (bookName.isEmpty) {
        errors.add(
          CsvRowError(
            rowNumber: rowIndex + 1,
            rawContent: row.join(', '),
            reason: 'কিতাবের নাম (Book Name) খালি রাখা যাবে না।',
          ),
        );
        continue;
      }

      final book = Book(
        accessionNo: accessionNo,
        bookName: bookName,
        volumeNo: volumeNo,
        author: author,
        translator: translator,
        publisher: publisher,
        address: address,
        subjectCategory: subjectCategory,
        shelfNo: shelfNo,
        status: status,
        remarks: remarks,
        lastUpdated: now,
      );

      validBooks.add(book);

      // Check if duplicate within current file or updating existing DB book
      if (existingAccessionNos.contains(accessionNo) ||
          batchAccessionTracker.contains(accessionNo)) {
        updateBooks.add(book);
      } else {
        newBooks.add(book);
      }

      batchAccessionTracker.add(accessionNo);
    }

    return CsvImportPreviewResult(
      validBooks: validBooks,
      newBooks: newBooks,
      updateBooks: updateBooks,
      errors: errors,
      detectedHeaders: rawHeaders,
      totalDataRows: totalDataRows,
    );
  }

  /// Generates sample CSV template content with Bengali headers and realistic examples.
  static String generateSampleCsvContent() {
    final sampleRows = [
      [
        'accession_no',
        'book_name',
        'volume_no',
        'author',
        'translator',
        'publisher',
        'address',
        'subject_category',
        'shelf_no',
        'status',
        'remarks',
      ],
      [
        '1001',
        'সহীহ বুখারী',
        '1',
        'ইমাম বুখারী (রহ.)',
        'মাওলানা ফজলুর রহমান',
        'ইসলামিক ফাউন্ডেশন',
        'ঢাকা',
        'হাদীস',
        'A-1',
        'Available',
        'উন্নত বাঁধাই',
      ],
      [
        '1002',
        'সহীহ বুখারী',
        '2',
        'ইমাম বুখারী (রহ.)',
        'মাওলানা ফজলুর রহমান',
        'ইসলামিক ফাউন্ডেশন',
        'ঢাকা',
        'হাদীস',
        'A-1',
        'Available',
        '',
      ],
      [
        '1003',
        'আল হিদায়া',
        '1',
        'আল্লামা মারগীনানী (রহ.)',
        '',
        'মাকতাবাতুল বুশরা',
        'করাচি',
        'ফিকহ',
        'B-3',
        'Available',
        'দরসি কিতাব',
      ],
      [
        '1004',
        'রিয়াদুস সালেহীন',
        '',
        'ইমাম নববী (রহ.)',
        'মুফতি আব্দুল্লাহ',
        'তাকওয়া প্রকাশন',
        'ঢাকা',
        'হাদীস ও আখলাক',
        'A-2',
        'Available',
        '',
      ],
    ];

    const converter = ListToCsvConverter(eol: '\r\n');
    return '\uFEFF${converter.convert(sampleRows)}'; // Prepend UTF-8 BOM for Excel / Google Sheets
  }

  /// Generates sample CSV template bytes (UTF-8 encoded with BOM).
  static Uint8List generateSampleCsvBytes() {
    final content = generateSampleCsvContent();
    return Uint8List.fromList(utf8.encode(content));
  }
}
