import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/widgets/madrasa_app_bar_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maktaba_ihsan/features/books/presentation/pages/book_list_page.dart';
import 'package:maktaba_ihsan/core/providers/providers.dart';
import 'package:maktaba_ihsan/core/providers/book_providers.dart';
import 'package:maktaba_ihsan/core/providers/user_providers.dart';

import 'package:maktaba_ihsan/features/users/presentation/pages/user_list_page.dart';
import 'package:maktaba_ihsan/features/transactions/presentation/pages/transaction_list_page.dart';
import 'package:maktaba_ihsan/features/settings/presentation/pages/settings_page.dart';
import 'package:maktaba_ihsan/features/assets/presentation/pages/asset_list_page.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import 'package:maktaba_ihsan/core/widgets/curved_bottom_nav.dart';
import 'package:maktaba_ihsan/core/providers/transaction_providers.dart';
import 'package:maktaba_ihsan/core/models/transaction_model.dart';
import 'package:maktaba_ihsan/core/database/hive_helper.dart';
import 'package:maktaba_ihsan/core/services/supabase_client.dart';
import 'package:maktaba_ihsan/core/services/routine_alarm_service.dart';
import 'package:supabase/supabase.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isSyncing = false;
  bool _isSilentSyncing = false;
  Timer? _heartbeatTimer;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initial silent sync right after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _silentSync();
    });

    // 15-second heartbeat timer for automatic delta sync
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _silentSync();
    });

    // Supabase Realtime channel subscription for instant push updates
    _subscribeRealtime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    _unsubscribeRealtime();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _silentSync();
    }
  }

  void _subscribeRealtime() {
    try {
      _realtimeChannel = supabaseClient.channel('admin_transactions_realtime')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'transactions',
          callback: (payload) {
            _silentSync();
          },
        )
        ..subscribe();
    } catch (e) {
      debugPrint('Realtime subscription error: $e');
    }
  }

  void _unsubscribeRealtime() {
    try {
      if (_realtimeChannel != null) {
        supabaseClient.removeChannel(_realtimeChannel!);
        _realtimeChannel = null;
      }
    } catch (e) {
      debugPrint('Realtime unsubscription error: $e');
    }
  }

  Future<void> _silentSync() async {
    if (_isSilentSyncing || !mounted) return;
    _isSilentSyncing = true;
    try {
      final syncService = await ref.read(syncServiceProvider.future);
      final result = await syncService.syncAll();
      if (result.totalSynced > 0) {
        ref.invalidate(allTransactionsProvider);
        ref.invalidate(transactionsListProvider);
        ref.invalidate(usersListProvider);
        refreshAllBookProviders(ref);
      }
    } catch (e) {
      debugPrint('Silent sync error: $e');
    } finally {
      if (mounted) {
        _isSilentSyncing = false;
      }
    }
  }

  void _checkNewRequests(List<LibraryTransaction> allTxs) {
    final notifiedList = HiveHelper.getSetting<List<dynamic>>(
        'notified_requested_trx_ids', <dynamic>[]);
    final notifiedSet =
        Set<String>.from(notifiedList.map((e) => e.toString()));

    final isFirstRun =
        !HiveHelper.settingsBox.containsKey('notified_requested_trx_ids');
    final requestedTxs = allTxs
        .where((tx) => tx.status == TransactionStatus.requested)
        .toList();

    if (isFirstRun) {
      // First run: silently save existing IDs so we don't alert on app startup
      final initialIds = requestedTxs.map((e) => e.trxId).toList();
      HiveHelper.setSetting('notified_requested_trx_ids', initialIds);
      return;
    }

    final newlyRequested =
        requestedTxs.where((tx) => !notifiedSet.contains(tx.trxId)).toList();

    if (newlyRequested.isNotEmpty) {
      for (final tx in newlyRequested) {
        notifiedSet.add(tx.trxId);
      }
      HiveHelper.setSetting('notified_requested_trx_ids', notifiedSet.toList());

      // Trigger system notification using the phone's set notification tone
      for (final tx in newlyRequested) {
        RoutineAlarmService.showBookRequestedNotification(
          teacherName: tx.userName ?? 'একজন ওস্তাদ',
          bookTitle: tx.bookName ?? 'কিতাব',
          trxId: tx.trxId,
        );
      }

      if (mounted) {
        final firstReq = newlyRequested.first;
        final extraCount = newlyRequested.length - 1;
        final title = extraCount > 0
            ? '🔔 নতুন ${newlyRequested.length} টি কিতাব রিকোয়েস্ট এসেছে!'
            : '🔔 নতুন কিতাব রিকোয়েস্ট এসেছে!';
        final subtitle = extraCount > 0
            ? '${firstReq.userName ?? 'ওস্তাদ'}: ${firstReq.bookName ?? 'কিতাব'} এবং আরো $extraCount টি'
            : '${firstReq.userName ?? 'ওস্তাদ'}: ${firstReq.bookName ?? 'কিতাব'}';

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active,
                      color: Colors.amber, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFF1E293B),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'দেখুন',
              textColor: Colors.amber,
              onPressed: () {
                setState(() {
                  _selectedIndex = 2; // Transactions tab
                });
                ref.read(transactionStatusFilterProvider.notifier).state =
                    TransactionStatus.requested;
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _runSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    try {
      // STEP 1: Push any pending local changes first
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
        await Future.delayed(const Duration(seconds: 1));
      }

      // STEP 2: Pull latest data from Supabase
      final syncService = await ref.read(syncServiceProvider.future);
      final result = await syncService.syncAll();

      // Force refresh UI
      refreshAllBookProviders(ref);
      ref.invalidate(usersListProvider);
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(transactionsListProvider);

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
    final pendingCount = ref.watch(pendingRequestsCountProvider);

    // Listen for new incoming requests in real-time
    ref.listen<AsyncValue<List<LibraryTransaction>>>(
      allTransactionsProvider,
      (previous, next) {
        next.whenData((txs) {
          _checkNewRequests(txs);
        });
      },
    );

    final pages = [
      const BookListPage(isAdmin: true),
      const UserListPage(),
      const TransactionListPage(),
      const AssetListPage(isAdmin: true),
      const SettingsPage(),
    ];

    final t = ref.watch(translationProvider);
    final showInactive = ref.watch(showInactiveUsersProvider);

    final titles = [
      t.bookList,
      (_selectedIndex == 1 && showInactive)
          ? t.inactiveMembersList
          : t.membersList,
      t.transactionList,
      t.assetsAndEquipment,
      t.settings,
    ];

    final canPop = _selectedIndex == 0 && !showInactive;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Priority 1: If in user list and viewing inactive members, return to active members
        if (_selectedIndex == 1 && showInactive) {
          ref.read(showInactiveUsersProvider.notifier).state = false;
          return;
        }
        // Priority 2: If in another tab, return to Books (index 0)
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return;
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: AppBar(
              toolbarHeight: 96,
              leading: (_selectedIndex == 1 && showInactive)
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: t.backToActiveMembers,
                      onPressed: () {
                        ref.read(showInactiveUsersProvider.notifier).state = false;
                      },
                    )
                  : null,
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
                      tooltip: 'ডাটাবেস সিঙ্ক করুন',
                      onPressed: _runSync,
                    ),
            ],
          ),
        ),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: CurvedBottomNav(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          if (_selectedIndex == 1 && index != 1 && ref.read(showInactiveUsersProvider)) {
            ref.read(showInactiveUsersProvider.notifier).state = false;
          }
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
            badgeCount: pendingCount,
            gradientColors: const [
              Color(0xFFfb923c),
              Color(0xFFea580c)
            ], // Orange
          ),
          CurvedNavItem(
            icon: Icons.inventory_2_outlined,
            activeIcon: Icons.inventory_2,
            label: t.assetsNav,
            gradientColors: const [
              Color(0xFF06B6D4), // Cyan
              Color(0xFF0891B2),
            ],
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
    ),
    );
  }
}
