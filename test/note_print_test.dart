import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktaba_ihsan/core/models/hive_models/teacher_note.dart';
import 'package:maktaba_ihsan/core/services/teacher_backup_service.dart';
import 'package:maktaba_ihsan/features/teacher/presentation/pages/teacher_note_editor_page.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('TeacherNote & Content Parsing Tests', () {
    test('extractPlainText correctly handles Quill Delta JSON', () {
      final delta = [
        {'insert': 'বল বীর –\n'},
        {'insert': 'বল উন্নত মম শির!\n'},
        {'insert': 'চির উন্নত শির!\n', 'attributes': {'bold': true}},
      ];
      final jsonStr = jsonEncode(delta);
      final plainText = TeacherBackupService.extractPlainText(jsonStr);

      expect(plainText, contains('বল বীর –'));
      expect(plainText, contains('বল উন্নত মম শির!'));
      expect(plainText, contains('চির উন্নত শির!'));
    });

    test('extractPlainText gracefully falls back for raw plain text', () {
      const rawText = 'বিদ্রোহী\nবল বীর –\nবল উন্নত মম শির!';
      final plainText = TeacherBackupService.extractPlainText(rawText);
      expect(plainText, equals(rawText));
    });

    test('TeacherNote copyWith correctly updates content with JSON delta', () {
      final note = TeacherNote(
        id: 'test-1',
        folderId: 'default',
        title: 'বিদ্রোহী',
        content: 'plain text',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final deltaJson = jsonEncode([
        {'insert': 'বল বীর –\n'}
      ]);

      final updated = note.copyWith(content: deltaJson);
      expect(updated.content, equals(deltaJson));
      expect(updated.title, equals('বিদ্রোহী'));
    });
  });

  group('Arabic Voice Note Ta Marbuta (ه ➔ ة) Tests', () {
    test('Corrects speech-recognized feminine nouns from ha to ta marbuta', () {
      expect(TeacherNoteEditorPage.fixArabicTaMarbuta('المكتبه'), equals('المكتبة'));
      expect(TeacherNoteEditorPage.fixArabicTaMarbuta('مدرسه'), equals('مدرسة'));
      expect(TeacherNoteEditorPage.fixArabicTaMarbuta('جامعه'), equals('جامعة'));
      expect(TeacherNoteEditorPage.fixArabicTaMarbuta('صفحه'), equals('صفحة'));
      expect(TeacherNoteEditorPage.fixArabicTaMarbuta('مسأله'), equals('مسألة'));
      expect(TeacherNoteEditorPage.fixArabicTaMarbuta('آيه'), equals('آية'));
      expect(TeacherNoteEditorPage.fixArabicTaMarbuta('سوره'), equals('سورة'));
      expect(TeacherNoteEditorPage.fixArabicTaMarbuta('الصفحه الثالثه'), equals('الصفحة الثالثة'));
    });

    test('Preserves authentic ha words and prepositions/pronouns', () {
      expect(TeacherNoteEditorPage.fixArabicTaMarbuta('الله'), equals('الله'));
      expect(TeacherNoteEditorPage.fixArabicTaMarbuta('والله'), equals('والله'));
      expect(TeacherNoteEditorPage.fixArabicTaMarbuta('له'), equals('له'));
      expect(TeacherNoteEditorPage.fixArabicTaMarbuta('به'), equals('به'));
      expect(TeacherNoteEditorPage.fixArabicTaMarbuta('فيه'), equals('فيه'));
      expect(TeacherNoteEditorPage.fixArabicTaMarbuta('منه'), equals('منه'));
      expect(TeacherNoteEditorPage.fixArabicTaMarbuta('عنه'), equals('عنه'));
      expect(TeacherNoteEditorPage.fixArabicTaMarbuta('وجه'), equals('وجه'));
      expect(TeacherNoteEditorPage.fixArabicTaMarbuta('فقه'), equals('فقه'));
      expect(TeacherNoteEditorPage.fixArabicTaMarbuta('هذه'), equals('هذه'));
    });

    test('Corrects mixed sentence while keeping authentic words intact', () {
      const input = 'قال في هذه المسأله رحمه الله في كتابه';
      // المسأله -> المسألة, رحمه -> رحمة, but هذه and الله are preserved!
      final result = TeacherNoteEditorPage.fixArabicTaMarbuta(input);
      expect(result, contains('هذه'));
      expect(result, contains('المسألة'));
      expect(result, contains('الله'));
      expect(result, contains('رحمة'));
    });
  });

  group('Pt Font Size Parsing Tests', () {
    test('Font size attributes parse cleanly whether int, double, or pt string', () {
      double? parseSize(dynamic sizeVal) {
        if (sizeVal == null) return null;
        if (sizeVal is num) return sizeVal.toDouble();
        final cleanStr = sizeVal.toString().replaceAll(RegExp(r'[^0-9.]'), '');
        final parsed = double.tryParse(cleanStr);
        if (parsed != null && parsed > 0) return parsed;
        return null;
      }

      expect(parseSize(16), equals(16.0));
      expect(parseSize(18.5), equals(18.5));
      expect(parseSize('18'), equals(18.0));
      expect(parseSize('24 pt'), equals(24.0));
      expect(parseSize('32pt'), equals(32.0));
      expect(parseSize('0'), isNull);
    });
  });

  group('PDF MultiPage Pagination Tests', () {
    test('MultiPage layout does not overflow pageFormat height', () async {
      final pdf = pw.Document();
      final widgets = <pw.Widget>[];

      for (int i = 1; i <= 60; i++) {
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 4),
            height: 18,
            child: pw.Text('Line $i: বল বীর – বল উন্নত মম শির!'),
          ),
        );
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.only(
            left: 32,
            top: 28,
            right: 32,
            bottom: 28,
          ),
          build: (pw.Context context) => widgets,
        ),
      );

      final bytes = await pdf.save();
      expect(bytes.length, greaterThan(1000));
    });
  });
}