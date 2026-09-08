import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/widgets/madrasa_app_bar_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maktaba_ihsan/core/database/hive_helper.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import 'package:maktaba_ihsan/core/models/hive_models/teacher_note.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:share_plus/share_plus.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:maktaba_ihsan/core/services/print_service.dart';
import 'package:maktaba_ihsan/core/services/teacher_backup_service.dart';
import 'package:maktaba_ihsan/core/providers/settings_provider.dart';
import '../widgets/pt_font_size_selector.dart';

class TeacherNoteEditorPage extends ConsumerStatefulWidget {
  final TeacherNote? note;
  const TeacherNoteEditorPage({super.key, this.note});

  /// Utility to correct phonetically recognized Arabic speech (ه ➔ ة)
  static String fixArabicTaMarbuta(String text) =>
      _TeacherNoteEditorPageState.fixArabicTaMarbuta(text);

  @override
  ConsumerState<TeacherNoteEditorPage> createState() =>
      _TeacherNoteEditorPageState();
}

class _TeacherNoteEditorPageState extends ConsumerState<TeacherNoteEditorPage> {
  late TextEditingController _titleController;
  late quill.QuillController _quillController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _editorFocusNode = FocusNode();

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _selectedLocaleId = 'bn-BD'; // Default to Bengali

