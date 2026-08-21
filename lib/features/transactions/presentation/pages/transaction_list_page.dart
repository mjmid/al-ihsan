import 'package:flutter/material.dart';
import '../../../../core/widgets/filter_segmented_control.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/providers/transaction_providers.dart';
import '../../../../core/widgets/dynamic_font_text.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import 'package:maktaba_ihsan/core/theme/neu_card.dart';
import 'package:maktaba_ihsan/core/providers/providers.dart';
import 'add_edit_transaction_page.dart';

class TransactionListPage extends ConsumerWidget {
  const TransactionListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationProvider);
    final txAsync = ref.watch(transactionsListProvider);
    final selectedStatus = ref.watch(transactionStatusFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditTransactionPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final syncService = await ref.read(syncServiceProvider.future);
          await syncService.syncAll();
          ref.invalidate(transactionsListProvider);
        },
        child: CustomScrollView(
        slivers: [
          SliverAppBar(
            toolbarHeight: 0,
            pinned: true,
            floating: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(75),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: FilterSegmentedControl<TransactionStatus?>(
                  items: const [
                    null,
                    TransactionStatus.active,
                    TransactionStatus.returned,
                    TransactionStatus.overdue,
                    TransactionStatus.requested,
                  ],
                  selected: selectedStatus,
                  labelBuilder: (status) {
                    if (status == null) return t.all;
                    return _translateTxStatus(status, t);
                  },
                  onChanged: (status) {
                    ref.read(transactionStatusFilterProvider.notifier).state =
                        status;
                  },
                ),
              ),
            ),
          ),
          txAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(t.noTransactions),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tx = transactions[index];
                      return NeuCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddEditTransactionPage(transaction: tx),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer
                                            .withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.menu_book_rounded,
                                          color: colorScheme.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          DynamicFontText(
                                            tx.bookName ?? tx.accessionNo,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 2,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.person,
                                                  size: 16,
                                                  color: colorScheme
                                                      .onSurfaceVariant),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  tx.userName ?? tx.userId,
                                                  style: TextStyle(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(tx.status)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: _getStatusColor(tx.status)
                                                .withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        _translateTxStatus(tx.status, t),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _getStatusColor(tx.status),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Divider(
                                    height: 1,
                                    color: colorScheme.outlineVariant
                                        .withOpacity(0.5)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (tx.status ==
                                              TransactionStatus.requested)
                                            _buildDateRow(
                                                context,
                                                Icons.edit_calendar,
                                                t.requestDate,
                                                tx.issueDate)
                                          else ...[ 
                                            _buildDateRow(
                                                context,
                                                Icons.calendar_today_rounded,
                                                t.issueDate,
                                                tx.issueDate),
                                            const SizedBox(height: 6),
                                            if (tx.status ==
                                                    TransactionStatus
                                                        .returned &&
                                                tx.actualReturn != null)
                                              _buildDateRow(
                                                  context,
                                                  Icons.check_circle_outline,
                                                  t.returnDate,
                                                  tx.actualReturn!)
                                            else if (tx.status ==
                                                    TransactionStatus.active ||
                                                tx.status ==
                                                    TransactionStatus.overdue)
                                              Row(
                                                children: [
                                                  Icon(Icons.hourglass_bottom,
                                                      size: 15,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'এখনো ফেরত দেওয়া হয়নি',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (tx.status == TransactionStatus.overdue)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.red,
                                                size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${tx.overdueDays} ${t.daysOverdue}',
                                              style: const TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: transactions.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(
                child: Text('${t.error}: $error'),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildDateRow(
      BuildContext context, IconData icon, String label, DateTime date) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: color, fontSize: 13),
        ),
        Text(
          date.toLocal().toString().split(' ')[0],
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _translateTxStatus(TransactionStatus status, AppTranslations t) {
    switch (status) {
      case TransactionStatus.active:
        return t.statusActive;
      case TransactionStatus.returned:
        return t.statusReturned;
      case TransactionStatus.overdue:
        return t.statusOverdue;
      case TransactionStatus.requested:
        return t.statusRequested;
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.active:
        return Colors.green;
      case TransactionStatus.returned:
        return Colors.blue;
      case TransactionStatus.overdue:
        return Colors.orange;
      case TransactionStatus.requested:
        return Colors.purple;
    }
  }
}
