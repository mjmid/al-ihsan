import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:maktaba_ihsan/core/models/book_model.dart';
import 'package:maktaba_ihsan/core/models/transaction_model.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';

class PrintService {
  /// Loads a Bengali/Arabic supporting font.
  /// Ensure you have a compatible font in your assets, e.g., NotoSansBengali.
  static Future<pw.Font> _loadFont() async {
    try {
      final fontData = await rootBundle
          .load('assets/fonts/KFGQPC Uthmanic Script HAFS Regular.otf');
      return pw.Font.ttf(fontData);
    } catch (e) {
      // Fallback to default if custom font fails to load
      return pw.Font.helvetica();
    }
  }

  /// Prints the list of books
  static Future<void> printBooks(List<Book> books, AppTranslations t) async {
    final pdf = pw.Document();
    final font = await _loadFont();
    final fallbackFont = await PdfGoogleFonts.notoSansBengaliRegular();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: font,
          fontFallback: [fallbackFont],
        ),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(t.appTitle,
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(t.bookList, style: pw.TextStyle(fontSize: 24)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Accession No', t.name, t.author, t.category, t.status],
              data: books.map((book) {
                return [
                  book.accessionNo,
                  book.bookName,
                  book.author ?? '',
                  book.subjectCategory ?? '',
                  _translateBookStatus(book.status, t),
                ];
              }).toList(),
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Books_List_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Prints the list of transactions
  static Future<void> printTransactions(
      List<LibraryTransaction> transactions, AppTranslations t) async {
    final pdf = pw.Document();
    final font = await _loadFont();
    final fallbackFont = await PdfGoogleFonts.notoSansBengaliRegular();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: font,
          fontFallback: [fallbackFont],
        ),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(t.transactionList,
                        style: pw.TextStyle(fontSize: 24)),
                    pw.Text(t.appTitle,
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.TableHelper.fromTextArray(
                context: context,
                headers: [
                  'Trx ID',
                  t.books,
                  t.members,
                  t.issueDate,
                  t.returnDate,
                  t.status
                ],
                data: transactions.map((tx) {
                  return [
                    tx.trxId,
                    tx.bookName ?? tx.accessionNo,
                    tx.userName ?? tx.userId,
                    tx.issueDate.toString().split(' ')[0],
                    tx.expectedReturn.toString().split(' ')[0],
                    _translateTxStatus(tx, t),
                  ];
                }).toList(),
                headerStyle:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignments: {
                  0: pw.Alignment.centerRight,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                  5: pw.Alignment.center,
                },
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Transactions_List_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static String _translateBookStatus(BookStatus status, AppTranslations t) {
    switch (status) {
      case BookStatus.available:
        return t.bookStatusAvailable;
      case BookStatus.lent:
        return t.bookStatusIssued;
      case BookStatus.lost:
      case BookStatus.damaged:
        return t.bookStatusLost;
      case BookStatus.referenceOnly:
        return t.bookStatusAvailable;
    }
  }

  static String _translateTxStatus(LibraryTransaction tx, AppTranslations t) {
    if (tx.status == TransactionStatus.returned) {
      return t.statusReturned;
    }
    if (tx.isOverdue) {
      return t.statusOverdue;
    }
    return t.statusIssued;
  }
}
