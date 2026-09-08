import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:maktaba_ihsan/core/database/hive_helper.dart';
import 'package:maktaba_ihsan/core/models/hive_models/teacher_note.dart';
import 'package:maktaba_ihsan/core/models/hive_models/note_folder.dart';
import 'package:maktaba_ihsan/core/models/hive_models/routine_entry.dart';
import 'package:maktaba_ihsan/core/services/routine_alarm_service.dart';

class TeacherBackupService {
  static const String _kBackupGmailKey = 'teacher_backup_gmail';

  /// Retrieves the saved personal Gmail address for teacher backup.
  static String? getBackupGmail() {
    try {
      final val = HiveHelper.settingsBox.get(_kBackupGmailKey);
      if (val is String && val.trim().isNotEmpty) {
        return val.trim();
      }
    } catch (_) {}
    return null;
  }

  /// Persistently saves the teacher's personal Gmail address.
  static Future<void> setBackupGmail(String email) async {
    await HiveHelper.settingsBox.put(_kBackupGmailKey, email.trim());
  }

  /// Helper to extract plain text from Quill delta JSON if applicable.
  static String extractPlainText(String content) {
    if (content.trim().isEmpty) return '';
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        final buffer = StringBuffer();
        for (final op in decoded) {
          if (op is Map && op.containsKey('insert')) {
            buffer.write(op['insert'].toString());
          }
        }
        return buffer.toString().trim();
      }
    } catch (_) {}
    return content.trim();
  }

  /// Generates the complete backup Map with notes, folders, and routines.
  static Map<String, dynamic> generateBackupData() {
    final notes = HiveHelper.notesBox.values.map((n) => {
      'id': n.id,
      'folderId': n.folderId,
      'title': n.title,
      'content': n.content,
      'createdAt': n.createdAt.toIso8601String(),
      'updatedAt': n.updatedAt.toIso8601String(),
      'linkedBookAccessionNo': n.linkedBookAccessionNo,
    }).toList();

    final folders = HiveHelper.foldersBox.values.map((f) => {
      'id': f.id,
      'name': f.name,
      'colorHex': f.colorHex,
      'createdAt': f.createdAt.toIso8601String(),
    }).toList();

    final routines = HiveHelper.routineBox.values.map((r) => {
      'id': r.id,
      'daysOfWeek': r.daysOfWeek,
      'startTime': r.startTime,
      'endTime': r.endTime,
      'subjectName': r.subjectName,
      'className': r.className,
      'roomNumber': r.roomNumber,
      'periodNumber': r.periodNumber,
      'reminderMinutes': r.reminderMinutes,
      'nightBeforeAlarm': r.nightBeforeAlarm,
      'nightBeforeAlarmTime': r.nightBeforeAlarmTime,
      'linkedBookAccessionNo': r.linkedBookAccessionNo,
      'linkedBookName': r.linkedBookName,
      'notes': r.notes,
    }).toList();

    return {
      'app': 'Maktabatu Ihsan',
      'type': 'teacher_personal_backup',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'notesCount': notes.length,
      'foldersCount': folders.length,
      'routinesCount': routines.length,
      'notes': notes,
      'folders': folders,
      'routines': routines,
    };
  }

  /// Generates human-readable Bengali text summary for notes and routines.
  static String generateReadableSummary() {
    final nowFormatted = DateFormat('dd/MM/yyyy, hh:mm a').format(DateTime.now());
    final notes = HiveHelper.notesBox.values.toList();
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final routines = HiveHelper.routineBox.values.toList();

    final buffer = StringBuffer();
    buffer.writeln('=========================================');
    buffer.writeln('মাকতাবাতুল ইহসান - ওস্তাদদের ব্যক্তিগত ব্যাকআপ');
    buffer.writeln('তারিখ: $nowFormatted');
    buffer.writeln('মোট নোট: ${notes.length} টি | মোট রুটিন: ${routines.length} টি');
    buffer.writeln('=========================================\n');

    if (notes.isNotEmpty) {
      buffer.writeln('--- [ব্যক্তিগত নোটসমূহ] ---\n');
      for (int i = 0; i < notes.length; i++) {
        final n = notes[i];
        final plainContent = extractPlainText(n.content);
        final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(n.updatedAt);
        buffer.writeln('${i + 1}. শিরোনাম: ${n.title.isNotEmpty ? n.title : "শিরোনামহীন"}');
        buffer.writeln('   সর্বশেষ পরিবর্তন: $dateStr');
        if (n.linkedBookAccessionNo != null && n.linkedBookAccessionNo!.isNotEmpty) {
          buffer.writeln('   সম্পর্কিত কিতাব নং: ${n.linkedBookAccessionNo}');
        }
        buffer.writeln('   বিবরণ:');
        buffer.writeln('   $plainContent');
        buffer.writeln('-----------------------------------------');
      }
    }

    if (routines.isNotEmpty) {
      buffer.writeln('\n--- [ক্লাস রুটিন] ---\n');
      for (int i = 0; i < routines.length; i++) {
        final r = routines[i];
        buffer.writeln('${i + 1}. বিষয়: ${r.subjectName} (শ্রেণী: ${r.className})');
        buffer.writeln('   সময়: ${r.startTime} - ${r.endTime}');
        if (r.roomNumber != null && r.roomNumber!.isNotEmpty) {
          buffer.writeln('   রুম নং: ${r.roomNumber}');
        }
        if (r.notes != null && r.notes!.isNotEmpty) {
          buffer.writeln('   মন্তব্য: ${r.notes}');
        }
        buffer.writeln('-----------------------------------------');
      }
    }

    return buffer.toString();
  }

  /// Sends the personal backup to Gmail.
  /// Launches the mail client via mailto: or falls back to system Share.
  static Future<bool> sendBackupToGmail({String? targetEmail}) async {
    final email = targetEmail ?? getBackupGmail() ?? '';
    final subject = 'মাকতাবাতুল ইহসান - ব্যক্তিগত নোটস ও রুটিন ব্যাকআপ (${DateFormat('dd/MM/yyyy').format(DateTime.now())})';
    final summary = generateReadableSummary();

    if (email.isNotEmpty) {
      final mailtoUri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {
          'subject': subject,
          'body': summary,
        },
      );

      try {
        final launched = await launchUrl(
          mailtoUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (_) {}
    }

    // Fallback to system share sheet (which allows choosing Gmail, Drive, WhatsApp, etc.)
    await Share.share(
      summary,
      subject: subject,
    );
    return true;
  }

  /// Exports/shares full JSON backup file.
  static Future<void> shareBackupFile() async {
    final backupData = generateBackupData();
    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(backupData);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    final filename = 'maktaba_teacher_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: filename,
          mimeType: 'application/json',
        )
      ],
      subject: 'মাকতাবাতুল ইহসান - ওস্তাদদের ব্যক্তিগত ব্যাকআপ ফাইল',
      text: 'মাকতাবাতুল ইহসান অ্যাপের ওস্তাদদের ব্যক্তিগত নোটস ও রুটিন ব্যাকআপ ফাইল।',
    );
  }

  /// Copies full JSON backup string to the clipboard.
  static Future<void> copyBackupToClipboard() async {
    final backupData = generateBackupData();
    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(backupData);
    await Clipboard.setData(ClipboardData(text: jsonString));
  }

  /// Restores notes, folders, and routines from a JSON string.
  /// Returns a map of restored counts: {'notes': X, 'folders': Y, 'routines': Z}.
  static Future<Map<String, int>> restoreFromJson(String rawJson) async {
    final decoded = jsonDecode(rawJson.trim());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('অবৈধ ব্যাকআপ ফাইল ফরম্যাট!');
    }

    int restoredFolders = 0;
    int restoredNotes = 0;
    int restoredRoutines = 0;

    // Restore folders
    if (decoded['folders'] is List) {
      for (final f in decoded['folders']) {
        if (f is Map) {
          final folder = NoteFolder(
            id: f['id']?.toString() ?? '',
            name: f['name']?.toString() ?? 'অজানা ফোল্ডার',
            colorHex: f['colorHex']?.toString() ?? '#4CAF50',
            createdAt: DateTime.tryParse(f['createdAt']?.toString() ?? '') ?? DateTime.now(),
          );
          if (folder.id.isNotEmpty) {
            await HiveHelper.foldersBox.put(folder.id, folder);
            restoredFolders++;
          }
        }
      }
    }

    // Restore notes
    if (decoded['notes'] is List) {
      for (final n in decoded['notes']) {
        if (n is Map) {
          final note = TeacherNote(
            id: n['id']?.toString() ?? '',
            folderId: n['folderId']?.toString() ?? '',
            title: n['title']?.toString() ?? '',
            content: n['content']?.toString() ?? '',
            createdAt: DateTime.tryParse(n['createdAt']?.toString() ?? '') ?? DateTime.now(),
            updatedAt: DateTime.tryParse(n['updatedAt']?.toString() ?? '') ?? DateTime.now(),
            linkedBookAccessionNo: n['linkedBookAccessionNo']?.toString(),
          );
          if (note.id.isNotEmpty) {
            await HiveHelper.notesBox.put(note.id, note);
            restoredNotes++;
          }
        }
      }
    }

    // Restore routines
    if (decoded['routines'] is List) {
      for (final r in decoded['routines']) {
        if (r is Map) {
          final routine = RoutineEntry(
            id: r['id']?.toString() ?? '',
            daysOfWeek: (r['daysOfWeek'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [1],
            startTime: r['startTime']?.toString() ?? '09:00',
            endTime: r['endTime']?.toString() ?? '10:00',
            subjectName: r['subjectName']?.toString() ?? 'বিষয়',
            className: r['className']?.toString() ?? 'শ্রেণী',
            roomNumber: r['roomNumber']?.toString(),
            periodNumber: r['periodNumber']?.toString(),
            reminderMinutes: (r['reminderMinutes'] as num?)?.toInt(),
            nightBeforeAlarm: r['nightBeforeAlarm'] == true,
            nightBeforeAlarmTime: r['nightBeforeAlarmTime']?.toString(),
            linkedBookAccessionNo: r['linkedBookAccessionNo']?.toString(),
            linkedBookName: r['linkedBookName']?.toString(),
            notes: r['notes']?.toString(),
          );
          if (routine.id.isNotEmpty) {
            await HiveHelper.routineBox.put(routine.id, routine);
            restoredRoutines++;
          }
        }
      }
    }

    // Reschedule alarms for all restored routines
    if (restoredRoutines > 0) {
      await RoutineAlarmService.rescheduleAll();
    }

    return {
      'notes': restoredNotes,
      'folders': restoredFolders,
      'routines': restoredRoutines,
    };
  }

  static const String _kCloudBucket = 'A7eBxZ9EMDjrdAnWhq7g36';
  static const String _kCloudBaseUrl = 'https://kvdb.io/$_kCloudBucket';

  static String _cloudKey(String email) {
    final clean = email.toLowerCase().trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return 'teacher_vault_$clean';
  }

  static String _vaultKey(String email) => 'teacher_vault_${email.toLowerCase().trim()}';

  /// Saves the current notes, folders, and routines both to local Hive storage
  /// AND to the global cloud store so that other devices can immediately access it.
  static Future<bool> saveCurrentToCloud(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return false;

    final backupData = generateBackupData();
    final jsonString = jsonEncode(backupData);

    // 1. Save locally for instant offline persistence
    await HiveHelper.settingsBox.put(_vaultKey(cleanEmail), jsonString);

    // 2. Upload to Cloud store for cross-device synchronization
    try {
      final cloudUri = Uri.parse('$_kCloudBaseUrl/${_cloudKey(cleanEmail)}');
      final response = await http.post(
        cloudUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json, text/plain, */*',
        },
        body: jsonString,
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[TeacherBackupService] Cloud backup succeeded for $cleanEmail');
        return true;
      }
    } catch (e) {
      debugPrint('[TeacherBackupService] Cloud backup error: $e');
    }
    return false;
  }

  /// Backward-compatible alias
  static Future<void> saveCurrentToVault(String email) => saveCurrentToCloud(email);

  /// Checks if vault data exists for this Gmail locally.
  static bool hasVaultData(String email) {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return false;
    final val = HiveHelper.settingsBox.get(_vaultKey(cleanEmail));
    return val is String && val.trim().isNotEmpty;
  }

  /// Restores notes and routines from Cloud first (for cross-device data),
  /// falling back to local vault if offline.
  static Future<Map<String, dynamic>> restoreFromCloud(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) {
      throw const FormatException('জিমেইল প্রদান করা হয়নি!');
    }

    String? backupJson;
    bool fromCloud = false;

    // 1. Try Cloud fetch first (cross-device sync)
    try {
      final cloudUri = Uri.parse('$_kCloudBaseUrl/${_cloudKey(cleanEmail)}');
      final response = await http.get(
        cloudUri,
        headers: {
          'Accept': 'application/json, text/plain, */*',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        final body = response.body.trim();
        if (body.contains('"notes"') || body.contains('"type"')) {
          backupJson = body;
          fromCloud = true;
          // Update local vault cache with latest cloud data
          await HiveHelper.settingsBox.put(_vaultKey(cleanEmail), backupJson);
          debugPrint('[TeacherBackupService] Cloud backup retrieved successfully');
        }
      }
    } catch (e) {
      debugPrint('[TeacherBackupService] Cloud fetch failed: $e');
    }

    // 2. Fall back to local vault if cloud was empty or offline
    if (backupJson == null) {
      final localVal = HiveHelper.settingsBox.get(_vaultKey(cleanEmail));
      if (localVal is String && localVal.trim().isNotEmpty) {
        backupJson = localVal;
      }
    }

    if (backupJson == null) {
      throw const FormatException(
        'এই জিমেইলে ক্লাউড বা ডিভাইসে কোনো সংরক্ষিত ব্যাকআপ পাওয়া যায়নি!\n\n'
        'পরামর্শ: যে ডিভাইসে আপনি পূর্বে নোট লিখেছিলেন, সেই ডিভাইসে একবার এই জিমেইল দিয়ে ঢুকে '
        '"জিমেইলে ব্যাকআপ সংরক্ষণ করুন" বাটনে চাপ দিন। তাহলে সাথে সাথে এই ডিভাইসেও ডাটা চলে আসবে।',
      );
    }

    final counts = await restoreFromJson(backupJson);
    return {
      ...counts,
      'fromCloud': fromCloud,
    };
  }

  /// Backward-compatible alias
  static Future<Map<String, dynamic>> restoreFromVault(String email) => restoreFromCloud(email);

  /// Clears active notes and routines from the local device when logging out.
  static Future<void> clearActiveData() async {
    await HiveHelper.notesBox.clear();
    await HiveHelper.routineBox.clear();
    await RoutineAlarmService.rescheduleAll();
    await setBackupGmail('');
  }
}