  final Map<String, String> _locales = {
    'bn-BD': 'বাংলা',
    'ar-SA': 'العربية',
    'ur-PK': 'اردو',
    'en-US': 'English',
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    
    // Initialize Quill Controller
    if (widget.note != null && widget.note!.content.isNotEmpty) {
      try {
        final json = jsonDecode(widget.note!.content);
        _quillController = quill.QuillController(
          document: quill.Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // Fallback for old plain text notes
        _quillController = quill.QuillController(
          document: quill.Document()..insert(0, widget.note!.content),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      _quillController = quill.QuillController.basic();
    }

    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _titleFocusNode.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  String? _getFontForLocale(String localeId) {
    if (localeId.startsWith('ar')) {
      return 'ArabicMyLotus';
    } else if (localeId.startsWith('ur')) {
      return 'UrduNastaleeq';
    } else if (localeId.startsWith('bn')) {
      return 'BengaliSolaiman';
    }
    return null;
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          debugPrint('onStatus: $val');
          if (val == 'notListening' && mounted) {
            setState(() => _isListening = false);
          }
        },
        onError: (val) {
          debugPrint('onError: $val');
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (available) {
        setState(() => _isListening = true);
        
        // Find best matching locale from system locales
        String? bestLocaleId = _selectedLocaleId;
        try {
          var systemLocales = await _speech.locales();
          var targetLang = _selectedLocaleId.split('-')[0];
          
          for (var loc in systemLocales) {
            if (loc.localeId.startsWith(targetLang)) {
              bestLocaleId = loc.localeId;
              break;
            }
          }
        } catch (e) {
          debugPrint("Error fetching locales: $e");
        }

        _speech.listen(
          onResult: (val) => setState(() {
            if (val.finalResult) {
              var recognized = val.recognizedWords;
              if (_selectedLocaleId.startsWith('ar') ||
                  RegExp(r'[\u0600-\u06FF]').hasMatch(recognized)) {
                recognized = fixArabicTaMarbuta(recognized);
              }
              final textToInsert = '$recognized ';
              if (_titleFocusNode.hasFocus) {
                final int currentPos = _titleController.selection.base.offset;
                final pos = currentPos >= 0 ? currentPos : _titleController.text.length;
                final text = _titleController.text;
                _titleController.text = text.substring(0, pos) + textToInsert + text.substring(pos);
                _titleController.selection = TextSelection.collapsed(offset: pos + textToInsert.length);
              } else {
                final selection = _quillController.selection;
                final index = selection.baseOffset >= 0
                    ? selection.start
                    : _quillController.document.length - 1;
                final length = selection.end - selection.start;
                if (length > 0) {
                  _quillController.document.delete(index, length);
                }
                _quillController.document.insert(index, textToInsert);
                final font = _getFontForLocale(_selectedLocaleId);
                if (font != null) {
                  _quillController.formatText(
                    index,
                    textToInsert.length,
                    quill.Attribute.fromKeyValue(quill.Attribute.font.key, font),
                  );
                  _quillController.formatSelection(
                    quill.Attribute.fromKeyValue(quill.Attribute.font.key, font),
                  );
                }
                _quillController.updateSelection(
                  TextSelection.collapsed(offset: index + textToInsert.length),
                  quill.ChangeSource.local,
                );
              }
            }
          }),
          localeId: bestLocaleId,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _saveNote() {
    // Automatically auto-correct any Arabic Ta Marbuta on title and document
    final title = fixArabicTaMarbuta(_titleController.text.trim());
    
    // Auto-correct Ta Marbuta in delta operations
    final delta = _quillController.document.toDelta();
    final newOps = <Map<String, dynamic>>[];
    for (final op in delta.toJson()) {
      if (op['insert'] is String) {
        final fixed = fixArabicTaMarbuta(op['insert'] as String);
        newOps.add({'insert': fixed, if (op['attributes'] != null) 'attributes': op['attributes']});
      } else {
        newOps.add(Map<String, dynamic>.from(op));
      }
    }

    final contentJson = jsonEncode(newOps);
    final plainText = _quillController.document.toPlainText().trim();

    if (plainText.isEmpty) return;

    final note = widget.note ??
        TeacherNote(
          id: const Uuid().v4(),
          folderId: 'default',
          title: title,
          content: contentJson, // Store JSON
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    if (widget.note != null) {
      note.title = title;
      note.content = contentJson;
      note.updatedAt = DateTime.now();
      note.save();
    } else {
      HiveHelper.notesBox.put(note.id, note);
    }

    final currentEmail = TeacherBackupService.getBackupGmail();
    if (currentEmail != null && currentEmail.isNotEmpty) {
      TeacherBackupService.saveCurrentToCloud(currentEmail);
    }

    Navigator.pop(context);
  }

  /// Corrects phonetically recognized Arabic speech where words ending in
  /// Taa Marbuta (ة, U+0629) were transcribed by the speech engine as Haa (ه, U+0647).
  /// Preserves authentic Haa words, divine names, and common prepositions/pronouns.
  static String fixArabicTaMarbuta(String text) {
    if (text.isEmpty) return text;

    const authenticHaaWords = {
      'الله', 'لله', 'والله', 'بالله', 'تالله', 'إله', 'اله', 'الإله', 'الاله',
      'وجه', 'الوجه', 'أوجه', 'وجوه', 'وجها', 'بوجه',
      'فقه', 'الفقه', 'تفقه', 'فقها',
      'شبه', 'الشبه', 'يشبه', 'تشبه', 'مشابه', 'متشابه', 'شبهه',
      'مكروه', 'المكروه', 'مشبوه', 'المشبوه',
      'تنبيه', 'منبه', 'المنبه', 'نبه', 'نبّه',
      'سفيه', 'السفيه', 'فقيه', 'الفقيه', 'نزيه', 'النزيه', 'نبيه', 'النبيه', 'كريه', 'الكريه',
      'مياه', 'المياه', 'أفواه', 'افواه', 'الأفواه', 'شفاه', 'الشفاه', 'جباه', 'الجباه',
      'فواكه', 'الفواكه',
      'له', 'وله', 'فله', 'أله', 'كله',
      'به', 'وبه', 'فبه',
      'فيه', 'وفيه', 'ففيه',
      'منه', 'ومنه', 'فمنه',
      'عنه', 'وعنه', 'فعنه',
      'معه', 'ومعه', 'فمعه',
      'عليه', 'وعليه', 'فعليه',
      'إليه', 'اليه', 'وإليه', 'واليه', 'فإليه', 'فاليه',
      'لديه', 'ولديه',
      'عنده', 'وعنده', 'فعنده',
      'دونه', 'ودونه',
      'بينه', 'وبينه',
      'حوله', 'وحوله',
      'خلفه', 'أمامه', 'فوقه', 'تحته', 'نحوه', 'غيره',
      'بعضه', 'نفسه', 'عينه', 'ذاته',
      'هذه', 'وهذه', 'فهذه',
      'أبوه', 'ابوه', 'أخوه', 'اخوه',
      'كره', 'يكره', 'شوه', 'يشوه', 'تاه', 'يتوه',
    };

    final wordRegex = RegExp(r'([\u0600-\u06FF]+)');
    return text.replaceAllMapped(wordRegex, (match) {
      final word = match.group(1)!;
      if (!word.endsWith('ه') && !word.endsWith('\u0647')) {
        return word;
      }
      if (authenticHaaWords.contains(word)) {
        return word;
      }
      // Any word with definite article 'ال' ending in 'ه' is ALWAYS Taa Marbuta 'ة'
      if (word.startsWith('ال') && word.length > 3) {
        return '${word.substring(0, word.length - 1)}ة';
      }
      // General words of 3+ letters ending with 'ه' in speech dictation
      if (word.length >= 3) {
        return '${word.substring(0, word.length - 1)}ة';
      }
      return word;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationProvider);
    final settings = ref.watch(appSettingsProvider);
    final locale = settings.locale.languageCode;

    final String appFontFamily;
    final List<String> fontFallback;
    if (locale == 'ar') {
      appFontFamily = 'ArabicMyLotus';
      fontFallback = const ['BengaliSolaiman', 'UrduNastaleeq', 'ArabicUthmanic'];
    } else if (locale == 'ur') {
      appFontFamily = 'UrduNastaleeq';
      fontFallback = const ['ArabicMyLotus', 'BengaliSolaiman', 'ArabicUthmanic'];
    } else {
      appFontFamily = 'BengaliSolaiman';
      fontFallback = const ['ArabicMyLotus', 'ArabicUthmanic', 'UrduNastaleeq'];
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 96,
        title: MadrasaAppBarTitle(
            title: widget.note == null
                ? t.newNote
                : t.editNote),
        actions: [
          PopupMenuButton<String>(
            tooltip: t.voiceLanguage,
            icon: Row(
              children: [
                const Icon(Icons.language, size: 20),
                const SizedBox(width: 4),
                Text(
                  _locales[_selectedLocaleId]!,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            onSelected: (val) {
              setState(() {
                _selectedLocaleId = val;
                if (_isListening) {
                  _speech.stop();
                  _isListening = false;
                }
                final font = _getFontForLocale(val);
                if (font != null) {
                  _quillController.formatSelection(
                    quill.Attribute.fromKeyValue(quill.Attribute.font.key, font),
                  );
                }
              });
            },
            itemBuilder: (context) => _locales.entries
                .map((e) => PopupMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ))
                .toList(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.share),
            tooltip: t.shareAction,
            onSelected: (val) async {
              final title = _titleController.text.trim();
              final contentJson = jsonEncode(_quillController.document.toDelta().toJson());
              final plainText = _quillController.document.toPlainText().trim();
              final noteToShare = widget.note?.copyWith(
                    title: title,
                    content: contentJson,
                  ) ??
                  TeacherNote(
                    id: 'temp',
                    folderId: '',
                    title: title,
                    content: contentJson,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

              if (val == 'share_pdf') {
                await PrintService.shareOrPrintNote(noteToShare, isShare: true);
              } else if (val == 'print_pdf') {
                await PrintService.shareOrPrintNote(noteToShare, isShare: false);
              } else if (val == 'share_text') {
                final textToShare = title.isNotEmpty
                    ? '$title\n\n$plainText'
                    : plainText;
                Share.share(
                  textToShare,
                  subject: title.isNotEmpty ? title : null,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'share_pdf',
                child: Row(children: [
                  const Icon(Icons.picture_as_pdf_outlined, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(t.shareAsPdf),
                ]),
              ),
              PopupMenuItem(
                value: 'print_pdf',
                child: Row(children: [
                  const Icon(Icons.print_outlined, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(t.printNote),
                ]),
              ),
              PopupMenuItem(
                value: 'share_text',
                child: Row(children: [
                  const Icon(Icons.text_fields_rounded, color: Colors.teal, size: 20),
                  const SizedBox(width: 8),
                  Text(t.shareAsText),
                ]),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNote,
          )
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        backgroundColor:
            _isListening ? Colors.red : Theme.of(context).colorScheme.primary,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none,
            color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: quill.QuillToolbar.simple(
              controller: _quillController,
              configurations: quill.QuillSimpleToolbarConfigurations(
                sharedConfigurations: quill.QuillSharedConfigurations(
                  locale: Locale(ref.watch(appSettingsProvider).locale.languageCode),
                ),
                multiRowsDisplay: false, // Single sleek scrolling row
                showFontFamily: true,
                fontFamilyValues: const {
                  'বাংলা (Solaiman)': 'BengaliSolaiman',
                  'বাংলা (Ekushey)': 'EkusheyBelycon',
                  'العربية (MyLotus)': 'ArabicMyLotus',
                  'العربية (Uthmanic)': 'ArabicUthmanic',
                  'اردو (Jameel Nastaleeq)': 'UrduNastaleeq',
                  'Clear': 'Clear',
                },
                showFontSize: true,
                fontSizesValues: const {
                  '8 pt': '8',
                  '9 pt': '9',
                  '10 pt': '10',
                  '11 pt': '11',
                  '12 pt': '12',
                  '13 pt': '13',
                  '14 pt': '14',
                  '15 pt': '15',
                  '16 pt': '16',
                  '18 pt': '18',
                  '20 pt': '20',
                  '22 pt': '22',
                  '24 pt': '24',
                  '26 pt': '26',
                  '28 pt': '28',
                  '32 pt': '32',
                  '36 pt': '36',
                  '40 pt': '40',
                  '48 pt': '48',
                  '56 pt': '56',
                  '64 pt': '64',
                  '72 pt': '72',
                  '96 pt': '96',
                  'ডিফল্ট রিসেট': '0',
                },
                showHeaderStyle: true,
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showColorButton: true,
                showAlignmentButtons: true,
                showListNumbers: true,
                showListBullets: true,
                showCodeBlock: false,
                showInlineCode: false,
                showSubscript: false,
                showSuperscript: false,
                showSearchButton: false,
                showBackgroundColorButton: false,
                showStrikeThrough: false,
                showClearFormat: true,
                buttonOptions: quill.QuillSimpleToolbarButtonOptions(
                  fontSize: quill.QuillToolbarFontSizeButtonOptions(
                    childBuilder: (options, extraOptions) {
                      return PtFontSizeSelectorWidget(
                        controller: extraOptions.controller,
                      );
                    },
                  ),
                  base: quill.QuillToolbarBaseButtonOptions(
                    iconTheme: quill.QuillIconTheme(
                      iconButtonSelectedData: quill.IconButtonData(
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      iconButtonUnselectedData: quill.IconButtonData(
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    focusNode: _titleFocusNode,
                    controller: _titleController,
                    style: TextStyle(
                      fontFamily: appFontFamily,
                      fontFamilyFallback: fontFallback,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: t.titlePlaceholder,
                      hintStyle: TextStyle(
                        fontFamily: appFontFamily,
                        fontFamilyFallback: fontFallback,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: quill.QuillEditor.basic(
                      controller: _quillController,
                      focusNode: _editorFocusNode,
                      configurations: quill.QuillEditorConfigurations(
                        sharedConfigurations: quill.QuillSharedConfigurations(
                          locale: Locale(ref.watch(appSettingsProvider).locale.languageCode),
                        ),
                        placeholder: t.contentPlaceholder,
                        padding: const EdgeInsets.only(bottom: 120),
                        customStyles: quill.DefaultStyles(
                          paragraph: quill.DefaultTextBlockStyle(
                            TextStyle(
                              fontFamily: appFontFamily,
                              fontFamilyFallback: fontFallback,
                              fontSize: 16,
                              height: 1.45,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const quill.HorizontalSpacing(0, 0),
                            const quill.VerticalSpacing(6, 0),
                            quill.VerticalSpacing.zero,
                            null,
                          ),
                          h1: quill.DefaultTextBlockStyle(
                            TextStyle(
                              fontFamily: appFontFamily,
                              fontFamilyFallback: fontFallback,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const quill.HorizontalSpacing(0, 0),
                            const quill.VerticalSpacing(12, 0),
                            quill.VerticalSpacing.zero,
                            null,
                          ),
                          h2: quill.DefaultTextBlockStyle(
                            TextStyle(
                              fontFamily: appFontFamily,
                              fontFamilyFallback: fontFallback,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const quill.HorizontalSpacing(0, 0),
                            const quill.VerticalSpacing(10, 0),
                            quill.VerticalSpacing.zero,
                            null,
                          ),
                          h3: quill.DefaultTextBlockStyle(
                            TextStyle(
                              fontFamily: appFontFamily,
                              fontFamilyFallback: fontFallback,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const quill.HorizontalSpacing(0, 0),
                            const quill.VerticalSpacing(8, 0),
                            quill.VerticalSpacing.zero,
                            null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
