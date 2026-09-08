import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:maktaba_ihsan/core/models/book_model.dart';
import 'package:maktaba_ihsan/core/models/transaction_model.dart';
import 'package:maktaba_ihsan/core/models/asset_model.dart';
import 'package:maktaba_ihsan/core/models/hive_models/teacher_note.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';

class _RenderedTextImage {
  final pw.MemoryImage image;
  final double logicalWidth;
  final double logicalHeight;
  const _RenderedTextImage(this.image, this.logicalWidth, this.logicalHeight);
}

class _NoteSpan {
  final String text;
  final bool bold;
  final bool italic;
  final double? fontSize;
  final material.Color? color;

  _NoteSpan({
    required this.text,
    this.bold = false,
    this.italic = false,
    this.fontSize,
    this.color,
  });
}

class _NoteLine {
  final List<_NoteSpan> spans;
  final int? header;
  final String? align;
  final bool isBullet;
  final bool isNumbered;

  _NoteLine({
    required this.spans,
    this.header,
    this.align,
    this.isBullet = false,
    this.isNumbered = false,
  });

  bool get isEmpty => spans.isEmpty || spans.every((s) => s.text.trim().isEmpty);
}

class PrintService {
  static final Map<String, _RenderedTextImage> _textImageCache = {};

  /// Renders complex Bengali, Arabic, and English text into a high-DPI
  /// bitmap image using Flutter's native HarfBuzz text shaping engine and
  /// embedded fonts (SolaimanLipi & MyLotus). This completely prevents broken
  /// Bengali conjuncts/ligatures (যুক্তাক্ষর, র-ফলা, য-ফলা, রেফ, ই-কার).
  static Future<pw.Widget> _buildImageText(
    String text, {
    double fontSize = 10,
    bool bold = false,
    material.Color color = material.Colors.black,
    pw.Alignment alignment = pw.Alignment.centerLeft,
    double? maxWidth,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return pw.SizedBox();

    final cacheKey = '${cleanText}_${fontSize}_${bold}_${color.value}_${maxWidth?.toInt() ?? 0}';
    final cached = _textImageCache[cacheKey];

    if (cached != null) {
      if (maxWidth != null) {
        return pw.Container(
          alignment: alignment,
          child: pw.Image(
            cached.image,
            width: cached.logicalWidth,
            height: cached.logicalHeight,
            fit: pw.BoxFit.contain,
          ),
        );
      }
      return pw.Container(
        alignment: alignment,
        child: pw.Image(cached.image, height: fontSize * 1.35, fit: pw.BoxFit.contain),
      );
    }

    final isUrdu = RegExp(r'[\u067E\u0686\u0698\u06AF\u06D2\u0688\u0691\u0679\u06BA\u06C1\u06BE]').hasMatch(cleanText);
    final isArabic = RegExp(r'[\u0600-\u06FF\u0750-\u077F]').hasMatch(cleanText);

    String fontToUse = 'BengaliSolaiman';
    if (isUrdu) {
      fontToUse = 'UrduNastaleeq';
    } else if (isArabic) {
      fontToUse = 'ArabicMyLotus';
    }

    final textSpan = material.TextSpan(
      text: cleanText,
      style: material.TextStyle(
        color: color,
        fontSize: fontSize * 3.0, // 3x scale for crisp 300+ DPI print quality
        fontWeight: bold ? material.FontWeight.bold : material.FontWeight.normal,
        fontFamily: fontToUse,
        fontFamilyFallback: const [
          'ArabicMyLotus',
          'ArabicUthmanic',
          'UrduNastaleeq',
          'BengaliSolaiman',
        ],
        height: 1.3,
      ),
    );
    final textPainter = material.TextPainter(
      text: textSpan,
      textDirection: (isArabic || isUrdu) ? material.TextDirection.rtl : material.TextDirection.ltr,
    );
    if (maxWidth != null) {
      textPainter.layout(maxWidth: maxWidth * 3.0);
    } else {
      textPainter.layout();
    }

    if (textPainter.width == 0 || textPainter.height == 0) {
      return pw.SizedBox();
    }

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

    final rendered = _RenderedTextImage(
      memImage,
      textPainter.width / 3.0,
      textPainter.height / 3.0,
    );
    _textImageCache[cacheKey] = rendered;

    if (maxWidth != null) {
      return pw.Container(
        alignment: alignment,
        child: pw.Image(
          rendered.image,
          width: rendered.logicalWidth,
          height: rendered.logicalHeight,
          fit: pw.BoxFit.contain,
        ),
      );
    }

    return pw.Container(
      alignment: alignment,
      child: pw.Image(rendered.image, height: fontSize * 1.35, fit: pw.BoxFit.contain),
    );
  }

  static Future<(pw.MemoryImage, pw.MemoryImage)> _loadBrandingImages() async {
    final logoBytes = (await rootBundle.load('assets/images/logo_light.png')).buffer.asUint8List();
    final calligBytes = (await rootBundle.load('assets/images/calligraphy_green.png')).buffer.asUint8List();
    return (pw.MemoryImage(logoBytes), pw.MemoryImage(calligBytes));
  }

  static pw.Widget _buildHeader(pw.MemoryImage logo, pw.MemoryImage callig, pw.Widget titleWidget) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      margin: const pw.EdgeInsets.only(bottom: 14),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Image(logo, height: 42, fit: pw.BoxFit.contain),
              pw.SizedBox(width: 12),
              pw.Image(callig, height: 36, fit: pw.BoxFit.contain),
            ],
          ),
          titleWidget,
        ],
      ),
    );
  }

  /// Prints the list of books with perfect Bengali typography
  static Future<void> printBooks(List<Book> books, AppTranslations t) async {
    final pdf = pw.Document();
    final (logoImage, calligImage) = await _loadBrandingImages();

    final titleWidget = await _buildImageText('বইয়ের তালিকা', fontSize: 16, bold: true, alignment: pw.Alignment.centerRight);

    // Pre-render headers
    final hNo = await _buildImageText('কিতাব নং', fontSize: 10, bold: true, alignment: pw.Alignment.center);
    final hName = await _buildImageText('কিতাবের নাম', fontSize: 10, bold: true, alignment: pw.Alignment.centerLeft);
    final hAuthor = await _buildImageText('লেখক', fontSize: 10, bold: true, alignment: pw.Alignment.centerLeft);
    final hCat = await _buildImageText('বিষয় / বিভাগ', fontSize: 10, bold: true, alignment: pw.Alignment.centerLeft);
    final hStatus = await _buildImageText('অবস্থা', fontSize: 10, bold: true, alignment: pw.Alignment.center);

    final headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: hNo),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: hName),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: hAuthor),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: hCat),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: hStatus),
      ],
    );

    final dataRows = <pw.TableRow>[];
    for (int i = 0; i < books.length; i++) {
      final book = books[i];
      final rNo = await _buildImageText(book.accessionNo, fontSize: 9, alignment: pw.Alignment.center);
      final rName = await _buildImageText(book.bookName, fontSize: 9, alignment: pw.Alignment.centerLeft);
      final rAuthor = await _buildImageText(book.author ?? '-', fontSize: 9, alignment: pw.Alignment.centerLeft);
      final rCat = await _buildImageText(book.subjectCategory ?? '-', fontSize: 9, alignment: pw.Alignment.centerLeft);
      final rStatus = await _buildImageText(_translateBookStatus(book.status, t), fontSize: 9, alignment: pw.Alignment.center);

      dataRows.add(
        pw.TableRow(
          decoration: i % 2 == 1 ? const pw.BoxDecoration(color: PdfColors.grey100) : null,
          children: [
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5), child: rNo),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5), child: rName),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5), child: rAuthor),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5), child: rCat),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5), child: rStatus),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(logoImage, calligImage, titleWidget),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2),
                1: pw.FlexColumnWidth(3.5),
                2: pw.FlexColumnWidth(2.2),
                3: pw.FlexColumnWidth(2.0),
                4: pw.FlexColumnWidth(1.5),
              },
              children: [
                headerRow,
                ...dataRows,
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Books_List.pdf',
    );
  }

  /// Prints the list of transactions with perfect Bengali typography
  static Future<void> printTransactions(
      List<LibraryTransaction> transactions, AppTranslations t) async {
    final pdf = pw.Document();
    final (logoImage, calligImage) = await _loadBrandingImages();

    final titleWidget = await _buildImageText('লেনদেনের তালিকা', fontSize: 16, bold: true, alignment: pw.Alignment.centerRight);

    // Pre-render headers
    final hNo = await _buildImageText('কিতাব নং', fontSize: 10, bold: true, alignment: pw.Alignment.center);
    final hName = await _buildImageText('কিতাবের নাম', fontSize: 10, bold: true, alignment: pw.Alignment.centerLeft);
    final hMember = await _buildImageText('সদস্যের নাম', fontSize: 10, bold: true, alignment: pw.Alignment.centerLeft);
    final hIssue = await _buildImageText('নেওয়ার তারিখ', fontSize: 10, bold: true, alignment: pw.Alignment.center);
    final hReturn = await _buildImageText('ফেরত দেওয়ার তারিখ', fontSize: 10, bold: true, alignment: pw.Alignment.center);
    final hStatus = await _buildImageText('অবস্থা', fontSize: 10, bold: true, alignment: pw.Alignment.center);

    final headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: hNo),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: hName),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: hMember),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: hIssue),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: hReturn),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: hStatus),
      ],
    );

    final dataRows = <pw.TableRow>[];
    for (int i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      final rNo = await _buildImageText(tx.accessionNo, fontSize: 9, alignment: pw.Alignment.center);
      final rName = await _buildImageText(tx.bookName ?? tx.accessionNo, fontSize: 9, alignment: pw.Alignment.centerLeft);
      final rMember = await _buildImageText(tx.userName ?? tx.userId, fontSize: 9, alignment: pw.Alignment.centerLeft);
      final rIssue = await _buildImageText(tx.issueDate.toString().split(' ')[0], fontSize: 9, alignment: pw.Alignment.center);
      final rReturn = await _buildImageText(tx.expectedReturn.toString().split(' ')[0], fontSize: 9, alignment: pw.Alignment.center);
      final rStatus = await _buildImageText(_translateTxStatus(tx), fontSize: 9, alignment: pw.Alignment.center);

      dataRows.add(
        pw.TableRow(
          decoration: i % 2 == 1 ? const pw.BoxDecoration(color: PdfColors.grey100) : null,
          children: [
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5), child: rNo),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5), child: rName),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5), child: rMember),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5), child: rIssue),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5), child: rReturn),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5), child: rStatus),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            _buildHeader(logoImage, calligImage, titleWidget),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2),
                1: pw.FlexColumnWidth(3.0),
                2: pw.FlexColumnWidth(2.5),
                3: pw.FlexColumnWidth(1.6),
                4: pw.FlexColumnWidth(1.6),
                5: pw.FlexColumnWidth(1.6),
              },
              children: [
                headerRow,
                ...dataRows,
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Transactions_List.pdf',
    );
  }

  /// Prints the list of assets/inventory with perfect Bengali typography
  static Future<void> printAssets(List<Asset> assets) async {
    final pdf = pw.Document();
    final (logoImage, calligImage) = await _loadBrandingImages();

    // Filter out phantom empty-name entries
    final validAssets = assets.where((a) => a.name.trim().isNotEmpty).toList();

    final titleWidget = await _buildImageText('মালামাল ও সরঞ্জাম অডিট তালিকা', fontSize: 16, bold: true, alignment: pw.Alignment.centerRight);

    // Pre-render headers
    final hId = await _buildImageText('আইডি', fontSize: 8.5, bold: true, alignment: pw.Alignment.center);
    final hName = await _buildImageText('মালামালের নাম', fontSize: 8.5, bold: true, alignment: pw.Alignment.centerLeft);
    final hCat = await _buildImageText('বিভাগ', fontSize: 8.5, bold: true, alignment: pw.Alignment.centerLeft);
    final hQty = await _buildImageText('পরিমাণ', fontSize: 8.5, bold: true, alignment: pw.Alignment.center);
    final hLoc = await _buildImageText('অবস্থান', fontSize: 8.5, bold: true, alignment: pw.Alignment.centerLeft);
    final hCond = await _buildImageText('বর্তমান অবস্থা', fontSize: 8.5, bold: true, alignment: pw.Alignment.center);
    final hSource = await _buildImageText('সংগ্রহ / দাতা', fontSize: 8.5, bold: true, alignment: pw.Alignment.centerLeft);
    final hRemarks = await _buildImageText('বিবরণ ও মন্তব্য', fontSize: 8.5, bold: true, alignment: pw.Alignment.centerLeft);

    final headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5), child: hId),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5), child: hName),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5), child: hCat),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5), child: hQty),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5), child: hLoc),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5), child: hCond),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5), child: hSource),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5), child: hRemarks),
      ],
    );

    final dataRows = <pw.TableRow>[];
    for (int i = 0; i < validAssets.length; i++) {
      final a = validAssets[i];
      final sourceText = a.acquisitionType == AcquisitionType.waqf
          ? (a.donorOrSource != null && a.donorOrSource!.trim().isNotEmpty
              ? 'ওয়াকফ (${a.donorOrSource})'
              : 'ওয়াকফ')
          : 'ক্রয়কৃত';
      final remarksText = (a.remarks != null && a.remarks!.trim().isNotEmpty) ? a.remarks! : '-';
      final qtyText = '${a.quantity} ${a.unit}';

      final rId = await _buildImageText(a.assetId, fontSize: 8, alignment: pw.Alignment.center);
      final rName = await _buildImageText(a.name, fontSize: 8, alignment: pw.Alignment.centerLeft);
      final rCat = await _buildImageText(a.category.isNotEmpty ? a.category : '-', fontSize: 8, alignment: pw.Alignment.centerLeft);
      final rQty = await _buildImageText(qtyText, fontSize: 8, alignment: pw.Alignment.center);
      final rLoc = await _buildImageText(a.location.isNotEmpty ? a.location : '-', fontSize: 8, alignment: pw.Alignment.centerLeft);
      final rCond = await _buildImageText(a.condition.label, fontSize: 8, alignment: pw.Alignment.center);
      final rSource = await _buildImageText(sourceText, fontSize: 8, alignment: pw.Alignment.centerLeft);
      final rRemarks = await _buildImageText(remarksText, fontSize: 8, alignment: pw.Alignment.centerLeft);

      dataRows.add(
        pw.TableRow(
          decoration: i % 2 == 1 ? const pw.BoxDecoration(color: PdfColors.grey100) : null,
          children: [
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4), child: rId),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4), child: rName),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4), child: rCat),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4), child: rQty),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4), child: rLoc),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4), child: rCond),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4), child: rSource),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4), child: rRemarks),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        build: (pw.Context context) {
          return [
            _buildHeader(logoImage, calligImage, titleWidget),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2),
                1: pw.FlexColumnWidth(2.6),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(1.1),
                4: pw.FlexColumnWidth(1.5),
                5: pw.FlexColumnWidth(1.5),
                6: pw.FlexColumnWidth(1.7),
                7: pw.FlexColumnWidth(2.2),
              },
              children: [
                headerRow,
                if (dataRows.isEmpty)
                  pw.TableRow(
                    children: List.generate(
                      8,
                      (idx) => pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: idx == 1
                            ? pw.Text('-', style: const pw.TextStyle(fontSize: 10))
                            : pw.SizedBox(),
                      ),
                    ),
                  )
                else
                  ...dataRows,
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'maktaba_assets_report.pdf',
    );
  }

  static String _translateBookStatus(BookStatus status, AppTranslations t) {
    switch (status) {
      case BookStatus.available:
        return 'মজুদ আছে';
      case BookStatus.lent:
        return 'নেওয়া হয়েছে';
      case BookStatus.lost:
        return 'হারিয়ে গেছে';
      case BookStatus.damaged:
        return 'ক্ষতিগ্রস্ত';
      case BookStatus.referenceOnly:
        return 'রেফারেন্স কপি';
    }
  }

  static String _translateTxStatus(LibraryTransaction tx) {
    if (tx.status == TransactionStatus.returned) {
      return 'ফেরত দেওয়া হয়েছে';
    }
    if (tx.isOverdue) {
      return 'মেয়াদোত্তীর্ণ';
    }
    return 'নেওয়া হয়েছে';
  }

  static List<_NoteLine> _parseNoteContent(String content) {
    final lines = <_NoteLine>[];
    if (content.trim().isEmpty) return lines;

    List<dynamic>? ops;
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        ops = decoded;
      }
    } catch (_) {
      ops = null;
    }

    if (ops == null) {
      for (final rawLine in content.split('\n')) {
        final trimmed = rawLine.trim();
        if (trimmed.isEmpty) {
          lines.add(_NoteLine(spans: []));
        } else {
          lines.add(_NoteLine(spans: [_NoteSpan(text: rawLine)]));
        }
      }
      return lines;
    }

    var currentSpans = <_NoteSpan>[];

    for (final rawOp in ops) {
      if (rawOp is! Map) continue;
      final insert = rawOp['insert'];
      if (insert is! String) continue;
      final attrs = rawOp['attributes'] as Map<String, dynamic>?;

      final isBold = attrs?['bold'] == true;
      final isItalic = attrs?['italic'] == true;

      double? fontSize;
      final sizeVal = attrs?['size'];
      if (sizeVal != null) {
        if (sizeVal == 'small') {
          fontSize = 11.0;
        } else if (sizeVal == 'normal') {
          fontSize = 13.0;
        } else if (sizeVal == 'large') {
          fontSize = 17.0;
        } else if (sizeVal == 'huge') {
          fontSize = 22.0;
        } else if (sizeVal is num) {
          fontSize = sizeVal.toDouble();
        } else {
          final cleanStr = sizeVal.toString().replaceAll(RegExp(r'[^0-9.]'), '');
          final parsed = double.tryParse(cleanStr);
          if (parsed != null && parsed > 0) fontSize = parsed;
        }
      }

      material.Color? color;
      final colorHex = attrs?['color']?.toString();
      if (colorHex != null && colorHex.startsWith('#')) {
        final hex = colorHex.replaceAll('#', '');
        if (hex.length == 6) {
          color = material.Color(int.parse('FF$hex', radix: 16));
        }
      }

      final parts = insert.split('\n');
      for (int i = 0; i < parts.length; i++) {
        final textPart = parts[i];
        if (textPart.isNotEmpty) {
          currentSpans.add(_NoteSpan(
            text: textPart,
            bold: isBold,
            italic: isItalic,
            fontSize: fontSize,
            color: color,
          ));
        }

        if (i < parts.length - 1) {
          int? header;
          final headerVal = attrs?['header'];
          if (headerVal is int) {
            header = headerVal;
          } else if (headerVal != null) {
            header = int.tryParse(headerVal.toString());
          }

          final align = attrs?['align']?.toString();
          final listVal = attrs?['list']?.toString();
          final isBullet = listVal == 'bullet';
          final isNumbered = listVal == 'ordered';

          lines.add(_NoteLine(
            spans: List.from(currentSpans),
            header: header,
            align: align,
            isBullet: isBullet,
            isNumbered: isNumbered,
          ));
          currentSpans.clear();
        }
      }
    }

    if (currentSpans.isNotEmpty) {
      lines.add(_NoteLine(spans: currentSpans));
    }

    return lines;
  }

  static List<_NoteLine> _splitLongLine(_NoteLine line, {int maxChunkChars = 220}) {
    if (line.isEmpty || line.header != null) {
      return [line];
    }
    final totalLen = line.spans.fold<int>(0, (sum, s) => sum + s.text.length);
    if (totalLen <= maxChunkChars) {
      return [line];
    }

    final chunks = <_NoteLine>[];
    var currentSpans = <_NoteSpan>[];
    int currentLen = 0;

    for (final span in line.spans) {
      if (currentLen + span.text.length <= maxChunkChars) {
        currentSpans.add(span);
        currentLen += span.text.length;
      } else {
        final words = span.text.split(' ');
        var subText = '';
        for (final word in words) {
          if ((currentLen + subText.length + word.length) > maxChunkChars && subText.isNotEmpty) {
            currentSpans.add(_NoteSpan(
              text: subText,
              bold: span.bold,
              italic: span.italic,
              fontSize: span.fontSize,
              color: span.color,
            ));
            chunks.add(_NoteLine(
              spans: List.from(currentSpans),
              header: line.header,
              align: line.align,
              isBullet: chunks.isEmpty ? line.isBullet : false,
              isNumbered: chunks.isEmpty ? line.isNumbered : false,
            ));
            currentSpans.clear();
            currentLen = 0;
            subText = word;
          } else {
            subText = subText.isEmpty ? word : '$subText $word';
          }
        }
        if (subText.isNotEmpty) {
          currentSpans.add(_NoteSpan(
            text: subText,
            bold: span.bold,
            italic: span.italic,
            fontSize: span.fontSize,
            color: span.color,
          ));
          currentLen += subText.length;
        }
      }
    }

    if (currentSpans.isNotEmpty) {
      chunks.add(_NoteLine(
        spans: currentSpans,
        header: line.header,
        align: line.align,
        isBullet: chunks.isEmpty ? line.isBullet : false,
        isNumbered: chunks.isEmpty ? line.isNumbered : false,
      ));
    }

    return chunks.isNotEmpty ? chunks : [line];
  }

  static Future<pw.Widget> _buildRichImageText(
    _NoteLine line, {
    double baseFontSize = 11.0,
    double maxWidth = 520,
  }) async {
    if (line.isEmpty) {
      return pw.SizedBox(height: 6);
    }

    final inlineSpans = <material.InlineSpan>[];
    var lineHasArabic = false;

    // Line-level header styling
    double lineFontSize = baseFontSize;
    bool lineBold = false;
    if (line.header == 1) {
      lineFontSize = 18.0;
      lineBold = true;
    } else if (line.header == 2) {
      lineFontSize = 15.0;
      lineBold = true;
    } else if (line.header == 3) {
      lineFontSize = 13.0;
      lineBold = true;
    }

    if (line.isBullet) {
      inlineSpans.add(
        material.TextSpan(
          text: '•  ',
          style: material.TextStyle(
            fontSize: lineFontSize * 3.0,
            fontWeight: material.FontWeight.bold,
            fontFamily: 'BengaliSolaiman',
          ),
        ),
      );
    }

    for (final span in line.spans) {
      if (span.text.isEmpty) continue;
      final isUrdu = RegExp(r'[\u067E\u0686\u0698\u06AF\u06D2\u0688\u0691\u0679\u06BA\u06C1\u06BE]').hasMatch(span.text);
      final isArabic = RegExp(r'[\u0600-\u06FF\u0750-\u077F]').hasMatch(span.text);
      if (isArabic || isUrdu) lineHasArabic = true;

      String fontToUse = 'BengaliSolaiman';
      if (isUrdu) {
        fontToUse = 'UrduNastaleeq';
      } else if (isArabic) {
        fontToUse = 'ArabicMyLotus';
      }

      final spanFontSize = (span.fontSize ?? lineFontSize) * 3.0;
      final spanBold = span.bold || lineBold;

      inlineSpans.add(
        material.TextSpan(
          text: span.text,
          style: material.TextStyle(
            color: span.color ?? material.Colors.black,
            fontSize: spanFontSize,
            fontWeight: spanBold ? material.FontWeight.bold : material.FontWeight.normal,
            fontStyle: span.italic ? material.FontStyle.italic : material.FontStyle.normal,
            fontFamily: fontToUse,
            fontFamilyFallback: const [
              'ArabicMyLotus',
              'ArabicUthmanic',
              'UrduNastaleeq',
              'BengaliSolaiman',
            ],
            height: 1.35,
          ),
        ),
      );
    }

    if (inlineSpans.isEmpty) {
      return pw.SizedBox(height: 6);
    }

    material.TextAlign textAlign = material.TextAlign.left;
    pw.Alignment alignment = pw.Alignment.centerLeft;
    if (line.align == 'center') {
      textAlign = material.TextAlign.center;
      alignment = pw.Alignment.center;
    } else if (line.align == 'right') {
      textAlign = material.TextAlign.right;
      alignment = pw.Alignment.centerRight;
    }

    final textPainter = material.TextPainter(
      text: material.TextSpan(children: inlineSpans),
      textAlign: textAlign,
      textDirection: lineHasArabic ? material.TextDirection.rtl : material.TextDirection.ltr,
    );

    textPainter.layout(maxWidth: maxWidth * 3.0);

    if (textPainter.width == 0 || textPainter.height == 0) {
      return pw.SizedBox();
    }

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

    final displayWidth = textPainter.width / 3.0;
    final displayHeight = textPainter.height / 3.0;

    return pw.Container(
      alignment: alignment,
      margin: pw.EdgeInsets.only(
        bottom: line.header != null ? 8 : (line.isBullet ? 3 : 4),
      ),
      child: pw.Image(
        memImage,
        width: displayWidth,
        height: displayHeight,
        fit: pw.BoxFit.contain,
      ),
    );
  }

  /// Shares or prints a single teacher note with beautiful branding and Bengali typography
  static Future<void> shareOrPrintNote(TeacherNote note, {required bool isShare}) async {
    final pdf = pw.Document();
    final (logoImage, calligImage) = await _loadBrandingImages();

    final headerTitleWidget = await _buildImageText('ব্যক্তিগত নোট', fontSize: 16, bold: true, alignment: pw.Alignment.centerRight);
    final dateStr = 'তারিখ: ${DateFormat('dd MMMM yyyy, hh:mm a').format(note.updatedAt)}';
    final headerDateWidget = await _buildImageText(dateStr, fontSize: 8.5, color: material.Colors.grey.shade700, alignment: pw.Alignment.centerRight);

    final titleHeaderColumn = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        headerTitleWidget,
        pw.SizedBox(height: 2),
        headerDateWidget,
      ],
    );

    final noteTitle = note.title.trim();
    final noteTitleWidget = noteTitle.isNotEmpty
        ? await _buildImageText(noteTitle, fontSize: 16, bold: true, maxWidth: 516)
        : null;

    pw.Widget? bookWidget;
    if (note.linkedBookAccessionNo != null && note.linkedBookAccessionNo!.isNotEmpty) {
      bookWidget = await _buildImageText('সম্পর্কিত কিতাব নং: ${note.linkedBookAccessionNo}', fontSize: 9.5, color: material.Colors.teal.shade800, maxWidth: 516);
    }

    final parsedLines = _parseNoteContent(note.content);
    final paragraphWidgets = <pw.Widget>[];

    for (final rawLine in parsedLines) {
      final subLines = _splitLongLine(rawLine);
      for (final line in subLines) {
        final w = await _buildRichImageText(line, baseFontSize: 11.0, maxWidth: 516);
        paragraphWidgets.add(w);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(
          left: 36,
          top: 36,
          right: 36,
          bottom: 86,
        ),
        build: (pw.Context context) {
          return [
            _buildHeader(logoImage, calligImage, titleHeaderColumn),
            if (noteTitleWidget != null) ...[
              noteTitleWidget,
              pw.SizedBox(height: 6),
            ],
            if (bookWidget != null) ...[
              bookWidget,
              pw.SizedBox(height: 8),
            ],
            pw.SizedBox(height: 6),
            ...paragraphWidgets,
          ];
        },
      ),
    );

    final filename = '${noteTitle.replaceAll(RegExp(r'[^\w\s\u0980-\u09FF]'), '_')}.pdf';
    if (isShare) {
      await Printing.sharePdf(bytes: await pdf.save(), filename: filename);
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: filename,
        format: PdfPageFormat.a4,
      );
    }
  }
}
