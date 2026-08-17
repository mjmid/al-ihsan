import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import 'providers.dart';

// Selected status filter
final transactionStatusFilterProvider =
    StateProvider<TransactionStatus?>((ref) => null);

// Transactions list
final transactionsListProvider =
    FutureProvider.autoDispose<List<LibraryTransaction>>((ref) async {
  final statusFilter = ref.watch(transactionStatusFilterProvider);
  final repository = ref.watch(transactionRepositoryProvider);

  List<LibraryTransaction> allTxs = await repository.getTransactionHistory();

  if (statusFilter == null) return allTxs;

  if (statusFilter == TransactionStatus.overdue) {
    return await repository.getOverdueTransactions();
  }

  return allTxs.where((tx) => tx.status == statusFilter).toList();
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
  final repository = ref.watch(transactionRepositoryProvider);
  final txs = await repository.getTransactionHistory();
  try {
    return txs.firstWhere((tx) => tx.accessionNo == accessionNo && tx.status != TransactionStatus.returned);
  } catch (e) {
    return null;
  }
});
