import 'package:flutter/material.dart';
import '../../../../core/widgets/madrasa_app_bar_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maktaba_ihsan/features/books/presentation/pages/book_list_page.dart';
import 'package:maktaba_ihsan/core/providers/auth_provider.dart';
import 'package:maktaba_ihsan/features/auth/presentation/pages/login_page.dart';
import 'package:maktaba_ihsan/core/providers/providers.dart';
import 'package:maktaba_ihsan/core/providers/book_providers.dart';
import 'package:maktaba_ihsan/core/providers/user_providers.dart';

import 'package:maktaba_ihsan/features/users/presentation/pages/user_list_page.dart';
import 'package:maktaba_ihsan/features/transactions/presentation/pages/transaction_list_page.dart';
import 'package:maktaba_ihsan/features/settings/presentation/pages/settings_page.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import 'package:maktaba_ihsan/core/widgets/curved_bottom_nav.dart';
import 'package:maktaba_ihsan/core/services/print_service.dart';
import 'package:maktaba_ihsan/core/providers/book_providers.dart';
import 'package:maktaba_ihsan/core/providers/transaction_providers.dart';
import 'package:maktaba_ihsan/core/models/transaction_model.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  int _selectedIndex = 0;
  bool _isSyncing = false;

  Future<void> _runSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    try {
      // STEP 1: Push any pending local changes to GAS first
      final pendingOps = ref.read(syncQueueProvider);
      if (pendingOps.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${pendingOps.length} টি পরিবর্তন আপলোড হচ্ছে...'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.blue,
            ),
          );
        }
        await ref.read(syncQueueProvider.notifier).processQueue(
              ref.read(apiServiceProvider),
            );
        // Wait a moment for GAS to process the data
        await Future.delayed(const Duration(seconds: 2));
      }

      // STEP 2: Pull latest data from GAS
      final syncService = await ref.read(syncServiceProvider.future);
      final result = await syncService.syncAll();

      // Force refresh UI
      final currentQuery = ref.read(bookSearchQueryProvider);
      ref.read(bookSearchQueryProvider.notifier).state = '__refresh__';
      await Future.delayed(const Duration(milliseconds: 50));
      ref.read(bookSearchQueryProvider.notifier).state = currentQuery;
      ref.invalidate(usersListProvider);

      if (mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('সিঙ্ক সম্পন্ন! ${result.totalSynced} টি রেকর্ড আপডেট।'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (result.isOffline) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ইন্টারনেট সংযোগ নেই।'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('সিঙ্ক ত্রুটি: ${result.errors.values.join(', ')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('সিঙ্ক ব্যর্থ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionsListProvider);
    int pendingCount = txAsync.valueOrNull
            ?.where((t) => t.status == TransactionStatus.requested)
            .length ??
        0;

    final pages = [
      const BookListPage(isAdmin: true),
      const UserListPage(),
      const TransactionListPage(),
      const SettingsPage(),
    ];

    final t = ref.watch(translationProvider);

    final titles = [
      t.bookList,
      t.membersList,
      t.transactionList,
      t.settings,
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AppBar(
            toolbarHeight: 90,
            title: MadrasaAppBarTitle(title: titles[_selectedIndex]),
            actions: [
              if (pendingCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Center(
                    child: Badge(
                      label: Text(pendingCount.toString()),
                      child: IconButton(
                        icon: const Icon(Icons.notifications),
                        tooltip: 'পেন্ডিং রিকোয়েস্ট',
                        onPressed: () {
                          setState(() {
                            _selectedIndex = 2;
                          });
                          ref.read(transactionStatusFilterProvider.notifier).state =
                              TransactionStatus.requested;
                        },
                      ),
                    ),
                  ),
                ),
              _isSyncing
                  ? const Padding(
                      padding: EdgeInsets.all(14.0),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.sync),
                      tooltip: 'গুগল শীট থেকে সিঙ্ক করুন',
                      onPressed: _runSync,
                    ),
              if (_selectedIndex == 2)
                IconButton(
                  icon: const Icon(Icons.print),
                  tooltip: 'প্রিন্ট করুন',
                  onPressed: () async {
                    try {
                      if (_selectedIndex == 2) {
                        final txs =
                            await ref.read(transactionsListProvider.future);
                        await PrintService.printTransactions(txs, t);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('প্রিন্ট করতে সমস্যা হয়েছে: $e')),
                        );
                      }
                    }
                  },
                ),
            ],
          ),
        ),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: CurvedBottomNav(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          CurvedNavItem(
            icon: Icons.book_outlined,
            activeIcon: Icons.book,
            label: t.books,
            gradientColors: const [
              Color(0xFF34d399),
              Color(0xFF059669)
            ], // Green
          ),
          CurvedNavItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: t.members,
            gradientColors: const [
              Color(0xFFc084fc),
              Color(0xFF7c3aed)
            ], // Purple
          ),
          CurvedNavItem(
            icon: Icons.swap_horiz_outlined,
            activeIcon: Icons.swap_horiz,
            label: t.transactions,
            gradientColors: const [
              Color(0xFFfb923c),
              Color(0xFFea580c)
            ], // Orange
          ),
          CurvedNavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: t.settings,
            gradientColors: const [
              Color(0xFFf472b6),
              Color(0xFFdb2777)
            ], // Pink
          ),
        ],
      ),
    );
  }
}
