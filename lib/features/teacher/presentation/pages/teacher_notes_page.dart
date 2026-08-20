import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maktaba_ihsan/core/database/hive_helper.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import 'package:maktaba_ihsan/core/models/hive_models/teacher_note.dart';
import 'package:maktaba_ihsan/core/theme/neu_card.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'teacher_note_editor_page.dart';

class TeacherNotesPage extends ConsumerWidget {
  const TeacherNotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TeacherNoteEditorPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder(
        valueListenable: HiveHelper.notesBox.listenable(),
        builder: (context, Box<TeacherNote> box, _) {
          final t = ref.watch(translationProvider);
          if (box.isEmpty) {
            return Center(child: Text(t.noNotesFound));
          }

          final notes = box.values.toList();
          notes.sort(
              (a, b) => b.updatedAt.compareTo(a.updatedAt)); // Newest first

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: NeuCard(
                  padding: const EdgeInsets.all(0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => TeacherNoteEditorPage(note: note)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.sticky_note_2_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.title.isNotEmpty
                                      ? note.title
                                      : t.untitled,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Builder(
                                  builder: (context) {
                                    String previewText = note.content;
                                    try {
                                      final json = jsonDecode(note.content);
                                      if (json is List) {
                                        previewText = json.map((op) => op['insert']?.toString() ?? '').join();
                                      }
                                    } catch (_) {
                                      // It's plain text, keep as is
                                    }
                                    return Text(
                                      previewText,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontSize: 14),
                                    );
                                  }
                                ),
                                const SizedBox(height: 12),
                                Divider(
                                    height: 1,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant
                                        .withOpacity(0.5)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.access_time_rounded,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateFormat('dd MMM yyyy, hh:mm a')
                                          .format(note.updatedAt),
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            onSelected: (val) {
                              if (val == 'share') {
                                String shareText = note.content;
                                try {
                                  final json = jsonDecode(note.content);
                                  if (json is List) {
                                    shareText = json.map((op) => op['insert']?.toString() ?? '').join();
                                  }
                                } catch (_) {}
                                Share.share('${note.title}\n\n$shareText');
                              } else if (val == 'delete') {
                                note.delete();
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                  value: 'share',
                                  child: Row(children: [
                                    const Icon(Icons.share_outlined, size: 20),
                                    const SizedBox(width: 8),
                                    Text(t.share)
                                  ])),
                              PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [
                                    const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 20),
                                    const SizedBox(width: 8),
                                    Text(t.delete,
                                        style:
                                            const TextStyle(color: Colors.red))
                                  ])),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
