import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/book_providers.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/csv_book_import_service.dart';
import '../../../../core/services/csv_file_picker_helper.dart';
import '../../../../core/theme/neu_card.dart';
import 'book_list_page.dart';

class CsvImportBooksPage extends ConsumerStatefulWidget {
  const CsvImportBooksPage({super.key});

  @override
  ConsumerState<CsvImportBooksPage> createState() => _CsvImportBooksPageState();
}

class _CsvImportBooksPageState extends ConsumerState<CsvImportBooksPage> {
  final CsvBookImportService _importService = CsvBookImportService();

  bool _isAnalyzing = false;
  bool _isImporting = false;
  int _importProgressCurrent = 0;
  int _importProgressTotal = 0;

  String? _pickedFileName;
  int? _pickedFileSize;
  CsvImportPreviewResult? _previewResult;
  bool _showAllErrors = false;

  /// Lets the user pick a .csv file from device storage or web browser.
  Future<void> _pickAndAnalyzeCsv() async {
    try {
      final picked = await pickCsvFile();
      if (picked == null) return;

      setState(() {
        _isAnalyzing = true;
        _pickedFileName = picked.name;
        _pickedFileSize = picked.size;
        _previewResult = null;
      });

      final csvContent = CsvBookImportService.decodeCsvBytes(picked.bytes);
      final preview = await _importService.analyzeCsv(csvContent);

      if (mounted) {
        setState(() {
          _previewResult = preview;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ফাইল প্রসেস করতে ত্রুটি হয়েছে: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Lets the user directly paste CSV content from clipboard / Google Sheets.
  Future<void> _showPasteCsvDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.paste_rounded, color: Color(0xFF1F9E5C)),
            SizedBox(width: 8),
            Text('CSV টেক্সট পেস্ট করুন'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'গুগল শিট থেকে কপি করা রো এবং কলামগুলো নিচের বক্সে পেস্ট করুন:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'accession_no,book_name,volume_no,author...\n1001,সহীহ বুখারী,১,ইমাম বুখারী...',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F9E5C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('যাচাই করুন'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _isAnalyzing = true;
        _pickedFileName = 'ক্লিপবোর্ড থেকে পেস্ট করা টেক্সট';
        _pickedFileSize = result.length;
        _previewResult = null;
      });

      final preview = await _importService.analyzeCsv(result);
      if (mounted) {
        setState(() {
          _previewResult = preview;
          _isAnalyzing = false;
        });
      }
    }
  }

  /// Executes batch upsert into SQLite and Supabase with progress tracking.
  Future<void> _executeImport() async {
    final preview = _previewResult;
    if (preview == null || preview.validBooks.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFF1F9E5C)),
            SizedBox(width: 8),
            Text('ইম্পোর্ট নিশ্চিতকরণ'),
          ],
        ),
        content: Text(
          'মোট ${preview.validBooks.length}টি কিতাব (${preview.newBooks.length}টি নতুন ও ${preview.updateBooks.length}টি আপডেট) ডাটাবেসে সেভ করা হবে। আপনি কি নিশ্চিত?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F9E5C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('হ্যাঁ, সেভ করুন'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isImporting = true;
      _importProgressCurrent = 0;
      _importProgressTotal = preview.validBooks.length;
    });

    try {
      final bookRepo = ref.read(bookRepositoryProvider);
      await bookRepo.batchUpsertBooks(
        preview.validBooks,
        onProgress: (current, total) {
          if (mounted) {
            setState(() {
              _importProgressCurrent = current;
              _importProgressTotal = total;
            });
          }
        },
      );

      // Refresh all providers across the app
      refreshAllBookProviders(ref);

      if (mounted) {
        setState(() {
          _isImporting = false;
        });

        _showSuccessDialog(preview.validBooks.length);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ইম্পোর্ট করার সময় ত্রুটি ঘটেছে: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Displays success modal with options to view the updated book list.
  void _showSuccessDialog(int count) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF1F9E5C),
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'আলহামদুলিল্লাহ!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'সফলভাবে $count টি কিতাব লাইব্রেরিতে যুক্ত ও আপডেট করা হয়েছে।',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _pickedFileName = null;
                        _pickedFileSize = null;
                        _previewResult = null;
                      });
                    },
                    child: const Text('আরও ইম্পোর্ট'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F9E5C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookListPage(
                            isAdmin: true,
                            canViewInventoryStatus: true,
                          ),
                        ),
                      );
                    },
                    child: const Text('কিতাব তালিকা'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'কিতাব বাল্ক ইম্পোর্ট (.csv)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // ─── 1. Instructions & Sample Card ─────────────────────────────
            _buildInstructionsCard(context, colorScheme, isDark),
            const SizedBox(height: 16),

            // ─── 2. File Picker Dropzone ──────────────────────────────────
            _buildFilePickerSection(context, colorScheme, isDark),
            const SizedBox(height: 16),

            // ─── 3. Progress or Analyzing Indicator ───────────────────────
            if (_isAnalyzing) ...[
              NeuCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'CSV ফাইলটি বিশ্লেষণ ও যাচাই করা হচ্ছে...',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ─── 4. Analysis Summary & Errors ─────────────────────────────
            if (_previewResult != null) ...[
              _buildSummaryMetrics(context, colorScheme, _previewResult!),
              const SizedBox(height: 16),

              if (_previewResult!.hasErrors) ...[
                _buildErrorsCard(context, colorScheme, _previewResult!),
                const SizedBox(height: 16),
              ],

              // ─── 5. Data Preview Table ─────────────────────────────────
              if (_previewResult!.hasValidBooks) ...[
                _buildDataPreviewCard(context, colorScheme, _previewResult!),
                const SizedBox(height: 20),
              ],
            ],

            // ─── 6. Import Action Button or Progress ───────────────────────
            if (_isImporting) ...[
              _buildImportProgressBar(colorScheme),
              const SizedBox(height: 20),
            ] else if (_previewResult != null && _previewResult!.hasValidBooks) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F9E5C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: _executeImport,
                icon: const Icon(Icons.cloud_upload_rounded, size: 22),
                label: Text(
                  'সবগুলো (${_previewResult!.validBooks.length}টি) কিতাব সেভ করুন',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F9E5C).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFF1F9E5C),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'গুগল শিট থেকে যুক্ত করার নিয়ম',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '১. গুগল শিটে কিতাবের তালিকা প্রস্তুত করুন। কলামগুলোর নাম বাংলায় (যেমন: কিতাব নম্বর, কিতাবের নাম, লেখক, খণ্ড, ইত্যাদি) বা ইংরেজিতে (accession_no, book_name, author, ইত্যাদি) রাখতে পারেন।\n'
            '২. গুগল শিট থেকে File > Download > Comma Separated Values (.csv) হিসেবে ডাউনলোড করে আপলোড করতে পারেন, অথবা সরাসরি শিট থেকে কিতাবের সারিগুলো কপি করে নিচের "সরাসরি টেক্সট পেস্ট" বাটনে পেস্ট করতে পারেন।\n'
            '৩. কিতাবগুলো স্বয়ংক্রিয়ভাবে লোকাল ডাটাবেস ও ক্লাউডে যুক্ত হয়ে যাবে।',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: colorScheme.onSurface.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePickerSection(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final hasFile = _pickedFileName != null;

    return NeuCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: hasFile
                  ? const Color(0xFF1F9E5C).withOpacity(0.15)
                  : colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasFile ? Icons.file_present_rounded : Icons.file_upload_outlined,
              color: hasFile ? const Color(0xFF1F9E5C) : colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          if (hasFile) ...[
            Text(
              _pickedFileName!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _pickedFileSize != null
                  ? '${(_pickedFileSize! / 1024).toStringAsFixed(1)} KB'
                  : '',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isImporting ? null : _pickAndAnalyzeCsv,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('অন্য ফাইল নির্বাচন করুন'),
            ),
          ] else ...[
            const Text(
              'গুগল শিটের .csv ফাইলটি আপলোড করুন',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ফাইলে কিতাব নম্বর ও কিতাবের নাম থাকা আবশ্যক',
              style: TextStyle(
                fontSize: 12.5,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isImporting ? null : _pickAndAnalyzeCsv,
                  icon: const Icon(Icons.folder_open_rounded, size: 20),
                  label: const Text(
                    'CSV ফাইল নির্বাচন করুন',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isImporting ? null : _showPasteCsvDialog,
                  icon: const Icon(Icons.paste_rounded, size: 18),
                  label: const Text(
                    'সরাসরি টেক্সট পেস্ট',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryMetrics(
    BuildContext context,
    ColorScheme colorScheme,
    CsvImportPreviewResult preview,
  ) {
    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ফাইল বিশ্লেষণ ফলাফল',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'মোট কিতাব',
                  count: preview.totalDataRows,
                  icon: Icons.menu_book_rounded,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'নতুন যুক্ত হবে',
                  count: preview.newBooks.length,
                  icon: Icons.add_circle_outline_rounded,
                  color: const Color(0xFF1F9E5C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'আপডেট হবে',
                  count: preview.updateBooks.length,
                  icon: Icons.update_rounded,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'ত্রুটি / বাদ',
                  count: preview.errors.length,
                  icon: Icons.warning_amber_rounded,
                  color: preview.hasErrors ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorsCard(
    BuildContext context,
    ColorScheme colorScheme,
    CsvImportPreviewResult preview,
  ) {
    final displayedErrors =
        _showAllErrors ? preview.errors : preview.errors.take(3).toList();

    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                'ত্রুটিপূর্ণ লাইনসমূহ (${preview.errors.length}টি)',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'এই লাইনগুলোতে প্রয়োজনীয় তথ্য অসম্পূর্ণ থাকায় এগুলো বাদ দেওয়া হবে:',
            style: TextStyle(
              fontSize: 12.5,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 10),
          ...displayedErrors.map(
            (e) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Text(
                '• লাইন ${e.rowNumber}: ${e.reason}',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
          ),
          if (preview.errors.length > 3) ...[
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() => _showAllErrors = !_showAllErrors);
                },
                child: Text(
                  _showAllErrors
                      ? 'সংক্ষেপ করুন'
                      : 'সবগুলো (${preview.errors.length}টি) ত্রুটি দেখুন',
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataPreviewCard(
    BuildContext context,
    ColorScheme colorScheme,
    CsvImportPreviewResult preview,
  ) {
    final previewBooks = preview.validBooks.take(10).toList();

    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'কিতাব তালিকা প্রিভিউ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'প্রথম ${previewBooks.length}টি কিতাব',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: previewBooks.length,
            separatorBuilder: (_, __) => Divider(
              height: 12,
              color: colorScheme.onSurface.withOpacity(0.08),
            ),
            itemBuilder: (context, idx) {
              final b = previewBooks[idx];
              final isUpdate = preview.updateBooks.contains(b);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUpdate
                          ? Colors.orange.withOpacity(0.12)
                          : const Color(0xFF1F9E5C).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'নং ${b.accessionNo}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isUpdate ? Colors.orange[800] : const Color(0xFF1F9E5C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.bookName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (b.volumeNo != null && b.volumeNo!.isNotEmpty)
                              'খণ্ড: ${b.volumeNo}',
                            if (b.author != null && b.author!.isNotEmpty)
                              'লেখক: ${b.author}',
                            if (b.subjectCategory != null &&
                                b.subjectCategory!.isNotEmpty)
                              'বিষয়: ${b.subjectCategory}',
                            if (b.shelfNo != null && b.shelfNo!.isNotEmpty)
                              'শেলফ: ${b.shelfNo}',
                          ].join(' • '),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colorScheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isUpdate
                          ? Colors.orange.withOpacity(0.15)
                          : const Color(0xFF1F9E5C).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isUpdate ? 'আপডেট' : 'নতুন',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isUpdate ? Colors.orange[800] : const Color(0xFF1F9E5C),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          if (preview.validBooks.length > 10) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                '...এবং আরও ${preview.validBooks.length - 10}টি কিতাব সফলভাবে প্রস্তুত রয়েছে',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImportProgressBar(ColorScheme colorScheme) {
    final progress = _importProgressTotal > 0
        ? _importProgressCurrent / _importProgressTotal
        : 0.0;

    return NeuCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'কিতাবসমূহ সেভ হচ্ছে...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                '$_importProgressCurrent / $_importProgressTotal',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F9E5C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1F9E5C)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'অনুগ্রহ করে অপেক্ষা করুন, লোকাল ডাটাবেস ও ক্লাউডে সিঙ্ক সম্পন্ন হচ্ছে...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
