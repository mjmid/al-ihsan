import 'package:flutter/material.dart';
import '../../../../../core/widgets/madrasa_app_bar_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/models/book_model.dart';
import '../../../../../core/providers/providers.dart';
import '../../../../../core/providers/book_providers.dart';
import '../../../../../core/providers/settings_provider.dart';
import '../../../../../core/l10n/app_translations.dart';
import '../../../../../core/utils/bengali_text_utils.dart';

// Assuming MaktabaTextField exists, otherwise a standard TextFormField is used
// import '../../../../../core/widgets/maktaba_text_field.dart';

class AddEditBookPage extends ConsumerStatefulWidget {
  final Book? book;

  const AddEditBookPage({super.key, this.book});

  @override
  ConsumerState<AddEditBookPage> createState() => _AddEditBookPageState();
}

class _AddEditBookPageState extends ConsumerState<AddEditBookPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _accessionNoController;
  late TextEditingController _bookNameController;
  late TextEditingController _volumeNoController;
  late TextEditingController _authorController;
  late TextEditingController _translatorController;
  late TextEditingController _publisherController;
  late TextEditingController _addressController;
  late TextEditingController _shelfNoController;
  late TextEditingController _remarksController;
  late TextEditingController _categoryController;
  bool _isBulkAdd = false;
  bool _showAllMissing = false;
  late TextEditingController _bulkVolumesController;
  BookAccessionAnalysis? _cachedAnalysis;

  BookStatus _selectedStatus = BookStatus.available;

  final List<String> _categoryPresets = [
    'ফিকহ',
    'হাদিস',
    'তাফসীর',
    'আকিদা',
    'সিরাত',
    'আরবি ভাষা',
    'বাংলা সাহিত্য',
    'গণিত',
    'বিজ্ঞান',
    'অন্যান্য'
  ];

  @override
  void initState() {
    super.initState();
    final isEdit = widget.book != null;

    _accessionNoController =
        TextEditingController(text: isEdit ? widget.book!.accessionNo : '');
    _bookNameController =
        TextEditingController(text: isEdit ? widget.book!.bookName : '');
    _volumeNoController =
        TextEditingController(text: isEdit ? widget.book!.volumeNo : '');
    _authorController =
        TextEditingController(text: isEdit ? widget.book!.author : '');
    _translatorController =
        TextEditingController(text: isEdit ? widget.book!.translator : '');
    _publisherController =
        TextEditingController(text: isEdit ? widget.book!.publisher : '');
    _addressController =
        TextEditingController(text: isEdit ? widget.book!.address : '');
    _shelfNoController =
        TextEditingController(text: isEdit ? widget.book!.shelfNo : '');
    _remarksController =
        TextEditingController(text: isEdit ? widget.book!.remarks : '');

    final category = isEdit ? widget.book!.subjectCategory : null;
    final initialCategory = (category != null && category.isNotEmpty)
        ? category
        : _categoryPresets.first;

    _categoryController = TextEditingController(text: initialCategory);
    _bulkVolumesController = TextEditingController(text: '2');

    if (!_categoryPresets.contains(initialCategory)) {
      _categoryPresets.add(initialCategory);
    }
    _selectedStatus = isEdit ? widget.book!.status : BookStatus.available;
  }

  @override
  void dispose() {
    _accessionNoController.dispose();
    _bookNameController.dispose();
    _volumeNoController.dispose();
    _authorController.dispose();
    _translatorController.dispose();
    _publisherController.dispose();
    _addressController.dispose();
    _shelfNoController.dispose();
    _remarksController.dispose();
    _categoryController.dispose();
    _bulkVolumesController.dispose();
    super.dispose();
  }

  void _saveBook() async {
    if (_formKey.currentState!.validate()) {
      final repository = ref.read(bookRepositoryProvider);

      try {
        if (!_isBulkAdd) {
          final book = Book(
            accessionNo: _accessionNoController.text.trim(),
            bookName: _bookNameController.text.trim(),
            subjectCategory: _categoryController.text.isNotEmpty
                ? _categoryController.text.trim()
                : _categoryPresets.first,
            author: _authorController.text.trim(),
            translator: _translatorController.text.isNotEmpty
                ? _translatorController.text.trim()
                : null,
            shelfNo: _shelfNoController.text.trim(),
            status: _selectedStatus,
            volumeNo: _volumeNoController.text.isNotEmpty
                ? _volumeNoController.text.trim()
                : null,
            publisher: _publisherController.text.isNotEmpty
                ? _publisherController.text.trim()
                : null,
            address: _addressController.text.isNotEmpty
                ? _addressController.text.trim()
                : null,
            remarks: _remarksController.text.isNotEmpty
                ? _remarksController.text.trim()
                : null,
            lastUpdated: DateTime.now(),
          );
          await repository.upsertBook(book);
        } else {
          // Bulk Save
          final totalVolumes = int.parse(_bulkVolumesController.text);
          final missing = _cachedAnalysis != null
              ? List<int>.from(_cachedAnalysis!.missingNumbers)
              : <int>[];
          int nextAvail =
              _cachedAnalysis != null ? _cachedAnalysis!.nextAvailable : 1;

          for (int i = 1; i <= totalVolumes; i++) {
            int assignedNo;
            if (missing.isNotEmpty) {
              assignedNo = missing.removeAt(0);
            } else {
              assignedNo = nextAvail++;
            }
            final book = Book(
              accessionNo: assignedNo.toString(),
              bookName: _bookNameController.text.trim(),
              subjectCategory: _categoryController.text.isNotEmpty
                  ? _categoryController.text.trim()
                  : _categoryPresets.first,
              author: _authorController.text.trim(),
              translator: _translatorController.text.isNotEmpty
                  ? _translatorController.text.trim()
                  : null,
              shelfNo: _shelfNoController.text.trim(),
              status: _selectedStatus,
              volumeNo: '$i',
              publisher: _publisherController.text.isNotEmpty
                  ? _publisherController.text.trim()
                  : null,
              address: _addressController.text.isNotEmpty
                  ? _addressController.text.trim()
                  : null,
              remarks: _remarksController.text.isNotEmpty
                  ? _remarksController.text.trim()
                  : null,
              lastUpdated: DateTime.now(),
            );
            await repository.upsertBook(book);
          }
        }

        ref.invalidate(bookCategoryCountsProvider);
        ref.invalidate(bookCategoriesProvider);
        ref.invalidate(bookSearchResultsProvider);
        ref.invalidate(bookAuthorCountsProvider);
        ref.invalidate(bookPublisherCountsProvider);
        ref.invalidate(bookShelfCountsProvider);
        ref.invalidate(bookStatusCountsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('কিতাব সফলভাবে সংরক্ষণ করা হয়েছে')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('সংরক্ষণে ত্রুটি: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.book != null;
    final t = ref.watch(translationProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final settings = ref.watch(appSettingsProvider);
    final locale = settings.locale.languageCode;
    final String appFontFamily = locale == 'ar'
        ? 'ArabicMyLotus'
        : (locale == 'ur' ? 'UrduNastaleeq' : 'BengaliSolaiman');
    final List<String> fontFallback = locale == 'ar'
        ? const ['BengaliSolaiman', 'UrduNastaleeq']
        : (locale == 'ur'
            ? const ['ArabicMyLotus', 'BengaliSolaiman']
            : const ['ArabicMyLotus', 'UrduNastaleeq']);

    final categoryCountsAsync = ref.watch(bookCategoryCountsProvider);
    final categoryCounts = categoryCountsAsync.valueOrNull ?? {};
    final dbCategories = categoryCounts.keys.toList();

    // Dynamically combine all categories: DB categories (sorted by frequency) + defaults + current value
    final allCategories = <String>[];
    final seen = <String>{};

    for (final cat in dbCategories) {
      final trimmed = cat.trim();
      if (trimmed.isNotEmpty && seen.add(trimmed)) {
        allCategories.add(trimmed);
      }
    }

    for (final preset in _categoryPresets) {
      final trimmed = preset.trim();
      if (trimmed.isNotEmpty && seen.add(trimmed)) {
        allCategories.add(trimmed);
      }
    }

    if (_categoryController.text.trim().isNotEmpty &&
        seen.add(_categoryController.text.trim())) {
      allCategories.add(_categoryController.text.trim());
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 96,
        title: MadrasaAppBarTitle(title: isEdit ? t.editBook : t.addBookTitle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Consumer(
              builder: (context, ref, child) {
                final analysisAsync = ref.watch(bookAccessionAnalysisProvider);
                return analysisAsync.when(
                  data: (analysis) {
                    _cachedAnalysis = analysis;
                    if (!isEdit &&
                        _accessionNoController.text.isEmpty &&
                        !_isBulkAdd) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _accessionNoController.text =
                            analysis.nextAvailable.toString();
                      });
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _accessionNoController,
                          decoration: InputDecoration(
                            labelText: t.bookNumber,
                            prefixIcon: const Icon(Icons.tag),
                            border: const OutlineInputBorder(),
                            helperText: !isEdit && !_isBulkAdd
                                ? 'আপনি চাইলে নিচের রিকমেন্ডেড ফাঁকা নাম্বারগুলো ব্যবহার করতে পারেন'
                                : null,
                          ),
                          enabled: !isEdit && !_isBulkAdd,
                          validator: (value) {
                            if (_isBulkAdd) return null;
                            if (value == null || value.isEmpty)
                              return t.required;
                            if (!isEdit || value != widget.book!.accessionNo) {
                              if (analysis.usedNumbers.contains(value.trim())) {
                                return 'এই নাম্বারটি ইতিমধ্যে ব্যবহার করা হয়েছে';
                              }
                            }
                            return null;
                          },
                        ),
                        if (analysis.missingNumbers.isNotEmpty &&
                            !isEdit &&
                            !_isBulkAdd) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_fix_high,
                                      size: 18,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'রিকমেন্ডেড ফাঁকা নাম্বার (${analysis.missingNumbers.length}টি ফাঁকা আছে):',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      // Next available chip
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 6.0),
                                        child: ChoiceChip(
                                          avatar: const Icon(
                                              Icons.add_circle_outline,
                                              size: 16),
                                          label: Text(
                                              'পরবর্তী নতুন (${analysis.nextAvailable})'),
                                          selected: _accessionNoController
                                                  .text
                                                  .trim() ==
                                              analysis.nextAvailable
                                                  .toString(),
                                          selectedColor: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.25),
                                          onSelected: (selected) {
                                            setState(() {
                                              _accessionNoController.text =
                                                  analysis.nextAvailable
                                                      .toString();
                                            });
                                          },
                                        ),
                                      ),
                                      // Missing vacant number chips
                                      ...analysis.missingNumbers
                                          .take(_showAllMissing
                                              ? analysis.missingNumbers.length
                                              : 25)
                                          .map((num) {
                                        final isSelected =
                                            _accessionNoController.text
                                                    .trim() ==
                                                num.toString();
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(right: 6.0),
                                          child: ChoiceChip(
                                            avatar: Icon(
                                              isSelected
                                                  ? Icons.check
                                                  : Icons.tag,
                                              size: 15,
                                            ),
                                            label: Text('# $num'),
                                            selected: isSelected,
                                            selectedColor: Colors.amber.shade200,
                                            onSelected: (selected) {
                                              setState(() {
                                                _accessionNoController.text =
                                                    num.toString();
                                              });
                                            },
                                          ),
                                        );
                                      }),
                                      if (analysis.missingNumbers.length > 25 &&
                                          !_showAllMissing)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 4.0),
                                          child: ActionChip(
                                            label: Text(
                                                '+ আরো ${analysis.missingNumbers.length - 25}টি'),
                                            onPressed: () {
                                              setState(() {
                                                _showAllMissing = true;
                                              });
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) =>
                      const Text('Error loading accession numbers'),
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bookNameController,
              decoration: InputDecoration(
                labelText: t.bookNameLabel,
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? t.required : null,
            ),
            if (!isEdit) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: colorScheme.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('একাধিক খণ্ড একসাথে যুক্ত করুন',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      value: _isBulkAdd,
                      onChanged: (val) {
                        setState(() {
                          _isBulkAdd = val;
                          if (val) {
                            _accessionNoController.text = 'Auto';
                          } else if (_cachedAnalysis != null) {
                            _accessionNoController.text =
                                _cachedAnalysis!.nextAvailable.toString();
                          }
                        });
                      },
                    ),
                    if (_isBulkAdd)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextFormField(
                          controller: _bulkVolumesController,
                          decoration: const InputDecoration(
                            labelText: 'কতগুলো খণ্ড?',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (!_isBulkAdd) return null;
                            if (value == null || value.isEmpty)
                              return 'খণ্ডের সংখ্যা দিন';
                            if (int.tryParse(value) == null ||
                                int.parse(value) < 1) return 'সঠিক সংখ্যা দিন';
                            return null;
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (!_isBulkAdd) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _volumeNoController,
                decoration: InputDecoration(
                  labelText: t.volumeNoLabel,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _categoryController.text),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return allCategories;
                }
                return allCategories.where((String option) {
                  return option
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _categoryController.text = selection;
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.surface,
                    surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 280,
                        maxWidth: MediaQuery.of(context).size.width - 32,
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          final count = categoryCounts[option];
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.category_outlined,
                                      size: 18, color: Colors.grey),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: appFontFamily,
                                        fontFamilyFallback: fontFallback,
                                      ),
                                    ),
                                  ),
                                  if (count != null && count > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$countটি বই',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontFamily: appFontFamily,
                                          fontFamilyFallback: fontFallback,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              fieldViewBuilder: (context, textEditingController, focusNode,
                  onFieldSubmitted) {
                // Keep our main controller in sync if user types manually
                textEditingController.addListener(() {
                  _categoryController.text = textEditingController.text;
                });

                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  style: TextStyle(
                    fontFamily: appFontFamily,
                    fontFamilyFallback: fontFallback,
                  ),
                  decoration: InputDecoration(
                    labelText: t.category,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_drop_down, size: 28),
                      tooltip: 'সকল বিষয় দেখুন',
                      onPressed: () => _openCategoryPicker(
                        allCategories: allCategories,
                        categoryCounts: categoryCounts,
                        textEditingController: textEditingController,
                        appFontFamily: appFontFamily,
                        fontFamilyFallback: fontFallback,
                      ),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? t.required : null,
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _authorController,
              decoration: InputDecoration(
                labelText: t.author,
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? t.required : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _translatorController,
              decoration: InputDecoration(
                labelText: t.translatorLabel,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _publisherController,
              decoration: InputDecoration(
                labelText: t.publisher,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: t.addressNoteLabel,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _shelfNoController,
              decoration: InputDecoration(
                labelText: t.shelfNoLabel,
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? t.required : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<BookStatus>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: t.status,
                border: OutlineInputBorder(),
              ),
              items: BookStatus.values.map((BookStatus status) {
                String label;
                switch (status) {
                  case BookStatus.available:
                    label = 'পাওয়া যাচ্ছে';
                    break;
                  case BookStatus.lent:
                    label = 'ধার দেওয়া';
                    break;
                  case BookStatus.lost:
                    label = 'হারিয়েছে';
                    break;
                  case BookStatus.damaged:
                    label = t.bookDamagedStatus;
                    break;
                  case BookStatus.referenceOnly:
                    label = t.bookReferenceStatus;
                    break;
                }
                return DropdownMenuItem<BookStatus>(
                  value: status,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (BookStatus? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedStatus = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksController,
              decoration: InputDecoration(
                labelText: t.remarksLabel,
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 80), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _saveBook,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(t.saveBtn, style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  void _openCategoryPicker({
    required List<String> allCategories,
    required Map<String, int> categoryCounts,
    required TextEditingController textEditingController,
    required String appFontFamily,
    required List<String> fontFamilyFallback,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryPickerSheet(
        allCategories: allCategories,
        categoryCounts: categoryCounts,
        selectedCategory: _categoryController.text.trim(),
        appFontFamily: appFontFamily,
        fontFamilyFallback: fontFamilyFallback,
        onSelected: (cat) {
          textEditingController.text = cat;
          _categoryController.text = cat;
          setState(() {});
        },
      ),
    );
  }
}

class _CategoryPickerSheet extends StatefulWidget {
  final List<String> allCategories;
  final Map<String, int> categoryCounts;
  final String selectedCategory;
  final ValueChanged<String> onSelected;
  final String appFontFamily;
  final List<String> fontFamilyFallback;

  const _CategoryPickerSheet({
    required this.allCategories,
    required this.categoryCounts,
    required this.selectedCategory,
    required this.onSelected,
    required this.appFontFamily,
    required this.fontFamilyFallback,
  });

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filtered = widget.allCategories.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.toLowerCase().contains(q) ||
          BengaliTextUtils.normalizeSubject(c)
              .contains(BengaliTextUtils.normalizeSubject(q));
    }).toList();

    final isCustomQuery = _searchQuery.trim().isNotEmpty &&
        !widget.allCategories.any((c) =>
            BengaliTextUtils.isSameSubject(c, _searchQuery));

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
        maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                const Icon(Icons.category_rounded, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'বিষয় নির্বাচন করুন',
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

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              style: TextStyle(
                fontFamily: widget.appFontFamily,
                fontFamilyFallback: widget.fontFamilyFallback,
              ),
              decoration: InputDecoration(
                hintText: 'খুঁজুন বা নতুন বিষয় লিখুন...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          const SizedBox(height: 8),

          // Add custom new subject button
          if (isCustomQuery)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  widget.onSelected(_searchQuery.trim());
                  Navigator.pop(context);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: colorScheme.primary.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline_rounded,
                          color: colorScheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'নতুন বিষয়: "${_searchQuery.trim()}" যুক্ত করুন',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontFamily: widget.appFontFamily,
                            fontFamilyFallback: widget.fontFamilyFallback,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 4),

          // Category items list
          Expanded(
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cat = filtered[index];
                final count = widget.categoryCounts[cat] ?? 0;
                final isSelected =
                    cat.trim() == widget.selectedCategory.trim() ||
                    BengaliTextUtils.isSameSubject(cat, widget.selectedCategory);

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
                    cat,
                    style: TextStyle(
                      fontFamily: widget.appFontFamily,
                      fontFamilyFallback: widget.fontFamilyFallback,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? colorScheme.primary : null,
                    ),
                  ),
                  trailing: count > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
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
                        )
                      : null,
                  onTap: () {
                    widget.onSelected(cat);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
