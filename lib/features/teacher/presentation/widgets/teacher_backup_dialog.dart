import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import 'package:maktaba_ihsan/core/services/teacher_backup_service.dart';
import 'package:maktaba_ihsan/core/database/hive_helper.dart';

class TeacherBackupDialog extends ConsumerStatefulWidget {
  const TeacherBackupDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const TeacherBackupDialog(),
    );
  }

  @override
  ConsumerState<TeacherBackupDialog> createState() => _TeacherBackupDialogState();
}

class _TeacherBackupDialogState extends ConsumerState<TeacherBackupDialog> {
  String? _savedEmail;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _savedEmail = TeacherBackupService.getBackupGmail();
    _emailController = TextEditingController(text: _savedEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loginEmail() async {
    final t = ref.read(translationProvider);
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.invalidEmailMsg),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await TeacherBackupService.setBackupGmail(email);
      setState(() {
        _savedEmail = email;
      });

      // Try restoring from Cloud or local vault for this Gmail
      try {
        final counts = await TeacherBackupService.restoreFromCloud(email);
        final int notesCount = counts['notes'] as int? ?? 0;
        final int routinesCount = counts['routines'] as int? ?? 0;
        final bool fromCloud = counts['fromCloud'] == true;

        if (notesCount > 0 || routinesCount > 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  fromCloud
                      ? t.loginSuccessCloudMsg
                      : t.allPreviousDataRestored,
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      } catch (_) {}

      // If cloud had no notes, but this device currently has notes/routines,
      // upload them to the cloud so they become accessible from other devices!
      final hasLocalData = HiveHelper.notesBox.isNotEmpty || HiveHelper.routineBox.isNotEmpty;
      if (hasLocalData) {
        await TeacherBackupService.saveCurrentToCloud(email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.backupSuccessMsg),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.loginSuccessMsg),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.loginErrorMsg}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logoutEmail() async {
    final t = ref.read(translationProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 8),
            Text(t.confirmLogoutTitle),
          ],
        ),
        content: Text(t.confirmLogoutDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.no),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.yesLogout),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      if (_savedEmail != null && _savedEmail!.isNotEmpty) {
        // Ensure latest data is safely backed up in vault before clearing
        await TeacherBackupService.saveCurrentToVault(_savedEmail!);
      }

      // Clear all active data from the device
      await TeacherBackupService.clearActiveData();

      setState(() {
        _savedEmail = null;
        _emailController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.logoutSuccessMsg),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreDirectly() async {
    final t = ref.read(translationProvider);
    if (_savedEmail == null || _savedEmail!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.pleaseLoginFirst),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final counts = await TeacherBackupService.restoreFromCloud(_savedEmail!);
      final int notesCount = counts['notes'] as int? ?? 0;
      final int routinesCount = counts['routines'] as int? ?? 0;
      final bool fromCloud = counts['fromCloud'] == true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${t.allPreviousDataRestored}\n'
              '• $notesCount ${t.notes}\n'
              '• $routinesCount ${t.routine}'
              '${fromCloud ? "\n(Cloud Sync)" : ""}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '').replaceAll('FormatException: ', '')),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendToGmail() async {
    final t = ref.read(translationProvider);
    if (_savedEmail == null || _savedEmail!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.pleaseLoginFirst),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Save to Cloud and local vault
      await TeacherBackupService.saveCurrentToCloud(_savedEmail!);

      // 2. Also send to Gmail client
      await TeacherBackupService.sendBackupToGmail(targetEmail: _savedEmail);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.backupSuccessMsg),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.backupErrorMsg}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFileOrCodeRestoreDialog() {
    final t = ref.read(translationProvider);
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.file_upload_outlined, color: Colors.teal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.restoreModalTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.pasteBackupCodeHint,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              maxLines: 6,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: t.pasteHerePlaceholder,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final raw = textController.text.trim();
              if (raw.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                final counts = await TeacherBackupService.restoreFromJson(raw);
                if (_savedEmail != null && _savedEmail!.isNotEmpty) {
                  await TeacherBackupService.saveCurrentToCloud(_savedEmail!);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${t.restoreSuccessMsg}\n• ${counts['notes']} ${t.notes}\n• ${counts['routines']} ${t.routine}',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${t.restoreErrorMsg}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: Text(t.restoreActionBtn),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLoggedIn = _savedEmail != null && _savedEmail!.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.mark_email_read_outlined, color: colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.personalBackupGmail,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        t.backupDialogSubtitle,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (isLoggedIn) ...[
              // Logged in card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.loggedInStatus,
                            style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _savedEmail!,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.logout, size: 16),
                      label: Text(t.logoutBtn, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: _isLoading ? null : _logoutEmail,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Button 1: Send / Save Backup
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA4335), // Google Red
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload_outlined, size: 20),
                  label: Text(
                    t.saveToGmailBtn,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isLoading ? null : _sendToGmail,
                ),
              ),
              const SizedBox(height: 10),

              // Button 2: 1-Click Restore
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    side: const BorderSide(color: Colors.teal, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.settings_backup_restore_rounded, size: 20),
                  label: Text(
                    t.restorePreviousDataBtn,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isLoading ? null : _restoreDirectly,
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton.icon(
                  onPressed: _isLoading ? null : _showFileOrCodeRestoreDialog,
                  icon: const Icon(Icons.code_rounded, size: 16),
                  label: Text(
                    t.restoreFromFileOrCodeBtn,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ] else ...[
              // Not logged in: Simple Login form
              Text(
                t.enterYourGmail,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'example@gmail.com',
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: Text(
                    t.loginBtn,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isLoading ? null : _loginEmail,
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton.icon(
                  onPressed: _isLoading ? null : _showFileOrCodeRestoreDialog,
                  icon: const Icon(Icons.code_rounded, size: 16),
                  label: Text(
                    t.orRestoreWithCodeBtn,
                    style: const TextStyle(fontSize: 12),
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
