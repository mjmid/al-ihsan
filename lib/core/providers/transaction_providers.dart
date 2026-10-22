import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import 'providers.dart';

// Selected status filter
final transactionStatusFilterProvider =
    StateProvider<TransactionStatus?>((ref) => null);

// All transactions provider (unfiltered, directly from DB)
final allTransactionsProvider =
    FutureProvider.autoDispose<List<LibraryTransaction>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getTransactionHistory();
});

// Transactions list (filtered according to selected status filter)
final transactionsListProvider =
    FutureProvider.autoDispose<List<LibraryTransaction>>((ref) async {
  final statusFilter = ref.watch(transactionStatusFilterProvider);
  final repository = ref.watch(transactionRepositoryProvider);

  if (statusFilter == TransactionStatus.overdue) {
    return await repository.getOverdueTransactions();
  }

  final allTxs = await ref.watch(allTransactionsProvider.future);

  if (statusFilter == null) return allTxs;

  return allTxs.where((tx) => tx.status == statusFilter).toList();
});

// Pending requested transactions count provider (always accurate, regardless of active filter)
final pendingRequestsCountProvider = Provider.autoDispose<int>((ref) {
  final allAsync = ref.watch(allTransactionsProvider);
  return allAsync.valueOrNull
          ?.where((t) => t.status == TransactionStatus.requested)
          .length ??
      0;
});

// Map of userId -> count of currently borrowed books (Active or Overdue)
final userActiveBookCountsProvider =
    Provider.autoDispose<Map<String, int>>((ref) {
  final allAsync = ref.watch(allTransactionsProvider);
  final all = allAsync.valueOrNull ?? [];
  final map = <String, int>{};
  for (final tx in all) {
    if (tx.status == TransactionStatus.active ||
        tx.status == TransactionStatus.overdue) {
      map[tx.userId] = (map[tx.userId] ?? 0) + 1;
    }
  }
  return map;
});

// User's specific transactions
final userTransactionsProvider = FutureProvider.autoDispose
    .family<List<LibraryTransaction>, String>((ref, userId) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getTransactionHistory(userId: userId);
});

// Active transaction for a book
final activeBookTransactionProvider = FutureProvider.autoDispose
    .family<LibraryTransaction?, String>((ref, accessionNo) async {
  if (accessionNo.trim().isEmpty) return null;
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getActiveTransactionForBook(accessionNo.trim());
});
