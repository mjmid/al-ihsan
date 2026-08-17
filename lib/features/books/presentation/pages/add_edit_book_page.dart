import 'package:flutter/material.dart';
import '../../../../../core/widgets/madrasa_app_bar_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/models/book_model.dart';
import '../../../../../core/providers/providers.dart';
import '../../../../../core/providers/book_providers.dart';
import '../../../../../core/l10n/app_translations.dart';

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

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
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
                        if (analysis.missingNumbers.isNotEmpty && !isEdit) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'মাঝে এই নম্বরগুলো ফাঁকা আছে:\n${analysis.missingNumbers.take(15).join(', ')}${analysis.missingNumbers.length > 15 ? '...' : ''}',
                                    style: TextStyle(
                                        color: Colors.orange.shade900),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _accessionNoController,
                          decoration: InputDecoration(
                            labelText: t.accessionNo,
                            border: OutlineInputBorder(),
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
                  return _categoryPresets;
                }
                return _categoryPresets.where((String option) {
                  return option
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _categoryController.text = selection;
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
                  decoration: InputDecoration(
                    labelText: t.category,
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? t.required : null,
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
}
