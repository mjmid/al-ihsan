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

class TeacherNoteEditorPage extends ConsumerStatefulWidget {
  final TeacherNote? note;
  const TeacherNoteEditorPage({super.key, this.note});

  @override
  ConsumerState<TeacherNoteEditorPage> createState() =>
      _TeacherNoteEditorPageState();
}

class _TeacherNoteEditorPageState extends ConsumerState<TeacherNoteEditorPage> {
  late TextEditingController _titleController;
  late quill.QuillController _quillController;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _selectedLocaleId = 'bn_BD'; // Default to Bengali

  final Map<String, String> _locales = {
    'bn_BD': 'বাংলা',
    'ar_SA': 'العربية',
    'ur_PK': 'اردو',
    'en_US': 'English',
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
    super.dispose();
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
        _speech.listen(
          onResult: (val) => setState(() {
            if (val.finalResult) {
              final textToInsert = val.recognizedWords + ' ';
              final index = _quillController.document.length - 1;
              _quillController.document.insert(index, textToInsert);
              _quillController.updateSelection(TextSelection.collapsed(offset: index + textToInsert.length), quill.ChangeSource.local);
            }
          }),
          localeId: _selectedLocaleId,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    
    // Convert quill document to JSON string
    final contentJson = jsonEncode(_quillController.document.toDelta().toJson());
    // Also extract plain text for preview in the list
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

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationProvider);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        title: MadrasaAppBarTitle(
            title: widget.note == null
                ? t.newNote
                : 'Note'), // edit note trans missing, keeping it simple
        actions: [
          PopupMenuButton<String>(
            tooltip: 'ভয়েস ভাষা',
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
              });
            },
            itemBuilder: (context) => _locales.entries
                .map((e) => PopupMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ))
                .toList(),
          ),
          if (widget.note != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                final plainText = _quillController.document.toPlainText();
                Share.share(
                    '${_titleController.text}\n\n$plainText');
              },
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
              configurations: quill.QuillSimpleToolbarConfigurations(
                controller: _quillController,
                sharedConfigurations: const quill.QuillSharedConfigurations(
                  locale: Locale('bn'),
                ),
                multiRowsDisplay: false, // Single sleek scrolling row
                showFontFamily: false,
                showFontSize: false,
                showCodeBlock: false,
                showInlineCode: false,
                showSubscript: false,
                showSuperscript: false,
                showSearchButton: false,
                showBackgroundColorButton: false,
                showStrikeThrough: false,
                showClearFormat: true,
                buttonOptions: quill.QuillSimpleToolbarButtonOptions(
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
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: t.titlePlaceholder,
                      hintStyle: TextStyle(
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
                      configurations: quill.QuillEditorConfigurations(
                        controller: _quillController,
                        sharedConfigurations: const quill.QuillSharedConfigurations(
                          locale: Locale('bn'),
                        ),
                        placeholder: t.contentPlaceholder,
                        padding: const EdgeInsets.only(bottom: 120),
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
