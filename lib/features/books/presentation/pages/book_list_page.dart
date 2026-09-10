import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/book_model.dart';
import '../../../../core/providers/book_providers.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/providers.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import 'package:maktaba_ihsan/core/theme/neu_card.dart';
import '../widgets/book_status_badge.dart';
import 'book_detail_page.dart';
import 'add_edit_book_page.dart';
import '../../../../core/utils/bengali_text_utils.dart';

class BookListPage extends ConsumerStatefulWidget {
  final bool isAdmin;
  final bool canViewInventoryStatus;

  const BookListPage({
    super.key,
    this.isAdmin = false,
    this.canViewInventoryStatus = false,
  });

  @override
  ConsumerState<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends ConsumerState<BookListPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchOpen = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    final currentQuery = ref.read(bookSearchQueryProvider);
    _searchController.text = currentQuery;
    if (currentQuery.isNotEmpty) {
      _isSearchOpen = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndTriggerSync(force: false);
    });
  }

  Future<void> _checkAndTriggerSync({bool force = false}) async {
    if (_isSyncing) return;
    try {
      final categoryCounts = ref.read(bookCategoryCountsProvider).valueOrNull;
      // Auto-sync if counts are empty, or if explicitly requested by user
      if (force || categoryCounts == null || categoryCounts.isEmpty) {
        if (mounted) setState(() => _isSyncing = true);
        final syncService = await ref.read(syncServiceProvider.future);
        final result = await syncService.syncAll();
        refreshAllBookProviders(ref);
        if (mounted && force) {
          if (result.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('বই ও বিষয়সমূহ আপডেট হয়েছে (${result.totalSynced} টি রেকর্ড)'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.error ?? 'সিঙ্ক সম্পন্ন করা যায়নি'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted && force) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('সিঙ্ক ত্রুটি: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openFilterPicker({
    required BuildContext context,
    required String title,
    required AsyncValue<Map<String, int>> itemsAsync,
    required String? selectedItem,
    required ValueChanged<String?> onSelected,
    required String allLabel,
    required String appFontFamily,
    required List<String> fontFamilyFallback,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterPickerSheet(
        title: title,
        itemsAsync: itemsAsync,
        selectedItem: selectedItem,
        onSelected: onSelected,
        allLabel: allLabel,
        appFontFamily: appFontFamily,
        fontFamilyFallback: fontFamilyFallback,
      ),
    );
  }

  void _openStatusPicker({
    required BuildContext context,
    required AppTranslations t,
    required BookStatus? selectedStatus,
    required ValueChanged<BookStatus?> onSelected,
    required String appFontFamily,
    required List<String> fontFamilyFallback,
  }) {
    final statusList = <BookStatus?>[
      null,
      BookStatus.available,
      BookStatus.lent,
      BookStatus.lost,
      BookStatus.damaged,
      BookStatus.referenceOnly,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.status,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: appFontFamily,
                        fontFamilyFallback: fontFamilyFallback,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...statusList.map((status) {
                final isSelected = selectedStatus == status;
                final label = status == null ? t.all : _getStatusLabel(status, t);
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: isSelected
                      ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                      : null,
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected ? theme.colorScheme.primary : null,
                  ),
                  title: Text(
                    label,
                    style: TextStyle(
                      fontFamily: appFontFamily,
                      fontFamilyFallback: fontFamilyFallback,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  onTap: () {
                    onSelected(status);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
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

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationProvider);
    final authState = ref.watch(authProvider);
    final settings = ref.watch(appSettingsProvider);
    final locale = settings.locale.languageCode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String appFontFamily = locale == 'ar'
        ? 'ArabicMyLotus'
        : (locale == 'ur' ? 'UrduNastaleeq' : 'BengaliSolaiman');
    final List<String> fontFallback = locale == 'ar'
        ? const ['BengaliSolaiman', 'UrduNastaleeq']
        : (locale == 'ur'
            ? const ['ArabicMyLotus', 'BengaliSolaiman']
            : const ['ArabicMyLotus', 'UrduNastaleeq']);

    final showStatusFilter = widget.isAdmin ||
        widget.canViewInventoryStatus ||
        authState.canViewInventoryStatus;

    final searchResultsAsync = ref.watch(bookSearchResultsProvider);
    final selectedStatus = ref.watch(bookStatusFilterProvider);
    final selectedCategory = ref.watch(bookCategoryFilterProvider);
    final selectedAuthor = ref.watch(bookAuthorFilterProvider);
    final selectedPublisher = ref.watch(bookPublisherFilterProvider);
    final selectedShelf = ref.watch(bookShelfFilterProvider);

    final hasActiveFilters = selectedCategory != null ||
        selectedAuthor != null ||
        selectedPublisher != null ||
        selectedShelf != null ||
        selectedStatus != null;

    final authorCountsAsync = ref.watch(bookAuthorCountsProvider);
    final publisherCountsAsync = ref.watch(bookPublisherCountsProvider);
    final categoryCountsAsync = ref.watch(bookCategoryCountsProvider);
    final shelfCountsAsync = ref.watch(bookShelfCountsProvider);

    return Scaffold(
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditBookPage(),
                  ),
                ).then((_) {
                  ref.invalidate(bookSearchResultsProvider);
                  ref.invalidate(bookCategoryCountsProvider);
                  ref.invalidate(bookCategoriesProvider);
                });
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => _checkAndTriggerSync(force: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              toolbarHeight: 0,
              pinned: true,
              floating: true,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(_isSearchOpen ? 104 : 52),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Expandable Search Bar (Revealed when search icon is clicked)
                      if (_isSearchOpen)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.4),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              autofocus: true,
                              style: TextStyle(
                                fontFamily: appFontFamily,
                                fontFamilyFallback: fontFallback,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: t.searchHint,
                                hintStyle: TextStyle(
                                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                  fontSize: 13,
                                  fontFamily: appFontFamily,
                                  fontFamilyFallback: fontFallback,
                                ),
                                prefixIcon: Icon(Icons.search_rounded,
                                    color: colorScheme.primary, size: 20),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_searchController.text.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 18),
                                        tooltip: 'মুছে ফেলুন',
                                        onPressed: () {
                                          _searchController.clear();
                                          ref.read(bookSearchQueryProvider.notifier).state = '';
                                          setState(() {});
                                        },
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 20),
                                      tooltip: 'বন্ধ করুন',
                                      onPressed: () {
                                        setState(() {
                                          _isSearchOpen = false;
                                          _searchFocusNode.unfocus();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                ref.read(bookSearchQueryProvider.notifier).state = value;
                                setState(() {});
                              },
                            ),
                          ),
                        ),

                      // Faceted Filter Chips Carousel with Search Icon on the left
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            // 0. Search Icon Button placed directly to the left of 'লেখক'
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                setState(() {
                                  _isSearchOpen = !_isSearchOpen;
                                  if (_isSearchOpen) {
                                    _searchFocusNode.requestFocus();
                                  } else {
                                    _searchFocusNode.unfocus();
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (_isSearchOpen || _searchController.text.isNotEmpty)
                                      ? colorScheme.primary
                                      : colorScheme.surfaceContainerHighest.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: (_isSearchOpen || _searchController.text.isNotEmpty)
                                        ? colorScheme.primary
                                        : colorScheme.outlineVariant.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.search_rounded,
                                      size: 16,
                                      color: (_isSearchOpen || _searchController.text.isNotEmpty)
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                    if (_searchController.text.isNotEmpty && !_isSearchOpen) ...[
                                      const SizedBox(width: 4),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 80),
                                        child: Text(
                                          _searchController.text,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onPrimary,
                                            fontFamily: appFontFamily,
                                            fontFamilyFallback: fontFallback,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _searchController.clear();
                                            ref.read(bookSearchQueryProvider.notifier).state = '';
                                          });
                                        },
                                        child: Icon(Icons.close_rounded,
                                            size: 14, color: colorScheme.onPrimary),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 1. Author Filter Chip
                            _FilterChipButton(
                              icon: Icons.person_outline_rounded,
                              activeIcon: Icons.person_rounded,
                            label: selectedAuthor == null
                                ? '${t.author} ▾'
                                : '${t.author}: $selectedAuthor',
                            isSelected: selectedAuthor != null,
                            appFontFamily: appFontFamily,
                            fontFamilyFallback: fontFallback,
                            onTap: () => _openFilterPicker(
                              context: context,
                              title: t.selectAuthor,
                              itemsAsync: authorCountsAsync,
                              selectedItem: selectedAuthor,
                              onSelected: (val) {
                                ref.read(bookAuthorFilterProvider.notifier).state = val;
                              },
                              allLabel: t.allAuthors,
                              appFontFamily: appFontFamily,
                              fontFamilyFallback: fontFallback,
                            ),
                            onClear: selectedAuthor != null
                                ? () {
                                    ref.read(bookAuthorFilterProvider.notifier).state = null;
                                  }
                                : null,
                          ),
                          const SizedBox(width: 8),

                          // 2. Publisher Filter Chip
                          _FilterChipButton(
                            icon: Icons.business_outlined,
                            activeIcon: Icons.business_rounded,
                            label: selectedPublisher == null
                                ? '${t.publisher} ▾'
                                : '${t.publisher}: $selectedPublisher',
                            isSelected: selectedPublisher != null,
                            appFontFamily: appFontFamily,
                            fontFamilyFallback: fontFallback,
                            onTap: () => _openFilterPicker(
                              context: context,
                              title: t.selectPublisher,
                              itemsAsync: publisherCountsAsync,
                              selectedItem: selectedPublisher,
                              onSelected: (val) {
                                ref.read(bookPublisherFilterProvider.notifier).state = val;
                              },
                              allLabel: t.allPublishers,
                              appFontFamily: appFontFamily,
                              fontFamilyFallback: fontFallback,
                            ),
                            onClear: selectedPublisher != null
                                ? () {
                                    ref.read(bookPublisherFilterProvider.notifier).state = null;
                                  }
                                : null,
                          ),
                          const SizedBox(width: 8),

                          // 3. Category / Subject Filter Chip
                          _FilterChipButton(
                            icon: Icons.category_outlined,
                            activeIcon: Icons.category_rounded,
                            label: selectedCategory == null
                                ? '${t.category} ▾'
                                : '${t.category}: $selectedCategory',
                            isSelected: selectedCategory != null,
                            appFontFamily: appFontFamily,
                            fontFamilyFallback: fontFallback,
                            onTap: () => _openFilterPicker(
                              context: context,
                              title: t.selectCategory,
                              itemsAsync: categoryCountsAsync,
                              selectedItem: selectedCategory,
                              onSelected: (val) {
                                ref.read(bookCategoryFilterProvider.notifier).state = val;
                              },
                              allLabel: t.allSubjects,
                              appFontFamily: appFontFamily,
                              fontFamilyFallback: fontFallback,
                            ),
                            onClear: selectedCategory != null
                                ? () {
                                    ref.read(bookCategoryFilterProvider.notifier).state = null;
                                  }
                                : null,
                          ),
                          const SizedBox(width: 8),

                          // 4. Shelf Filter Chip
                          _FilterChipButton(
                            icon: Icons.shelves,
                            activeIcon: Icons.shelves,
                            label: selectedShelf == null
                                ? '${t.shelfNo} ▾'
                                : '${t.shelfNo}: $selectedShelf',
                            isSelected: selectedShelf != null,
                            appFontFamily: appFontFamily,
                            fontFamilyFallback: fontFallback,
                            onTap: () => _openFilterPicker(
                              context: context,
                              title: t.selectShelf,
                              itemsAsync: shelfCountsAsync,
                              selectedItem: selectedShelf,
                              onSelected: (val) {
                                ref.read(bookShelfFilterProvider.notifier).state = val;
                              },
                              allLabel: t.allShelves,
                              appFontFamily: appFontFamily,
                              fontFamilyFallback: fontFallback,
                            ),
                            onClear: selectedShelf != null
                                ? () {
                                    ref.read(bookShelfFilterProvider.notifier).state = null;
                                  }
                                : null,
                          ),

                          // 5. Status Filter Chip (if permitted)
                          if (showStatusFilter) ...[
                            const SizedBox(width: 8),
                            _FilterChipButton(
                              icon: Icons.check_circle_outline_rounded,
                              activeIcon: Icons.check_circle_rounded,
                              label: selectedStatus == null
                                  ? '${t.status} ▾'
                                  : '${t.status}: ${_getStatusLabel(selectedStatus, t)}',
                              isSelected: selectedStatus != null,
                              appFontFamily: appFontFamily,
                              fontFamilyFallback: fontFallback,
                              onTap: () => _openStatusPicker(
                                context: context,
                                t: t,
                                selectedStatus: selectedStatus,
                                onSelected: (val) {
                                  ref.read(bookStatusFilterProvider.notifier).state = val;
                                },
                                appFontFamily: appFontFamily,
                                fontFamilyFallback: fontFallback,
                              ),
                              onClear: selectedStatus != null
                                  ? () {
                                      ref.read(bookStatusFilterProvider.notifier).state = null;
                                    }
                                : null,
                            ),
                          ],

                          // 6. Clear All Filters Button
                          if (hasActiveFilters) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                ref.read(bookCategoryFilterProvider.notifier).state = null;
                                ref.read(bookAuthorFilterProvider.notifier).state = null;
                                ref.read(bookPublisherFilterProvider.notifier).state = null;
                                ref.read(bookShelfFilterProvider.notifier).state = null;
                                ref.read(bookStatusFilterProvider.notifier).state = null;
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.close_rounded,
                                        size: 14, color: Colors.red),
                                    const SizedBox(width: 4),
                                    Text(
                                      t.clearFilters,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: appFontFamily,
                                        fontFamilyFallback: fontFallback,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),

          // Search Results
          searchResultsAsync.when(
            data: (books) {
              if (books.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.menu_book_rounded,
                                size: 40,
                                color: colorScheme.primary.withOpacity(0.6)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t.noBooks,
                            style: TextStyle(
                              fontSize: 18,
                              color: colorScheme.onSurface,
                              fontFamily: appFontFamily,
                              fontFamilyFallback: fontFallback,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (hasActiveFilters) ...[
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () {
                                ref.read(bookCategoryFilterProvider.notifier).state = null;
                                ref.read(bookAuthorFilterProvider.notifier).state = null;
                                ref.read(bookPublisherFilterProvider.notifier).state = null;
                                ref.read(bookShelfFilterProvider.notifier).state = null;
                                ref.read(bookStatusFilterProvider.notifier).state = null;
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: Text(
                                t.clearFilters,
                                style: TextStyle(
                                  fontFamily: appFontFamily,
                                  fontFamilyFallback: fontFallback,
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

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      // Filter results summary bar
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                        child: Row(
                          children: [
                            Text(
                              '${books.length} ${t.booksFound}',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                                fontFamily: appFontFamily,
                                fontFamilyFallback: fontFallback,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final book = books[index - 1];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: BookListTile(
                        book: book,
                        index: index - 1,
                        isAdmin: widget.isAdmin,
                      ),
                    );
                  },
                  childCount: books.length + 1,
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
    ),
  );
}
}

class _FilterChipButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final String appFontFamily;
  final List<String> fontFamilyFallback;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FilterChipButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.appFontFamily,
    required this.fontFamilyFallback,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(
          left: 10,
          right: onClear != null ? 4 : 10,
          top: 6,
          bottom: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 15,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontFamily: appFontFamily,
                  fontFamilyFallback: fontFamilyFallback,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterPickerSheet extends StatefulWidget {
  final String title;
  final AsyncValue<Map<String, int>> itemsAsync;
  final String? selectedItem;
  final ValueChanged<String?> onSelected;
  final String allLabel;
  final String appFontFamily;
  final List<String> fontFamilyFallback;

  const _FilterPickerSheet({
    required this.title,
    required this.itemsAsync,
    required this.selectedItem,
    required this.onSelected,
    required this.allLabel,
    required this.appFontFamily,
    required this.fontFamilyFallback,
  });

  @override
  State<_FilterPickerSheet> createState() => _FilterPickerSheetState();
}

class _FilterPickerSheetState extends State<_FilterPickerSheet> {
  final TextEditingController _filterSearchController = TextEditingController();
  String _filterSearchQuery = '';

  @override
  void dispose() {
    _filterSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: widget.appFontFamily,
                      fontFamilyFallback: widget.fontFamilyFallback,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Field inside picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextField(
              controller: _filterSearchController,
              style: TextStyle(
                fontFamily: widget.appFontFamily,
                fontFamilyFallback: widget.fontFamilyFallback,
              ),
              decoration: InputDecoration(
                hintText: 'খুঁজুন...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              ),
              onChanged: (val) => setState(() => _filterSearchQuery = val.trim().toLowerCase()),
            ),
          ),
          const SizedBox(height: 12),

          // Items List
          Expanded(
            child: widget.itemsAsync.when(
              data: (itemsMap) {
                final filteredEntries = itemsMap.entries.where((e) {
                  if (_filterSearchQuery.isEmpty) return true;
                  final q = _filterSearchQuery.toLowerCase();
                  return e.key.toLowerCase().contains(q) ||
                      BengaliTextUtils.normalizeSubject(e.key)
                          .contains(BengaliTextUtils.normalizeSubject(q));
                }).toList();

                return ListView.builder(
                  itemCount: filteredEntries.length + 1, // +1 for "All" option
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      final isSelected = widget.selectedItem == null;
                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected ? colorScheme.primary : null,
                        ),
                        title: Text(
                          widget.allLabel,
                          style: TextStyle(
                            fontFamily: widget.appFontFamily,
                            fontFamilyFallback: widget.fontFamilyFallback,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected ? colorScheme.primary : null,
                          ),
                        ),
                        onTap: () {
                          widget.onSelected(null);
                          Navigator.pop(context);
                        },
                      );
                    }

                    final entry = filteredEntries[i - 1];
                    final isSelected = widget.selectedItem == entry.key ||
                        BengaliTextUtils.isSameSubject(widget.selectedItem, entry.key);

                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      tileColor: isSelected
                          ? colorScheme.primaryContainer.withOpacity(0.3)
                          : null,
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected ? colorScheme.primary : null,
                      ),
                      title: Text(
                        entry.key,
                        style: TextStyle(
                          fontFamily: widget.appFontFamily,
                          fontFamilyFallback: widget.fontFamilyFallback,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected ? colorScheme.primary : null,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${entry.value}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                            fontFamily: widget.appFontFamily,
                            fontFamilyFallback: widget.fontFamilyFallback,
                          ),
                        ),
                      ),
                      onTap: () {
                        widget.onSelected(entry.key);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
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
    final settings = ref.watch(appSettingsProvider);
    final locale = settings.locale.languageCode;
    final colorScheme = Theme.of(context).colorScheme;

    final String appFontFamily = locale == 'ar'
        ? 'ArabicMyLotus'
        : (locale == 'ur' ? 'UrduNastaleeq' : 'BengaliSolaiman');
    final List<String> fontFallback = locale == 'ar'
        ? const ['BengaliSolaiman', 'UrduNastaleeq']
        : (locale == 'ur'
            ? const ['ArabicMyLotus', 'BengaliSolaiman']
            : const ['ArabicMyLotus', 'UrduNastaleeq']);

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
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                fontFamily: appFontFamily,
                                fontFamilyFallback: fontFallback,
                              ),
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
                            Icon(Icons.person_outline_rounded,
                                size: 14, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                book.author!,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                  fontFamily: appFontFamily,
                                  fontFamilyFallback: fontFallback,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (book.publisher != null &&
                          book.publisher!.trim().isNotEmpty &&
                          book.publisher != '.') ...[
                        Row(
                          children: [
                            Icon(Icons.business_outlined,
                                size: 14, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                book.publisher!,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant.withOpacity(0.85),
                                  fontSize: 12,
                                  fontFamily: appFontFamily,
                                  fontFamilyFallback: fontFallback,
                                ),
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
                              fontSize: 13,
                              fontFamily: appFontFamily,
                              fontFamilyFallback: fontFallback,
                            ),
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
                                  fontSize: 13,
                                  fontFamily: appFontFamily,
                                  fontFamilyFallback: fontFallback,
                                ),
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
                              fontWeight: FontWeight.normal,
                              fontFamily: appFontFamily,
                              fontFamilyFallback: fontFallback,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
