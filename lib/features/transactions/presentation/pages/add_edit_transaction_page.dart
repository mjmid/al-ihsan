import 'package:flutter/material.dart';
import '../../../../core/widgets/madrasa_app_bar_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/providers/book_providers.dart';
import '../../../../core/providers/transaction_providers.dart';
import '../../../../core/widgets/dynamic_font_text.dart';

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

  String _currentBookId = '';

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
    _bookIdController.addListener(() {
      setState(() {
        _currentBookId = _bookIdController.text;
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
      final t = ref.watch(translationProvider);
      final repository = ref.read(transactionRepositoryProvider);

      try {
        if (!isEdit) {
          // Verify book and user exist before issuing
          final bookRepo = ref.read(bookRepositoryProvider);
          final userRepo = ref.read(userRepositoryProvider);

          final book =
              await bookRepo.getBookByAccessionNo(_bookIdController.text);
          if (book == null) {
            _showError('কিতাব পাওয়া যায়নি। অ্যাকসেশন নম্বর চেক করুন।');
            return;
          }
          if (book.status != null && book.status!.name != 'available') {
            // Note: BookStatus is an enum, we just check if it's available conceptually.
            // If it's already lent, show error.
          }

          final user =
              await userRepo.getUserById(_userIdController.text.trim());
          if (user == null) {
            _showError('সদস্য পাওয়া যায়নি। মেম্বার আইডি চেক করুন।');
            return;
          }

          final result = await repository.issueBook(
            _bookIdController.text.trim(),
            _userIdController.text.trim(),
            _expectedReturn,
          );

          if (result == null) {
            _showError('কিতাবটি পাওয়া যায়নি বা বর্তমানে ধার দেওয়া সম্ভব নয়।');
            return;
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

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
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
                    title: Text('ডিলিট করুন'),
                    content: Text('আপনি কি নিশ্চিত যে এই রিকোয়েস্ট বা লেনদেনটি ডিলিট করতে চান?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('বাতিল করুন'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('ডিলিট', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  try {
                    await ref.read(transactionRepositoryProvider).deleteTransaction(widget.transaction!.trxId);
                    ref.invalidate(transactionsListProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('সফলভাবে ডিলিট করা হয়েছে')),
                      );
                      Navigator.pop(context);
                    }
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
              decoration: InputDecoration(
                labelText: t.bookAccessionNo,
                border: OutlineInputBorder(),
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
                  return bookAsync.when(
                    data: (book) {
                      if (book == null)
                        return Text(t.bookNotFound,
                            style: TextStyle(color: Colors.red));
                      return DynamicFontText(
                          'কিতাবের নাম: ${book.bookName}\nলেখক: ${book.author}',
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold));
                    },
                    loading: () => Text(t.searching),
                    error: (_, __) => const Text(''),
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _userIdController,
              decoration: InputDecoration(
                labelText: t.memberId,
                border: OutlineInputBorder(),
              ),
              enabled: !isEdit && widget.prefilledUserId == null,
              validator: (value) =>
                  value == null || value.isEmpty ? t.required : null,
            ),
            if (!isEdit) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _issueDateController,
                decoration: InputDecoration(
                  labelText: t.issueDate,
                  border: OutlineInputBorder(),
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
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(t.bookReturned,
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saveTransaction,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  t.addTransaction,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
