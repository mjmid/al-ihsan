import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maktaba_ihsan/core/providers/transaction_providers.dart';
import 'package:maktaba_ihsan/core/providers/auth_provider.dart';
import 'package:maktaba_ihsan/core/models/transaction_model.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import 'package:maktaba_ihsan/core/theme/neu_card.dart';
import 'package:intl/intl.dart';

class TeacherShelfPage extends ConsumerStatefulWidget {
  const TeacherShelfPage({super.key});

  @override
  ConsumerState<TeacherShelfPage> createState() => _TeacherShelfPageState();
}

class _TeacherShelfPageState extends ConsumerState<TeacherShelfPage> {
  int _selectedTab = 0; // 0=চলতি, 1=রিকোয়েস্ট, 2=পড়া

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationProvider);
    final authState = ref.watch(authProvider);
    final userId = authState.userId;

    if (userId == null) {
      return const Center(child: Text('User ID not found.'));
    }

    final txAsync = ref.watch(userTransactionsProvider(userId));

    return Scaffold(
      body: txAsync.when(
        data: (transactions) {
          final pendingRequests = transactions
              .where((tx) => tx.status == TransactionStatus.requested)
              .toList();
          final activeBooks = transactions
              .where((tx) =>
                  tx.status == TransactionStatus.active ||
                  tx.status == TransactionStatus.overdue)
              .toList();
          final readBooks = transactions
              .where((tx) => tx.status == TransactionStatus.returned)
              .toList();

          List<LibraryTransaction> currentList;
          if (_selectedTab == 0) currentList = activeBooks;
          else if (_selectedTab == 1) currentList = pendingRequests;
          else currentList = readBooks;

          return Column(
            children: [
              // Horizontal filter tabs
              Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildTab(context, 0, t.currentlyWithMe, Icons.menu_book, activeBooks.length),
                    const SizedBox(width: 8),
                    _buildTab(context, 1, t.pendingRequests, Icons.hourglass_empty, pendingRequests.length),
                    const SizedBox(width: 8),
                    _buildTab(context, 2, t.previouslyRead, Icons.done_all, readBooks.length),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: currentList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64,
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4)),
                            const SizedBox(height: 16),
                            Text(t.noBooks,
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: currentList.length,
                        itemBuilder: (context, index) =>
                            _buildTxCard(context, currentList[index], t),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${t.error}: $e')),
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index, String label, IconData icon, int count) {
    final isSelected = _selectedTab == index;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colorScheme.primary : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18,
                  color: isSelected ? Colors.white : colorScheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (count > 0) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.3) : colorScheme.onSurfaceVariant.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTxCard(
      BuildContext context, LibraryTransaction tx, AppTranslations t) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final colorScheme = Theme.of(context).colorScheme;

    Color statusColor;
    String statusText;
    if (tx.status == TransactionStatus.requested) {
      statusColor = Colors.orange;
      statusText = t.pending;
    } else if (tx.status == TransactionStatus.active) {
      statusColor = Colors.blue;
      statusText = t.statusOngoing;
    } else if (tx.status == TransactionStatus.overdue) {
      statusColor = Colors.red;
      statusText = t.statusOverdue;
    } else {
      statusColor = Colors.green;
      statusText = t.statusReturned;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: NeuCard(
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
                    color: statusColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.menu_book_rounded,
                      color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.bookName ?? t.unknownBook,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.numbers_rounded,
                              size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${t.accessionNo}: ${tx.accessionNo}',
                            style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (tx.status != TransactionStatus.requested) ...[
              const SizedBox(height: 16),
              Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withOpacity(0.5)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    t.issueDate,
                    style: TextStyle(
                        color: colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                  Text(
                    dateFormat.format(tx.issueDate),
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (tx.status == TransactionStatus.returned &&
                  tx.actualReturn != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      t.returnDate,
                      style: TextStyle(
                          color: colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                    Text(
                      dateFormat.format(tx.actualReturn!),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ]
          ],
        ),
      ),
    );
  }
}
