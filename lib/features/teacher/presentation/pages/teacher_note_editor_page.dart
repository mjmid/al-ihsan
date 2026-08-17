import 'package:flutter/material.dart';
import '../../../../core/widgets/madrasa_app_bar_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maktaba_ihsan/core/database/hive_helper.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import 'package:maktaba_ihsan/core/models/hive_models/teacher_note.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:share_plus/share_plus.dart';

class TeacherNoteEditorPage extends ConsumerStatefulWidget {
  final TeacherNote? note;
  const TeacherNoteEditorPage({super.key, this.note});

  @override
  ConsumerState<TeacherNoteEditorPage> createState() =>
      _TeacherNoteEditorPageState();
}

class _TeacherNoteEditorPageState extends ConsumerState<TeacherNoteEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            // Append speech text to content
            if (val.finalResult) {
              _contentController.text = _contentController.text +
                  (_contentController.text.isEmpty ? '' : ' ') +
                  val.recognizedWords;
              // Wait for a short moment then we can stop or keep listening
            }
          }),
          localeId: 'bn_BD', // Default to Bengali
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (content.isEmpty) return;

    final note = widget.note ??
        TeacherNote(
          id: const Uuid().v4(),
          folderId: 'default',
          title: title,
          content: content,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    if (widget.note != null) {
      note.title = title;
      note.content = content;
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
          if (widget.note != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                Share.share(
                    '${_titleController.text}\n\n${_contentController.text}');
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: t.titlePlaceholder,
                border: InputBorder.none,
              ),
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: t.contentPlaceholder,
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
