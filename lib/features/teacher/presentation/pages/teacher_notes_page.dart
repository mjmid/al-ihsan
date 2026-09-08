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
import '../widgets/teacher_backup_dialog.dart';
import 'package:maktaba_ihsan/core/services/print_service.dart';
import 'package:maktaba_ihsan/core/services/teacher_backup_service.dart';

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
          final notes = box.values.toList();
          notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // Newest first

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${t.personalNotesTitle} (${notes.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              if (notes.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.note_alt_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(t.noNotesFound, style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.settings_backup_restore_rounded, size: 18),
                          label: Text(t.restorePreviousBackup),
                          onPressed: () => TeacherBackupDialog.show(context),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                    fontSize: 18,
                                    fontFamilyFallback: [
                                      'ArabicMyLotus',
                                      'ArabicUthmanic',
                                      'UrduNastaleeq',
                                      'BengaliSolaiman',
                                    ],
                                  ),
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
                                          fontSize: 14,
                                          fontFamilyFallback: const [
                                            'ArabicMyLotus',
                                            'ArabicUthmanic',
                                            'UrduNastaleeq',
                                            'BengaliSolaiman',
                                          ],
                                      ),
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
                            onSelected: (val) async {
                              if (val == 'share_pdf') {
                                await PrintService.shareOrPrintNote(note, isShare: true);
                              } else if (val == 'print_pdf') {
                                await PrintService.shareOrPrintNote(note, isShare: false);
                              } else if (val == 'share_text') {
                                final cleanContent = TeacherBackupService.extractPlainText(note.content).trim();
                                final title = note.title.trim();
                                final textToShare = title.isNotEmpty
                                    ? '$title\n\n$cleanContent'
                                    : cleanContent;
                                Share.share(
                                  textToShare,
                                  subject: title.isNotEmpty ? title : null,
                                );
                              } else if (val == 'delete') {
                                note.delete();
                                final currentEmail = TeacherBackupService.getBackupGmail();
                                if (currentEmail != null && currentEmail.isNotEmpty) {
                                  TeacherBackupService.saveCurrentToCloud(currentEmail);
                                }
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
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Text(t.delete, style: const TextStyle(color: Colors.red)),
                                ]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              },
            ),
          ),
        ],
      );
    },
  ),
);
}
}
