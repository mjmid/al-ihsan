import 'package:flutter/material.dart';
import '../../../../core/widgets/madrasa_app_bar_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/user_model.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/providers/providers.dart';
import 'package:maktaba_ihsan/core/providers/transaction_providers.dart';
import 'package:maktaba_ihsan/core/providers/book_providers.dart';
import 'package:maktaba_ihsan/core/services/pdf_service.dart';
import 'package:maktaba_ihsan/core/theme/neu_card.dart';
import 'package:maktaba_ihsan/core/theme/neu_button.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import '../../../../core/widgets/dynamic_font_text.dart';
import 'add_edit_user_page.dart';
import '../../../transactions/presentation/pages/add_edit_transaction_page.dart';

class UserDetailPage extends ConsumerStatefulWidget {
  final User user;

  const UserDetailPage({super.key, required this.user});

  @override
  ConsumerState<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends ConsumerState<UserDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUser = widget.user;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshUser() async {
    final updated =
        await ref.read(userRepositoryProvider).getUserById(_currentUser.userId);
    if (updated != null && mounted) {
      setState(() {
        _currentUser = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationProvider);
    final isStudent = _currentUser.type == UserType.student;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        title: MadrasaAppBarTitle(title: t.memberProfile),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final transactionsAsync =
                  ref.watch(userTransactionsProvider(_currentUser.userId));
              return IconButton(
                icon: const Icon(Icons.print),
                tooltip: t.print,
                onPressed: transactionsAsync.isLoading
                    ? null
                    : () async {
                        final allTxs = transactionsAsync.valueOrNull ?? [];
                        if (allTxs.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('প্রিন্ট করার মতো কোনো লেনদেন নেই')),
                          );
                          return;
                        }

                        // Show dialog to ask if returned books should be included
                        bool includeReturned = false;
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) {
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  title: const Text('প্রিন্ট অপশন'),
                                  content: Row(
                                    children: [
                                      Checkbox(
                                        value: includeReturned,
                                        onChanged: (val) {
                                          setState(() => includeReturned = val ?? false);
                                        },
                                      ),
                                      const Expanded(
                                        child: Text('পূর্বে পড়া কিতাবের তালিকা যোগ করুন'),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('বাতিল'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('প্রিন্ট করুন'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        );

                        if (confirm != true) return;

                        final txsToPrint = includeReturned 
                            ? allTxs 
                            : allTxs.where((tx) => tx.status != TransactionStatus.returned).toList();

                        try {
                          await PdfService.printTransactionHistory(
                              _currentUser, txsToPrint, t);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('প্রিন্ট করতে সমস্যা হয়েছে: $e')),
                            );
                          }
                        }
                      },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // User Profile Card
          NeuCard(
            margin: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    _currentUser.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('ID: ${_currentUser.userId}'),
                      if (_currentUser.classJamat?.isNotEmpty == true)
                        Text('${t.classJamat} ${_currentUser.classJamat}'),
                      if (_currentUser.phone?.isNotEmpty == true)
                        Text('${t.phone} ${_currentUser.phone}'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _currentUser.status == UserStatus.active
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _currentUser.status == UserStatus.active
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        child: Text(
                          _currentUser.status == UserStatus.active
                              ? t.active
                              : t.inactive,
                          style: TextStyle(
                            color: _currentUser.status == UserStatus.active
                                ? Colors.green
                                : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddEditUserPage(user: _currentUser),
                      ),
                    );
                    _refreshUser();
                    ref.invalidate(
                        userTransactionsProvider(_currentUser.userId));
                  },
                ),
              ],
            ),
          ),

          // Issue Book Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: NeuButton(
                isPrimary: true,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditTransactionPage(
                          prefilledUserId: _currentUser.userId),
                    ),
                  );
                  ref.invalidate(userTransactionsProvider(_currentUser.userId));
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.library_add,
                        size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(t.issueBook),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: t.currentlyIssued),
              Tab(text: t.returned),
            ],
          ),

          // Tab Views
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final txAsync =
                    ref.watch(userTransactionsProvider(_currentUser.userId));

                return txAsync.when(
                  data: (transactions) {
                    final activeTxs = transactions
                        .where((tx) => tx.status == TransactionStatus.active)
                        .toList();
                    final returnedTxs = transactions
                        .where((tx) => tx.status == TransactionStatus.returned)
                        .toList();

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTransactionList(activeTxs, true, t),
                        _buildTransactionList(returnedTxs, false, t),
                      ],
                    );
                  },
                  loading: () => Center(child: Text(t.loading)),
                  error: (e, st) => Center(child: Text('${t.error}: $e')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<LibraryTransaction> transactions,
      bool isActiveTab, AppTranslations t) {
    if (transactions.isEmpty) {
      return Center(
        child: Text(
            isActiveTab ? 'No books currently issued' : 'No books returned'),
      );
    }

    final dateFormat = DateFormat('dd MMM yyyy');

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isOverdue = tx.isOverdue;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Consumer(
            builder: (context, ref, child) {
              final bookAsync =
                  ref.watch(bookByAccessionNoProvider(tx.accessionNo));
              final bookName = bookAsync.when(
                data: (book) => book?.bookName ?? t.unknownBook,
                loading: () => t.loading,
                error: (_, __) => t.error,
              );

              return NeuCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  title: DynamicFontText(bookName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${tx.accessionNo}'),
                      Text(
                          '${t.issueDate} ${dateFormat.format(tx.issueDate.toLocal())}'),
                      if (!isActiveTab && tx.actualReturn != null)
                        Text(
                            '${t.returnDate} ${dateFormat.format(tx.actualReturn!.toLocal())}'),
                    ],
                  ),
                  trailing: isActiveTab
                      ? NeuButton(
                          onPressed: () => _returnBook(tx.trxId),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text(t.takeReturn),
                        )
                      : null,
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _returnBook(String trxId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('কিতাব ফেরত'),
        content: const Text('আপনি কি নিশ্চিত যে এই কিতাবটি ফেরত নেওয়া হয়েছে?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('না'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('হ্যাঁ'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(transactionRepositoryProvider);
        await repository.returnBook(trxId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('কিতাব সফলভাবে ফেরত নেওয়া হয়েছে।')),
        );
        ref.invalidate(userTransactionsProvider(_currentUser.userId));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ত্রুটি: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
