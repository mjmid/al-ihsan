import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book_model.dart';
import '../utils/bengali_text_utils.dart';
import 'providers.dart';

// Search query state
final bookSearchQueryProvider = StateProvider<String>((ref) => '');

// Selected status filter
final bookStatusFilterProvider = StateProvider<BookStatus?>((ref) => null);

// Selected category filter
final bookCategoryFilterProvider = StateProvider<String?>((ref) => null);

// Selected author filter
final bookAuthorFilterProvider = StateProvider<String?>((ref) => null);

// Selected publisher / maktaba filter
final bookPublisherFilterProvider = StateProvider<String?>((ref) => null);

// Selected shelf filter
final bookShelfFilterProvider = StateProvider<String?>((ref) => null);

// Search results
final bookSearchResultsProvider =
    FutureProvider.autoDispose<List<Book>>((ref) async {
  final query = ref.watch(bookSearchQueryProvider);
  final statusFilter = ref.watch(bookStatusFilterProvider);
  final categoryFilter = ref.watch(bookCategoryFilterProvider);
  final authorFilter = ref.watch(bookAuthorFilterProvider);
  final publisherFilter = ref.watch(bookPublisherFilterProvider);
  final shelfFilter = ref.watch(bookShelfFilterProvider);

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
    // Also catch books if query matches a subject category regardless of kar differences
    final normQuery = BengaliTextUtils.normalizeSubject(query);
    if (normQuery.length >= 2) {
      final allBooks = await repository.getAllBooks();
      final extraBooks = allBooks.where((b) {
        final cat = b.subjectCategory;
        if (cat == null || cat.trim().isEmpty) return false;
        return BengaliTextUtils.normalizeSubject(cat).contains(normQuery);
      });
      final existingAccs = books.map((b) => b.accessionNo).toSet();
      for (final eb in extraBooks) {
        if (!existingAccs.contains(eb.accessionNo)) {
          books.add(eb);
          existingAccs.add(eb.accessionNo);
        }
      }
    }
  }

  // Apply filters in-memory
  if (statusFilter != null) {
    books = books.where((book) => book.status == statusFilter).toList();
  }

  if (categoryFilter != null && categoryFilter.isNotEmpty) {
    books = books
        .where((book) => BengaliTextUtils.isSameSubject(book.subjectCategory, categoryFilter))
        .toList();
  }

  if (authorFilter != null && authorFilter.isNotEmpty) {
    books = books
        .where((book) => book.author?.trim() == authorFilter.trim())
        .toList();
  }

  if (publisherFilter != null && publisherFilter.isNotEmpty) {
    books = books
        .where((book) => book.publisher?.trim() == publisherFilter.trim())
        .toList();
  }

  if (shelfFilter != null && shelfFilter.isNotEmpty) {
    books = books
        .where((book) => book.shelfNo?.trim() == shelfFilter.trim())
        .toList();
  }

  return books;
});

// Book status counts for dashboard chips
final bookStatusCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(bookRepositoryProvider);
  return await repository.getBookStatusCounts();
});

// Author counts
final bookAuthorCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(bookRepositoryProvider);
  return await repository.getAuthorCounts();
});

// Publisher counts
final bookPublisherCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(bookRepositoryProvider);
  return await repository.getPublisherCounts();
});

// Category counts (aggregated to merge spelling variants differing only by kars)
final bookCategoryCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(bookRepositoryProvider);
  final rawCounts = await repository.getCategoryCounts();
  return BengaliTextUtils.aggregateCategoryCounts(rawCounts);
});

// All distinct categories (deduplicated canonical categories)
final bookCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final counts = await ref.watch(bookCategoryCountsProvider.future);
  return counts.keys.toList();
});

// Shelf counts
final bookShelfCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(bookRepositoryProvider);
  return await repository.getShelfCounts();
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
    final parsed = int.tryParse(book.accessionNo.trim().toEnglishNumerals);
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

/// Invalidates all book, category, shelf, author, and related counts providers
/// so that the latest synced data is immediately re-read from SQLite.
void refreshAllBookProviders(dynamic ref) {
  ref.invalidate(bookSearchResultsProvider);
  ref.invalidate(bookCategoryCountsProvider);
  ref.invalidate(bookCategoriesProvider);
  ref.invalidate(bookAuthorCountsProvider);
  ref.invalidate(bookPublisherCountsProvider);
  ref.invalidate(bookShelfCountsProvider);
  ref.invalidate(bookStatusCountsProvider);
  ref.invalidate(bookAccessionAnalysisProvider);
}
