import 'package:flutter/material.dart';
import '../../../../core/widgets/madrasa_app_bar_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/providers/book_providers.dart';
import '../../../../core/providers/transaction_providers.dart';
import '../../../../core/providers/user_providers.dart';
import '../../../../core/widgets/dynamic_font_text.dart';
import 'package:maktaba_ihsan/core/providers/auth_provider.dart';
import 'package:maktaba_ihsan/core/providers/settings_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/book_model.dart';

class AddEditTransactionPage extends ConsumerStatefulWidget {
  final LibraryTransaction? transaction;
  final String? prefilledUserId;

  const AddEditTransactionPage(
      {super.key, this.transaction, this.prefilledUserId});

  @override
  ConsumerState<AddEditTransactionPage> createState() =>
      _AddEditTransactionPageState();
}

class _AddEditTransactionPageState
    extends ConsumerState<AddEditTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _bookIdController;
  late TextEditingController _userIdController;
  late TextEditingController _issueDateController;
  late TextEditingController _expectedReturnController;
  late TextEditingController _actualReturnController;

  TransactionStatus _selectedStatus = TransactionStatus.active;
  DateTime _issueDate = DateTime.now();
  DateTime _expectedReturn = DateTime.now()
      .add(const Duration(days: 365)); // Default to 1 year since UI is hidden
  DateTime? _actualReturn;

  bool _sendWhatsapp = true;

  String _currentBookId = '';
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    final isEdit = widget.transaction != null;

    if (isEdit) {
      _issueDate = widget.transaction!.issueDate;
      _expectedReturn = widget.transaction!.expectedReturn;
      _actualReturn = widget.transaction!.actualReturn;
      _selectedStatus = widget.transaction!.status;
    }

    _bookIdController = TextEditingController(
        text: isEdit ? widget.transaction!.accessionNo : '');
    _userIdController = TextEditingController(
        text: isEdit
            ? widget.transaction!.userId
            : (widget.prefilledUserId ?? ''));
    _issueDateController = TextEditingController(text: _formatDate(_issueDate));
    _expectedReturnController =
        TextEditingController(text: _formatDate(_expectedReturn));
    _actualReturnController = TextEditingController(
        text: _actualReturn != null ? _formatDate(_actualReturn!) : '');

    _currentBookId = _bookIdController.text;
    _currentUserId = _userIdController.text;
    _bookIdController.addListener(() {
      setState(() {
        _currentBookId = _bookIdController.text;
      });
    });
    _userIdController.addListener(() {
      setState(() {
        _currentUserId = _userIdController.text;
      });
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  void dispose() {
    _bookIdController.dispose();
    _userIdController.dispose();
    _issueDateController.dispose();
    _expectedReturnController.dispose();
    _actualReturnController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isIssueDate) async {
    final initialDate = isIssueDate ? _issueDate : _expectedReturn;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
          _issueDateController.text = _formatDate(_issueDate);
        } else {
          _expectedReturn = picked;
          _expectedReturnController.text = _formatDate(_expectedReturn);
        }
      });
    }
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final isEdit = widget.transaction != null;
      final repository = ref.read(transactionRepositoryProvider);
      final settings = ref.read(appSettingsProvider);

      try {
        if (!isEdit) {
          // Verify book and user exist before issuing
          final bookRepo = ref.read(bookRepositoryProvider);
          final userRepo = ref.read(userRepositoryProvider);

          final bookId = _bookIdController.text.trim();
          final book = await bookRepo.getBookByAccessionNo(bookId);
          if (book == null) {
            _showError('কিতাব পাওয়া যায়নি। কিতাব নম্বর চেক করুন।');
            return;
          }

          // Check if book is already lent out
          final activeTx = await repository.getActiveTransactionForBook(bookId);
          if (activeTx != null || book.status == BookStatus.lent) {
            final borrower = activeTx?.userName != null
                ? '${activeTx!.userName} (সদস্য আইডি: ${activeTx.userId})'
                : (activeTx?.userId != null
                    ? 'সদস্য আইডি: ${activeTx!.userId}'
                    : 'অন্য একজন শিক্ষক');
            _showError(
                'এই কিতাবটি বর্তমানে $borrower এর কাছে ধার দেওয়া রয়েছে। ফেরত নেওয়ার পূর্বে এটি পুনরায় ধার দেওয়া যাবে না।');
            return;
          }

          final user =
              await userRepo.getUserById(_userIdController.text.trim());
          if (user == null) {
            _showError('সদস্য পাওয়া যায়নি। মেম্বার আইডি চেক করুন।');
            return;
          }

          final result = await repository.issueBook(
            bookId,
            _userIdController.text.trim(),
            _expectedReturn,
          );

          if (result == null) {
            _showError('কিতাবটি পাওয়া যায়নি বা বর্তমানে ধার দেওয়া সম্ভব নয়।');
            return;
          }

          // Whatsapp message logic for non-admins (teachers)
          final authState = ref.read(authProvider);
          final isAdmin = authState.userType == UserType.admin;
          if (!isAdmin && _sendWhatsapp) {
            String? adminPhone = settings.adminWhatsAppNumber;
            if (adminPhone == null || adminPhone.trim().isEmpty) {
              final db = await ref.read(databaseHelperProvider).database;
              final rows = await db.rawQuery("SELECT phone FROM users WHERE LOWER(type) = 'admin' AND phone IS NOT NULL AND TRIM(phone) != '' LIMIT 1");
              if (rows.isNotEmpty) {
                adminPhone = rows.first['phone']?.toString();
              }
            }
            if (adminPhone != null && adminPhone.isNotEmpty) {
              final formattedPhone = adminPhone.replaceAll(RegExp(r'[^0-9]'), '');
              final String message = "আসসালামু আলাইকুম।\nআমি '${book.bookName}' কিতাবটির জন্য রিকোয়েস্ট পাঠিয়েছি।\nআমার আইডি: ${user.userId}\nনাম: ${user.name}";
              final url = Uri.parse("whatsapp://send?phone=$formattedPhone&text=${Uri.encodeComponent(message)}");
              // Using try-catch around url_launcher so it doesn't break if whatsapp not installed
              try {
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  final fallbackUrl = Uri.parse("https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}");
                  await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
                }
              } catch (_) {}
            }
          }
        } else {
          // Edit existing transaction
          if (_selectedStatus == TransactionStatus.returned &&
              widget.transaction!.status != TransactionStatus.returned) {
            await repository.returnBook(widget.transaction!.trxId);
          } else if (_selectedStatus == TransactionStatus.active &&
              widget.transaction!.status == TransactionStatus.requested) {
            // Approve Request logic
            await repository.approveRequest(
                widget.transaction!.trxId, _issueDate, _expectedReturn);
          }
        }

        // Refresh lists
        ref.invalidate(allTransactionsProvider);
        ref.invalidate(transactionsListProvider);

        ref.invalidate(bookRepositoryProvider);
        ref.invalidate(
            bookSearchResultsProvider); // Because book status changed
        ref.invalidate(userRepositoryProvider); // if needed

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('লেনদেন সফলভাবে সম্পন্ন হয়েছে')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        _showError('ত্রুটি: $e');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transaction != null;
    final t = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 96,
        title: MadrasaAppBarTitle(
            title: isEdit ? t.editTransaction : t.addTransaction),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('ডিলিট করুন'),
                    content: const Text(
                        'আপনি কি নিশ্চিত যে এই রিকোয়েস্ট বা লেনদেনটি ডিলিট করতে চান?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('বাতিল করুন'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('ডিলিট',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  try {
                    await ref
                        .read(transactionRepositoryProvider)
                        .deleteTransaction(widget.transaction!.trxId);
                    ref.read(syncQueueProvider.notifier).processQueue();
                    ref.invalidate(allTransactionsProvider);
                    ref.invalidate(transactionsListProvider);
                    ref.invalidate(
                        userTransactionsProvider(widget.transaction!.userId));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('সফলভাবে ডিলিট করা হয়েছে')),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    _showError('ডিলিট করতে সমস্যা হয়েছে: $e');
                  }
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _bookIdController,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: t.bookAccessionNo,
                labelStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                border: const OutlineInputBorder(),
                disabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
              ),
              enabled: !isEdit,
              validator: (value) =>
                  value == null || value.isEmpty ? t.required : null,
            ),
            if (_currentBookId.isNotEmpty) ...[
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, child) {
                  final bookAsync =
                      ref.watch(bookByAccessionNoProvider(_currentBookId));
                  final activeTxAsync =
                      ref.watch(activeBookTransactionProvider(_currentBookId));

                  return bookAsync.when(
                    data: (book) {
                      if (book == null) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Text(t.bookNotFound,
                                  style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                        );
                      }

                      final activeTx = activeTxAsync.value;
                      final isLent = book.status == BookStatus.lent || activeTx != null;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isLent
                              ? (isDark
                                  ? const Color(0xFF331515)
                                  : Colors.red.withOpacity(0.08))
                              : (isDark
                                  ? const Color(0xFF162B21)
                                  : Colors.green.withOpacity(0.08)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isLent
                                ? Colors.red.withOpacity(0.4)
                                : (isDark
                                    ? const Color(0xFF2E6B47)
                                    : Colors.green.withOpacity(0.3)),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DynamicFontText(
                              book.bookName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isLent
                                    ? Colors.red
                                    : (isDark
                                        ? const Color(0xFF5BE29B)
                                        : Colors.green.shade800),
                              ),
                            ),
                            if (book.volumeNo != null && book.volumeNo!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.format_list_numbered,
                                      size: 14,
                                      color: isDark ? Colors.white60 : Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    'খণ্ড: ${book.volumeNo!.toEnglishNumerals}',
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (book.author != null && book.author!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.person_outline,
                                      size: 14,
                                      color: isDark ? Colors.white60 : Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: DynamicFontText(
                                      book.author!,
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (book.publisher != null && book.publisher!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.business_outlined,
                                      size: 14,
                                      color: isDark ? Colors.white60 : Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: DynamicFontText(
                                      book.publisher!,
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (isLent) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withOpacity(0.4)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'এই কিতাবটি বর্তমানে ধার দেওয়া রয়েছে!',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (activeTx != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'গ্রহীতা: ${activeTx.userName ?? 'সদস্য'} (আইডি: ${activeTx.userId})',
                                              style: TextStyle(
                                                color: isDark ? Colors.red.shade200 : Colors.red.shade900,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    loading: () => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 10),
                          Text(t.searching),
                        ],
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _userIdController,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: t.memberId,
                labelStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                border: const OutlineInputBorder(),
                disabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
              ),
              enabled: !isEdit && widget.prefilledUserId == null,
              validator: (value) =>
                  value == null || value.isEmpty ? t.required : null,
            ),
            if (_currentUserId.isNotEmpty) ...[
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, child) {
                  final userAsync = ref.watch(userByIdProvider(_currentUserId));
                  return userAsync.when(
                    data: (user) {
                      final displayName = user?.name ?? widget.transaction?.userName;
                      if (displayName == null || displayName.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Text('সদস্য আইডি: $_currentUserId',
                                  style: const TextStyle(color: Colors.orange, fontSize: 13)),
                            ],
                          ),
                        );
                      }
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF162B21)
                              : colorScheme.primaryContainer.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF2E6B47)
                                : colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isDark
                                      ? const Color(0xFF1E3F2E)
                                      : colorScheme.primary.withOpacity(0.15),
                                  child: Icon(
                                    user?.type == UserType.teacher ? Icons.school_rounded : Icons.person,
                                    size: 18,
                                    color: isDark ? const Color(0xFF5BE29B) : colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isDark ? const Color(0xFF5BE29B) : colorScheme.primary,
                                        ),
                                      ),
                                      if (user?.type != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          user!.type == UserType.teacher
                                              ? 'শিক্ষক'
                                              : (user.type == UserType.student ? 'ছাত্র' : 'সদস্য'),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.white70 : colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (user?.phone != null && user!.phone!.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.phone_outlined,
                                      size: 14,
                                      color: isDark ? Colors.white60 : Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    user.phone!,
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    loading: () => widget.transaction?.userName != null
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF162B21)
                                  : colorScheme.primaryContainer.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF2E6B47)
                                    : colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.person,
                                    color: isDark ? const Color(0xFF5BE29B) : colorScheme.primary,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  widget.transaction!.userName!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFF5BE29B) : colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2)),
                                const SizedBox(width: 10),
                                Text(t.searching),
                              ],
                            ),
                          ),
                    error: (_, __) => widget.transaction?.userName != null
                        ? Text('নাম: ${widget.transaction!.userName!}')
                        : const SizedBox.shrink(),
                  );
                },
              ),
            ],
            if (!isEdit) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _issueDateController,
                decoration: InputDecoration(
                  labelText: t.issueDate,
                  border: const OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () => _selectDate(context, true),
              ),
            ],
            if (isEdit) ...[
              if (widget.transaction!.status ==
                  TransactionStatus.requested) ...[
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = TransactionStatus.active;
                      _issueDate = DateTime.now();
                      _expectedReturn =
                          DateTime.now().add(const Duration(days: 7));
                    });
                    _saveTransaction();
                  },
                  icon: const Icon(Icons.check_circle),
                  label: Text(t.requestApprovedIssue),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('রিকোয়েস্ট বাতিল করবেন?'),
                        content: const Text(
                            'এই রিকোয়েস্টটি মুছে ফেলা হবে এবং শিক্ষক পুনরায় রিকোয়েস্ট পাঠাতে পারবেন।'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('না'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('হ্যাঁ, বাতিল করুন'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted) {
                      try {
                        await ref
                            .read(transactionRepositoryProvider)
                            .deleteTransaction(widget.transaction!.trxId);
                        ref.read(syncQueueProvider.notifier).processQueue();
                        ref.invalidate(allTransactionsProvider);
                        ref.invalidate(transactionsListProvider);
                        ref.invalidate(userTransactionsProvider(
                            widget.transaction!.userId));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('রিকোয়েস্ট বাতিল ও মুছে ফেলা হয়েছে'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        Navigator.pop(context);
                      } catch (e) {
                        _showError('রিকোয়েস্ট বাতিল করতে সমস্যা হয়েছে: $e');
                      }
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: const Text(
                    'রিকোয়েস্ট বাতিল / কেটে দিন',
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ] else if (widget.transaction!.status ==
                      TransactionStatus.active ||
                  widget.transaction!.status == TransactionStatus.overdue) ...[
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = TransactionStatus.returned;
                    });
                    _saveTransaction();
                  },
                  icon: const Icon(Icons.keyboard_return),
                  label: Text(t.bookReturned),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ] else if (widget.transaction!.status ==
                  TransactionStatus.returned) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(t.bookReturned,
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final authState = ref.watch(authProvider);
                  final isAdmin = authState.userType == UserType.admin;
                  if (!isAdmin) {
                    return Column(
                      children: [
                        CheckboxListTile(
                          title: const Text('অ্যাডমিনকে হোয়াটসঅ্যাপে মেসেজ পাঠান'),
                          value: _sendWhatsapp,
                          onChanged: (val) => setState(() => _sendWhatsapp = val ?? true),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }
              ),
              Consumer(
                builder: (context, ref, child) {
                  final activeTxAsync = ref.watch(activeBookTransactionProvider(_currentBookId));
                  final bookAsync = ref.watch(bookByAccessionNoProvider(_currentBookId));
                  final isLent = !isEdit && _currentBookId.trim().isNotEmpty && (
                    bookAsync.value?.status == BookStatus.lent ||
                    activeTxAsync.value != null
                  );

                  return FilledButton(
                    onPressed: isLent ? null : _saveTransaction,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isLent ? Colors.grey : null,
                    ),
                    child: Text(
                      isLent ? 'কিতাবটি ধার দেওয়া অবস্থায় আছে' : t.addTransaction,
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
