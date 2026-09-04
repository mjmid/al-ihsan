import 'package:flutter/material.dart';
import '../../../../core/widgets/filter_segmented_control.dart';
import '../../../../core/widgets/madrasa_app_bar_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/models/book_model.dart';
import '../../../../core/providers/book_providers.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import 'package:maktaba_ihsan/core/theme/neu_card.dart';
import '../widgets/book_status_badge.dart';
import 'book_detail_page.dart';
import '../../../../core/providers/auth_provider.dart';
import 'add_edit_book_page.dart';

class BookListPage extends ConsumerWidget {
  final bool isAdmin;
  final bool canViewInventoryStatus;

  const BookListPage({
    super.key,
    this.isAdmin = false,
    this.canViewInventoryStatus = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationProvider);
    final authState = ref.watch(authProvider);
    final showStatusFilter =
        isAdmin || canViewInventoryStatus || authState.canViewInventoryStatus;
    final searchResultsAsync = ref.watch(bookSearchResultsProvider);
    final categoriesAsync = ref.watch(bookCategoriesProvider);
    final selectedStatus = ref.watch(bookStatusFilterProvider);
    final selectedCategory = ref.watch(bookCategoryFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final categories = categoriesAsync.asData?.value ?? [];

    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditBookPage(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            toolbarHeight: 0,
            pinned: true,
            floating: true,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(
                showStatusFilter ? 118 : 66,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 6.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: t.searchHint,
                              prefixIcon: const Icon(Icons.search),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest,
                            ),
                            onChanged: (value) {
                              ref.read(bookSearchQueryProvider.notifier).state =
                                  value;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryButton(
                          context,
                          ref,
                          categories: categories,
                          selectedCategory: selectedCategory,
                          colorScheme: colorScheme,
                          isLoading: categoriesAsync.isLoading,
                        ),
                      ],
                    ),
                  ),
                  if (showStatusFilter)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 4.0),
                      child: FilterSegmentedControl<BookStatus?>(
                        items: const [
                          null,
                          BookStatus.available,
                          BookStatus.lent,
                          BookStatus.lost,
                          BookStatus.damaged,
                          BookStatus.referenceOnly,
                        ],
                        selected: selectedStatus,
                        labelBuilder: (status) {
                          if (status == null) return t.all;
                          return _getStatusLabel(status, t);
                        },
                        onChanged: (status) {
                          ref.read(bookStatusFilterProvider.notifier).state =
                              status;
                        },
                      ),
                    ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
          searchResultsAsync.when(
            data: (books) {
              if (books.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(t.noBooks),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final book = books[index];
                    return BookListTile(
                      book: book,
                      index: index,
                      isAdmin: isAdmin,
                    );
                  },
                  childCount: books.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => SliverFillRemaining(
              child: Center(child: Text('${t.error}: $e')),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(BookStatus status, AppTranslations t) {
    switch (status) {
      case BookStatus.available:
        return t.bookStatusAvailable;
      case BookStatus.lent:
        return t.bookStatusIssued;
      case BookStatus.lost:
        return t.bookStatusLost;
      case BookStatus.damaged:
        return t.bookDamagedStatus;
      case BookStatus.referenceOnly:
        return t.bookReferenceStatus;
    }
  }

  Widget _buildCategoryButton(
    BuildContext context,
    WidgetRef ref, {
    required List<String> categories,
    required String? selectedCategory,
    required ColorScheme colorScheme,
    required bool isLoading,
  }) {
    if (selectedCategory != null) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String?>(
              initialValue: selectedCategory,
              tooltip: 'বিভাগ পরিবর্তন করুন',
              elevation: 6,
              offset: const Offset(0, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onSelected: (cat) {
                ref.read(bookCategoryFilterProvider.notifier).state = cat;
              },
              itemBuilder: (ctx) => _buildCategoryMenuItems(
                categories: categories,
                selectedCategory: selectedCategory,
                isLoading: isLoading,
                colorScheme: colorScheme,
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 12, top: 12, bottom: 12, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 16, color: colorScheme.onPrimary),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 85),
                      child: Text(
                        selectedCategory,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down,
                        size: 18, color: colorScheme.onPrimary),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  ref.read(bookCategoryFilterProvider.notifier).state = null;
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: colorScheme.onPrimary),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PopupMenuButton<String?>(
      initialValue: selectedCategory,
      tooltip: 'বিষয় / বিভাগ ফিল্টার',
      elevation: 6,
      offset: const Offset(0, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (cat) {
        ref.read(bookCategoryFilterProvider.notifier).state = cat;
      },
      itemBuilder: (ctx) => _buildCategoryMenuItems(
        categories: categories,
        selectedCategory: selectedCategory,
        isLoading: isLoading,
        colorScheme: colorScheme,
      ),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'বিভাগ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<String?>> _buildCategoryMenuItems({
    required List<String> categories,
    required String? selectedCategory,
    required bool isLoading,
    required ColorScheme colorScheme,
  }) {
    if (isLoading) {
      return [
        const PopupMenuItem<String?>(
          enabled: false,
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('বিভাগ লোড হচ্ছে...'),
            ],
          ),
        ),
      ];
    }

    final items = <PopupMenuEntry<String?>>[
      PopupMenuItem<String?>(
        value: null,
        child: Row(
          children: [
            Icon(
              selectedCategory == null
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 18,
              color: selectedCategory == null ? colorScheme.primary : null,
            ),
            const SizedBox(width: 10),
            const Text('সব বিভাগ',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      const PopupMenuDivider(),
    ];

    if (categories.isEmpty) {
      items.add(
        const PopupMenuItem<String?>(
          enabled: false,
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.grey),
              SizedBox(width: 10),
              Text(
                'কোনো বিভাগ পাওয়া যায়নি',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    } else {
      for (final cat in categories) {
        final isSelected = selectedCategory == cat;
        items.add(
          PopupMenuItem<String?>(
            value: cat,
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 18,
                  color: isSelected ? colorScheme.primary : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return items;
  }
}

class BookListTile extends ConsumerWidget {
  final Book book;
  final int index;
  final bool isAdmin;

  const BookListTile({
    super.key,
    required this.book,
    required this.index,
    required this.isAdmin,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: NeuCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BookDetailPage(book: book, isAdmin: isAdmin),
              ),
            ).then((_) => ref.invalidate(bookSearchResultsProvider));
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: avatarColor.withOpacity(0.15),
                  child: Icon(Icons.menu_book_rounded,
                      color: avatarColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              book.bookName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (book.author != null &&
                          book.author!.trim().isNotEmpty &&
                          book.author != '.') ...[
                        Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 14, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                book.author!,
                                style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        children: [
                          Icon(Icons.numbers_rounded,
                              size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            book.volumeNo != null && book.volumeNo!.trim().isNotEmpty
                                ? '${book.accessionNo}  -  খণ্ড ${book.volumeNo!.toEnglishNumerals}'
                                : book.accessionNo,
                            style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13),
                          ),
                          if (book.subjectCategory != null &&
                              book.subjectCategory!.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.category_outlined,
                                size: 14, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                book.subjectCategory!,
                                style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    BookStatusBadge(status: book.status),
                    if (book.shelfNo != null && book.shelfNo!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shelves,
                              size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            book.shelfNo!,
                            style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ]
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
