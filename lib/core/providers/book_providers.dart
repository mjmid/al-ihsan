import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book_model.dart';
import 'providers.dart';

// Search query state
final bookSearchQueryProvider = StateProvider<String>((ref) => '');

// Selected status filter
final bookStatusFilterProvider = StateProvider<BookStatus?>((ref) => null);

// Selected category filter
final bookCategoryFilterProvider = StateProvider<String?>((ref) => null);

// Search results
final bookSearchResultsProvider =
    FutureProvider.autoDispose<List<Book>>((ref) async {
  final query = ref.watch(bookSearchQueryProvider);
  final statusFilter = ref.watch(bookStatusFilterProvider);
  final categoryFilter = ref.watch(bookCategoryFilterProvider);

  final repository = ref.watch(bookRepositoryProvider);

  // Debounce search
  await Future.delayed(const Duration(milliseconds: 300));
  if (ref.state.isRefreshing) {
    // Check if the provider was disposed during the delay
  }

  List<Book> books = [];

  if (query.isEmpty) {
    books = await repository.getAllBooks();
  } else {
    books = await repository.searchBooks(query);
  }

  // Apply filters in-memory
  if (statusFilter != null) {
    books = books.where((book) => book.status == statusFilter).toList();
  }

  if (categoryFilter != null) {
    books =
        books.where((book) => book.subjectCategory == categoryFilter).toList();
  }

  return books;
});

// Book status counts for dashboard chips
final bookStatusCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(bookRepositoryProvider);
  return await repository.getBookStatusCounts();
});

// All distinct categories
final bookCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(bookRepositoryProvider);
  return await repository.getAllCategories();
});

// Single book by accession number
final bookByAccessionNoProvider =
    FutureProvider.autoDispose.family<Book?, String>((ref, accessionNo) async {
  final repository = ref.watch(bookRepositoryProvider);
  return await repository.getBookByAccessionNo(accessionNo);
});

class BookAccessionAnalysis {
  final int maxAccessionNo;
  final int nextAvailable;
  final List<int> missingNumbers;
  final Set<String> usedNumbers;

  BookAccessionAnalysis({
    required this.maxAccessionNo,
    required this.nextAvailable,
    required this.missingNumbers,
    required this.usedNumbers,
  });
}

final bookAccessionAnalysisProvider = FutureProvider.autoDispose<BookAccessionAnalysis>((ref) async {
  final repository = ref.watch(bookRepositoryProvider);
  final books = await repository.getAllBooks();

  final usedNumbers = <String>{};
  final intNumbers = <int>[];

  for (final book in books) {
    usedNumbers.add(book.accessionNo.trim());
    final parsed = int.tryParse(book.accessionNo.trim());
    if (parsed != null && parsed > 0) {
      intNumbers.add(parsed);
    }
  }

  int max = 0;
  if (intNumbers.isNotEmpty) {
    max = intNumbers.reduce((a, b) => a > b ? a : b);
  }

  final nextAvailable = max + 1;
  final missingNumbers = <int>[];

  if (max > 0) {
    final intSet = intNumbers.toSet();
    for (int i = 1; i < max; i++) {
      if (!intSet.contains(i)) {
        missingNumbers.add(i);
      }
    }
  }

  return BookAccessionAnalysis(
    maxAccessionNo: max,
    nextAvailable: nextAvailable,
    missingNumbers: missingNumbers,
    usedNumbers: usedNumbers,
  );
});
