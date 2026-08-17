import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:maktaba_ihsan/core/models/user_model.dart';
import 'package:maktaba_ihsan/core/models/transaction_model.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> printTransactionHistory(User user,
      List<LibraryTransaction> transactions, AppTranslations t) async {
    final pdf = pw.Document();

    // Load custom fonts for fallback (Bengali, Arabic, Urdu)
    final fontDataBn =
        await rootBundle.load('assets/fonts/SolaimanLipi_22-02-2012.ttf');
    final ttfBn = pw.Font.ttf(fontDataBn);

    final fontDataAr = await rootBundle
        .load('assets/fonts/KFGQPC Uthmanic Script HAFS Regular.otf');
    final ttfAr = pw.Font.ttf(fontDataAr);

    final fontDataUr = await rootBundle
        .load('assets/fonts/Jameel Noori Nastaleeq Regular.ttf');
    final ttfUr = pw.Font.ttf(fontDataUr);

    final pdfTheme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      fontFallback: [ttfBn, ttfAr, ttfUr],
    );

    final dateFormat = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: pdfTheme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
        ),
        build: (pw.Context context) {
          return [
            // Header
            pw.Center(
              child: pw.Text(
                'مكتبة الإحسان / মাকতাবাতুল ইহসান',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                '${t.transactionList} - ${user.name}',
                style: pw.TextStyle(fontSize: 18),
              ),
            ),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 16),

            // User Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${t.name}: ${user.name}',
                        style: pw.TextStyle(fontSize: 14)),
                    pw.Text('ID: ${user.userId}',
                        style: pw.TextStyle(fontSize: 14)),
                    pw.Text('${t.classJamat}: ${user.classJamat ?? ""}',
                        style: pw.TextStyle(fontSize: 14)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('${t.phone}: ${user.phone ?? ""}',
                        style: pw.TextStyle(fontSize: 14)),
                    pw.Text('${dateFormat.format(DateTime.now())}',
                        style: pw.TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Transactions Table
            pw.TableHelper.fromTextArray(
              headers: [
                'ID',
                t.books,
                t.issueDate.replaceAll(':', ''),
                t.returnDate.replaceAll(':', ''),
                t.status
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              data: transactions.map((tx) {
                final isOverdue = tx.isOverdue;
                String statusText = t.statusIssued;
                if (tx.status == TransactionStatus.returned)
                  statusText = t.statusReturned;
                else if (isOverdue) statusText = t.statusOverdue;

                return [
                  tx.accessionNo,
                  tx.bookName ?? t.unknownBook,
                  dateFormat.format(tx.issueDate.toLocal()),
                  tx.actualReturn != null
                      ? dateFormat.format(tx.actualReturn!.toLocal())
                      : '-',
                  statusText,
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${user.name}_transactions.pdf',
    );
  }
}
