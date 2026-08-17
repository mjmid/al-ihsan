import 'package:flutter/material.dart';
import '../../../../core/widgets/madrasa_app_bar_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maktaba_ihsan/core/models/transaction_model.dart';
import 'package:maktaba_ihsan/core/providers/transaction_providers.dart';
import 'package:maktaba_ihsan/core/providers/providers.dart';
import 'package:maktaba_ihsan/core/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/book_model.dart';
import '../../../../core/l10n/app_translations.dart';
import '../widgets/book_status_badge.dart';
import 'add_edit_book_page.dart';

class BookDetailPage extends ConsumerWidget {
  final Book book;
  final bool isAdmin;

  const BookDetailPage({
    super.key,
    required this.book,
    this.isAdmin =
        true, // Defaulting to true for demo purposes, replace with actual auth state
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationProvider);
    final colorScheme = Theme.of(context).colorScheme;

    Color avatarColor;
    switch (book.status) {
      case BookStatus.available:
        avatarColor = Colors.green;
        break;
      case BookStatus.lent:
        avatarColor = Colors.orange;
        break;
      case BookStatus.lost:
        avatarColor = Colors.red;
        break;
      case BookStatus.damaged:
        avatarColor = Colors.grey;
        break;
      case BookStatus.referenceOnly:
        avatarColor = Colors.blue;
        break;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            toolbarHeight: 90,
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: avatarColor.withOpacity(0.1),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: avatarColor.withOpacity(0.2),
                        foregroundColor: avatarColor,
                        child: Text(
                          book.bookName.isNotEmpty ? book.bookName[0] : '?',
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      BookStatusBadge(status: book.status),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditBookPage(book: book),
                      ),
                    );
                  },
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSectionCard(
                    context,
                    title: t.basicInfo,
                    children: [
                      _buildInfoRow(
                          Icons.menu_book, t.bookNameLabel, book.bookName),
                      if (book.volumeNo != null && book.volumeNo!.isNotEmpty)
                        _buildInfoRow(Icons.format_list_numbered,
                            t.volumeNoLabel, book.volumeNo!),
                      _buildInfoRow(Icons.person, t.author, book.author ?? ''),
                      if (book.publisher != null && book.publisher!.isNotEmpty)
                        _buildInfoRow(
                            Icons.business, t.publisher, book.publisher!),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: t.location,
                    children: [
                      _buildInfoRow(
                          Icons.shelves, t.shelfNo, book.shelfNo ?? ""),
                      _buildInfoRow(Icons.category, t.category,
                          book.subjectCategory ?? ""),
                      if (book.address != null && book.address!.isNotEmpty)
                        _buildInfoRow(
                            Icons.location_on, t.addressLabel, book.address!),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: t.condition,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: Text(t.currentCondition),
                        trailing: BookStatusBadge(status: book.status),
                      ),
                      if (book.remarks != null && book.remarks!.isNotEmpty)
                        _buildInfoRow(
                            Icons.notes, t.remarksLabel, book.remarks!),
                    ],
                  ),
                  if (book.status == BookStatus.lent) ...[
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      context,
                      title: t.transactionTab,
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            final txAsync = ref.watch(
                                activeBookTransactionProvider(
                                    book.accessionNo));
                            return txAsync.when(
                              data: (tx) {
                                if (tx == null) {
                                  return ListTile(
                                    leading: const Icon(Icons.info_outline),
                                    title: MadrasaAppBarTitle(
                                        title: 'কোনো তথ্য পাওয়া যায়নি'),
                                  );
                                }
                                return Column(
                                  children: [
                                    _buildInfoRow(Icons.person, 'যার কাছে আছে',
                                        tx.userName ?? tx.userId),
                                    _buildInfoRow(
                                        Icons.calendar_today,
                                        t.issueDate,
                                        tx.issueDate.toString().split(' ')[0]),
                                    if (tx.status ==
                                            TransactionStatus.returned &&
                                        tx.actualReturn != null)
                                      _buildInfoRow(
                                          Icons.event,
                                          t.returnDate,
                                          tx.actualReturn!
                                              .toString()
                                              .split(' ')[0]),
                                  ],
                                );
                              },
                              loading: () => const Center(
                                  child: CircularProgressIndicator()),
                              error: (e, st) => Text('Error: $e'),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isAdmin
          ? Consumer(
              builder: (context, ref, child) {
                final authState = ref.watch(authProvider);
                if (authState.userId == null) return const SizedBox.shrink();

                final txAsync =
                    ref.watch(userTransactionsProvider(authState.userId!));

                return txAsync.when(
                  data: (transactions) {
                    final hasActiveOrPending = transactions.any((tx) =>
                        tx.accessionNo == book.accessionNo &&
                        (tx.status == TransactionStatus.requested ||
                            tx.status == TransactionStatus.active ||
                            tx.status == TransactionStatus.overdue));

                    final isAvailable = book.status == BookStatus.available;

                    if (hasActiveOrPending || !isAvailable) {
                      String message = '';
                      if (hasActiveOrPending) {
                        message =
                            'এই কিতাবটি আপনার কাছে আছে বা রিকোয়েস্ট করা হয়েছে';
                      } else {
                        message = 'এই কিতাবটি বর্তমানে ধার দেওয়া যাবে না';
                      }

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: FilledButton.icon(
                          onPressed: null, // Disabled
                          icon: const Icon(Icons.block),
                          label: Text(message,
                              style: const TextStyle(fontSize: 14)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FilledButton.icon(
                        onPressed: () async {
                          final repo = ref.read(transactionRepositoryProvider);
                          final tx = LibraryTransaction(
                            trxId: const Uuid().v4(),
                            accessionNo: book.accessionNo,
                            userId: authState.userId!,
                            issueDate: DateTime.now(),
                            expectedReturn:
                                DateTime.now().add(const Duration(days: 7)),
                            status: TransactionStatus.requested,
                            lastUpdated: DateTime.now(),
                            bookName: book.bookName,
                            userName: authState.userName,
                          );

                          await repo.insertTransaction(tx);

                          // Invalidate to refresh the shelf page
                          ref.invalidate(
                              userTransactionsProvider(authState.userId!));

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(t.statusOngoing),
                              backgroundColor: Colors.green,
                            ));
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.send),
                        label: Text(t.requestThisBook,
                            style: const TextStyle(fontSize: 16)),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                );
              },
            )
          : null,
    );
  }

  Widget _buildSectionCard(BuildContext context,
      {required String title, required List<Widget> children}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
