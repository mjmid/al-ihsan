import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart' as material;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:maktaba_ihsan/core/models/user_model.dart';
import 'package:maktaba_ihsan/core/models/transaction_model.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<pw.Widget> _buildImageText(String text, {double fontSize = 12, bool bold = false}) async {
    if (text.isEmpty) return pw.SizedBox();
    
    final isArabic = RegExp(r'[\u0600-\u06FF\u0750-\u077F]').hasMatch(text);
    
    final textSpan = material.TextSpan(
      text: text,
      style: material.TextStyle(
        color: material.Colors.black,
        fontSize: fontSize * 3, // scale up for high-dpi print
        fontWeight: bold ? material.FontWeight.bold : material.FontWeight.normal,
        fontFamily: isArabic ? 'ArabicMyLotus' : 'BengaliSolaiman',
        height: 1.2,
      ),
    );
    final textPainter = material.TextPainter(
      text: textSpan,
      textDirection: isArabic ? material.TextDirection.rtl : material.TextDirection.ltr,
    );
    textPainter.layout();

    if (textPainter.width == 0 || textPainter.height == 0) return pw.SizedBox();

    final pictureRecorder = ui.PictureRecorder();
    final canvas = ui.Canvas(pictureRecorder);
    textPainter.paint(canvas, ui.Offset.zero);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(
      textPainter.width.ceil(),
      textPainter.height.ceil(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final memImage = pw.MemoryImage(byteData!.buffer.asUint8List());
    
    return pw.Container(
      width: textPainter.width / 3, // scale down to original font size
      height: textPainter.height / 3,
      alignment: isArabic ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Image(memImage, fit: pw.BoxFit.contain),
    );
  }

  static Future<void> printTransactionHistory(User user, List<LibraryTransaction> transactions, AppTranslations t) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Pre-render all texts
    final wHeader = await _buildImageText('মাকতাবাতুল ইহসান', fontSize: 22, bold: true);
    final wSubHeader = await _buildImageText('লেনদেনের তালিকা - ${user.name}', fontSize: 14);
    
    final wName = await _buildImageText('নাম: ${user.name}', fontSize: 11);
    final wId = await _buildImageText('আইডি: ${user.userId}', fontSize: 11);
    final wClass = await _buildImageText('শ্রেণী/জামাআত: ${user.classJamat ?? ""}', fontSize: 11);
    final wPhone = await _buildImageText('মোবাইল: ${user.phone ?? ""}', fontSize: 11);
    final wDate = await _buildImageText('তারিখ: ${dateFormat.format(DateTime.now())}', fontSize: 11);

    final wThId = await _buildImageText('আইডি', fontSize: 11, bold: true);
    final wThBook = await _buildImageText(t.books, fontSize: 11, bold: true);
    final wThIssue = await _buildImageText('নেওয়ার তারিখ', fontSize: 11, bold: true);
    final wThReturn = await _buildImageText('ফেরত দেওয়ার তারিখ', fontSize: 11, bold: true);
    final wThStatus = await _buildImageText('অবস্থা', fontSize: 11, bold: true);

    // Pre-render rows
    final renderedRows = <List<pw.Widget>>[];
    for (var tx in transactions) {
      final isOverdue = tx.isOverdue;
      String statusText = t.statusIssued;
      if (tx.status == TransactionStatus.returned) {
        statusText = t.statusReturned;
      } else if (isOverdue) {
        statusText = t.statusOverdue;
      }

      renderedRows.add([
        await _buildImageText(tx.accessionNo, fontSize: 10),
        await _buildImageText(tx.bookName ?? t.unknownBook, fontSize: 10),
        await _buildImageText(dateFormat.format(tx.issueDate.toLocal()), fontSize: 10),
        await _buildImageText(tx.actualReturn != null ? dateFormat.format(tx.actualReturn!.toLocal()) : '-', fontSize: 10),
        await _buildImageText(statusText, fontSize: 10),
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Center(child: wHeader),
            pw.SizedBox(height: 8),
            pw.Center(child: wSubHeader),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [wName, pw.SizedBox(height: 4), wId, pw.SizedBox(height: 4), wClass],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [wPhone, pw.SizedBox(height: 4), wDate],
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [wThId, wThBook, wThIssue, wThReturn, wThStatus].map((w) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Center(child: w),
                  )).toList(),
                ),
                ...renderedRows.map((row) => pw.TableRow(
                  children: row.map((w) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: w,
                  )).toList(),
                )),
              ],
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
