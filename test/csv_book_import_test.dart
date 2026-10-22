import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktaba_ihsan/core/services/csv_book_import_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CsvBookImportService Tests', () {
    final service = CsvBookImportService();

    test('decodeCsvBytes strips UTF-8 BOM', () {
      final bomBytes = Uint8List.fromList([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode('accession_no,book_name\n101,বুখারী'),
      ]);
      final decoded = CsvBookImportService.decodeCsvBytes(bomBytes);
      expect(decoded.startsWith('accession_no'), isTrue);
      expect(decoded.contains('বুখারী'), isTrue);
    });

    test('parses CSV with English headers', () async {
      const csv = '''accession_no,book_name,volume_no,author,subject_category,shelf_no
1001,Sahih Bukhari,1,Imam Bukhari,Hadith,A-1
1002,Sahih Muslim,,Imam Muslim,Hadith,A-2''';

      final result = await service.analyzeCsv(csv);

      expect(result.hasValidBooks, isTrue);
      expect(result.validBooks.length, equals(2));
      expect(result.errors.isEmpty, isTrue);

      final b1 = result.validBooks[0];
      expect(b1.accessionNo, equals('1001'));
      expect(b1.bookName, equals('Sahih Bukhari'));
      expect(b1.volumeNo, equals('1'));
      expect(b1.author, equals('Imam Bukhari'));
      expect(b1.subjectCategory, equals('Hadith'));
      expect(b1.shelfNo, equals('A-1'));

      final b2 = result.validBooks[1];
      expect(b2.accessionNo, equals('1002'));
      expect(b2.bookName, equals('Sahih Muslim'));
      expect(b2.volumeNo, isNull);
    });

    test('parses CSV with Bengali headers and Bengali numerals', () async {
      const csv = '''কিতাব নম্বর,কিতাবের নাম,খণ্ড,লেখক,বিষয়,শেলফ
১০১,সহীহ বুখারী,১,ইমাম বুখারী (রহ.),হাদীস,A-1
১০২,আল হিদায়া,২,মারগীনানী (রহ.),ফিকহ,B-2''';

      final result = await service.analyzeCsv(csv);

      expect(result.hasValidBooks, isTrue);
      expect(result.validBooks.length, equals(2));
      expect(result.errors.isEmpty, isTrue);

      final b1 = result.validBooks[0];
      expect(b1.accessionNo, equals('101')); // Converted to English numerals
      expect(b1.bookName, equals('সহীহ বুখারী'));
      expect(b1.volumeNo, equals('1')); // Converted to English numerals
      expect(b1.author, equals('ইমাম বুখারী (রহ.)'));
      expect(b1.subjectCategory, equals('হাদীস'));
      expect(b1.shelfNo, equals('A-1'));

      final b2 = result.validBooks[1];
      expect(b2.accessionNo, equals('102'));
      expect(b2.volumeNo, equals('2'));
    });

    test('flags error when required fields are missing in row', () async {
      const csv = '''accession_no,book_name,author
1001,,Imam Bukhari
,Sahih Muslim,Imam Muslim
1003,Sunan Abi Dawud,Imam Abu Dawud''';

      final result = await service.analyzeCsv(csv);

      expect(result.validBooks.length, equals(1));
      expect(result.validBooks[0].accessionNo, equals('1003'));
      expect(result.errors.length, equals(2));
      expect(result.hasErrors, isTrue);
    });

    test('flags error when header is missing required columns', () async {
      const csv = '''author,publisher,subject
Imam Bukhari,Darul Kutub,Hadith''';

      final result = await service.analyzeCsv(csv);

      expect(result.validBooks.isEmpty, isTrue);
      expect(result.errors.length, equals(1));
      expect(result.errors[0].reason.contains('accession_no'), isTrue);
    });

    test('parses Tab-separated (TSV) pasted text with headers', () async {
      const tsv = 'accession_no\tbook_name\tvolume_no\tauthor\n'
          '1\tসহীহ বুখারী\t১\tইমাম বুখারী\n'
          '2\tসহীহ মুসলিম\t২\tইমাম মুসলিম';

      final result = await service.analyzeCsv(tsv);
      expect(result.hasValidBooks, isTrue);
      expect(result.validBooks.length, equals(2));
      expect(result.validBooks[0].accessionNo, equals('1'));
      expect(result.validBooks[0].bookName, equals('সহীহ বুখারী'));
      expect(result.validBooks[1].accessionNo, equals('2'));
    });

    test('parses Tab-separated Google Sheets copy WITHOUT headers', () async {
      // Simulates user selecting A2:K3 in Google Sheets and pasting
      const tsv = '1\tإعراب القرآن\t১\tمحيي الدين درويش\t\tদার ইবনে কাসির\t\tএ\'রাবুল কুরআন\t\t\tAvailable\n'
          '2\tإعراب القرآن\t২\tمحيي الدين درويش\t\tদার ইবনে কাসির\t\tএ\'রাবুল কুরআন\t\t\tAvailable';

      final result = await service.analyzeCsv(tsv);
      expect(result.hasValidBooks, isTrue);
      expect(result.validBooks.length, equals(2));
      expect(result.validBooks[0].accessionNo, equals('1'));
      expect(result.validBooks[0].bookName, equals('إعراب القرآن'));
      expect(result.validBooks[0].volumeNo, equals('1'));
      expect(result.validBooks[0].author, equals('محيي الدين درويش'));
      expect(result.validBooks[1].accessionNo, equals('2'));
      expect(result.validBooks[1].volumeNo, equals('2'));
      expect(result.errors.isEmpty, isTrue);
    });

    test('generateSampleCsvContent returns valid CSV with BOM', () {
      final sample = CsvBookImportService.generateSampleCsvContent();
      expect(sample.startsWith('\uFEFF'), isTrue);
      expect(sample.contains('accession_no'), isTrue);
      expect(sample.contains('book_name'), isTrue);
      expect(sample.contains('সহীহ বুখারী'), isTrue);
    });
  });
}
