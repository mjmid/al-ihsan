import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maktaba_ihsan/core/providers/settings_provider.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import 'package:maktaba_ihsan/core/theme/neu_card.dart';
import 'package:maktaba_ihsan/features/auth/presentation/pages/login_page.dart';
import 'package:maktaba_ihsan/core/providers/auth_provider.dart';
import 'package:maktaba_ihsan/core/providers/mode_provider.dart';
import 'package:maktaba_ihsan/core/providers/providers.dart';
import 'package:maktaba_ihsan/core/services/supabase_client.dart';
import 'package:maktaba_ihsan/core/models/user_model.dart';
import 'package:maktaba_ihsan/features/teacher/presentation/widgets/teacher_backup_dialog.dart';
import 'package:maktaba_ihsan/features/books/presentation/pages/csv_import_books_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:maktaba_ihsan/core/services/pwa_install/pwa_install_service.dart';
import 'package:maktaba_ihsan/core/widgets/app_install_bottom_banner.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final themeMode = settings.themeMode;
    final locale = settings.locale.languageCode;
    final t = ref.watch(translationProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authProvider);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Profile Section
        if (authState.userId != null) ...[
          _buildProfileSection(context, authState),
          const SizedBox(height: 24),
        ],

        // Theme Section
        _buildSectionHeader(context, Icons.brush, t.themeSetting),
        const SizedBox(height: 12),
        _buildSegmentedControl(
          context: context,
          children: [
            _SegmentData(
              icon: Icons.light_mode,
              label: 'Light',
              isSelected: themeMode == ThemeMode.light,
              onTap: () => ref
                  .read(appSettingsProvider.notifier)
                  .setThemeMode(ThemeMode.light),
            ),
            _SegmentData(
              icon: Icons.dark_mode,
              label: 'Dark',
              isSelected: themeMode == ThemeMode.dark,
              onTap: () => ref
                  .read(appSettingsProvider.notifier)
                  .setThemeMode(ThemeMode.dark),
            ),
            _SegmentData(
              icon: Icons.brightness_auto,
              label: 'System',
              isSelected: themeMode == ThemeMode.system,
              onTap: () => ref
                  .read(appSettingsProvider.notifier)
                  .setThemeMode(ThemeMode.system),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Language Section
        _buildSectionHeader(context, Icons.translate, t.languageSetting),
        const SizedBox(height: 12),
        _buildSegmentedControl(
          context: context,
          children: [
            _SegmentData(
              label: 'বাংলা',
              isSelected: locale == 'bn',
              onTap: () =>
                  ref.read(appSettingsProvider.notifier).setLanguage('bn'),
            ),
            _SegmentData(
              label: 'English',
              isSelected: locale == 'en',
              onTap: () =>
                  ref.read(appSettingsProvider.notifier).setLanguage('en'),
            ),
            _SegmentData(
              label: 'العربية',
              isSelected: locale == 'ar',
              onTap: () =>
                  ref.read(appSettingsProvider.notifier).setLanguage('ar'),
            ),
            _SegmentData(
              label: 'اردو',
              isSelected: locale == 'ur',
              onTap: () =>
                  ref.read(appSettingsProvider.notifier).setLanguage('ur'),
            ),
          ],
        ),

        const SizedBox(height: 24),

        if (authState.userType == UserType.admin) ...[
          _buildSectionHeader(
              context, Icons.admin_panel_settings, t.adminOptions),
          const SizedBox(height: 12),
          _buildManagementCard(
            context: context,
            icon: Icons.admin_panel_settings,
            iconColor: Colors.green,
            title: t.useTeacherDashboard,
            subtitle: t.teacherDashboardDesc,
            trailing: Switch(
              value: ref.watch(actingAsTeacherProvider),
              onChanged: (val) =>
                  ref.read(actingAsTeacherProvider.notifier).state = val,
              activeColor: Colors.white,
              activeTrackColor: colorScheme.primary,
            ),
            onTap: () {
              ref.read(actingAsTeacherProvider.notifier).state =
                  !ref.watch(actingAsTeacherProvider);
            },
          ),
          const SizedBox(height: 12),
          _buildManagementCard(
            context: context,
            icon: Icons.chat_rounded,
            iconColor: const Color(0xFF25D366),
            title: t.adminWhatsAppNumberLabel,
            subtitle: (settings.adminWhatsAppNumber != null &&
                    settings.adminWhatsAppNumber!.trim().isNotEmpty)
                ? settings.adminWhatsAppNumber!
                : 'সেট করা নেই — ক্লিক করে সেট করুন',
            onTap: () {
              _showAdminWhatsAppDialog(context, ref);
            },
          ),
          const SizedBox(height: 12),
          _buildManagementCard(
            context: context,
            icon: Icons.upload_file_rounded,
            iconColor: Colors.deepPurple,
            title: 'কিতাব বাল্ক ইম্পোর্ট (.csv)',
            subtitle: 'গুগল শিট থেকে .csv আপলোড করে একসাথে কিতাব যুক্ত করুন',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CsvImportBooksPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],

        // Teacher Backup & Gmail Section
        _buildSectionHeader(context, Icons.shield_outlined, t.teacherBackupSectionHeader),
        const SizedBox(height: 12),
        _buildManagementCard(
          context: context,
          icon: Icons.mark_email_read_outlined,
          iconColor: Colors.teal,
          title: t.teacherBackupCardTitle,
          subtitle: t.teacherBackupCardSubtitle,
          onTap: () {
            TeacherBackupDialog.show(context);
          },
        ),
        const SizedBox(height: 24),

        // Installation & App Update Section
        _buildSectionHeader(context, Icons.system_update_rounded, 'ইনস্টলেশন ও আপডেট'),
        const SizedBox(height: 12),
        _buildManagementCard(
          context: context,
          icon: Icons.install_mobile_rounded,
          iconColor: Colors.teal,
          title: 'অ্যাপ ইনস্টল করুন',
          subtitle: PwaInstallService.isAppInstalled()
              ? 'অ্যাপটি ইতিমধ্যে ডিভাইসে ইনস্টল করা আছে'
              : 'পিসি, অ্যান্ড্রয়েড বা আইফোনে সরাসরি ইনস্টল করুন',
          trailing: PwaInstallService.isAppInstalled()
              ? const Icon(Icons.check_circle_rounded, color: Colors.green)
              : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () {
            AppInstallBottomBanner.showInstallDialog(context);
          },
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          context: context,
          icon: Icons.sync_rounded,
          iconColor: Colors.blue,
          title: 'অ্যাপ আপডেট চেক করুন',
          subtitle: 'বর্তমান ভার্সন v${PwaInstallService.currentVersion} • নতুন আপডেট দেখুন',
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () {
            _handleCheckUpdate(context);
          },
        ),
        const SizedBox(height: 24),

        // Management Section
        _buildSectionHeader(context, Icons.account_circle, t.management),
        const SizedBox(height: 12),
        _buildManagementCard(
          context: context,
          icon: Icons.logout,
          iconColor: Colors.orange,
          title: t.logout,
          subtitle: t.logoutDesc,
          onTap: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            }
          },
        ),

        const SizedBox(height: 32),
        // Developer Credit
        Center(
          child: Text(
            'Developed by Habibullah Foridi',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProfileSection(BuildContext context, AuthState authState) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = authState.userName ?? 'Unknown User';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final String role;
    switch (authState.userType) {
      case UserType.admin:
        role = 'Owner';
        break;
      case UserType.principal:
        role = 'প্রিন্সিপাল';
        break;
      case UserType.educationSecretary:
        role = 'শিক্ষা সচিব';
        break;
      case UserType.teacher:
        role = 'শিক্ষক';
        break;
      case UserType.student:
        role = 'ছাত্র';
        break;
      case null:
        role = 'ব্যবহারকারী';
        break;
    }

    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Circular Avatar with initial
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(
                            color: Colors.deepOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      authState.userPhone ?? 'N/A',
                      style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl({
    required BuildContext context,
    required List<_SegmentData> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: children.map((data) {
          return Expanded(
            child: GestureDetector(
              onTap: data.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: data.isSelected
                      ? colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (data.icon != null) ...[
                      Icon(
                        data.icon,
                        size: 18,
                        color: data.isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      data.label,
                      style: TextStyle(
                        fontWeight: data.isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: data.isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildManagementCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: NeuCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 13)),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _SegmentData {
  final IconData? icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  _SegmentData({
    this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
}

void _showAdminWhatsAppDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) => const _AdminWhatsAppDialog(),
  );
}

class _AdminWhatsAppDialog extends ConsumerStatefulWidget {
  const _AdminWhatsAppDialog();

  @override
  ConsumerState<_AdminWhatsAppDialog> createState() => _AdminWhatsAppDialogState();
}

class _AdminWhatsAppDialogState extends ConsumerState<_AdminWhatsAppDialog> {
  late TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(appSettingsProvider).adminWhatsAppNumber ?? '';
    _controller = TextEditingController(text: current);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = ref.read(translationProvider);
    final number = _controller.text.trim();

    setState(() => _isLoading = true);
    try {
      // 1. Save to local settings (Hive)
      await ref.read(appSettingsProvider.notifier).setAdminWhatsAppNumber(number);

      // 2. Update local SQLite users table for Admin
      final db = await ref.read(databaseHelperProvider).database;
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      await db.rawUpdate(
        "UPDATE users SET phone = ?, last_updated = ? WHERE LOWER(type) = 'admin'",
        [number, nowUtc],
      );

      // 3. Enqueue change to GAS and Supabase if active
      ref.read(syncQueueProvider.notifier).enqueue(
        SyncOperation.create(
          sheet: 'Users',
          action: 'upsert',
          payload: {
            'user_id': 'admin',
            'phone': number,
            'last_updated': nowUtc,
          },
        ),
      );
      try {
        await supabaseClient
            .from('users')
            .update({'phone': number, 'last_updated': nowUtc})
            .ilike('type', 'admin');
      } catch (_) {}

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(t.adminWhatsAppSavedSuccess)),
              ],
            ),
            backgroundColor: const Color(0xFF25D366),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ত্রুটি: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationProvider);
    final settings = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentNumber = settings.adminWhatsAppNumber;
    final hasNumber = currentNumber != null && currentNumber.trim().isNotEmpty;

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
                    color: const Color(0xFF25D366).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.adminWhatsAppNumberLabel,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'শিক্ষকদের বই রিকোয়েস্ট এই নম্বরে আসবে',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
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
            const SizedBox(height: 18),

            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasNumber
                    ? const Color(0xFF25D366).withOpacity(0.08)
                    : Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasNumber
                      ? const Color(0xFF25D366).withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasNumber ? Icons.check_circle : Icons.info_outline,
                    color: hasNumber ? const Color(0xFF25D366) : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasNumber
                          ? 'বর্তমান নম্বর: $currentNumber'
                          : 'কোনো হোয়াটসঅ্যাপ নম্বর যুক্ত নেই',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hasNumber
                            ? (isDark ? const Color(0xFF5BE29B) : const Color(0xFF1E7E34))
                            : Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Input Field
            TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'হোয়াটসঅ্যাপ নম্বর লিখুন',
                hintText: '০১৭১২৩৪৫৬৭৮ বা +৮৮০১...',
                prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF25D366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'নোট: শিক্ষকরা কিতাব ধার নেওয়ার রিকোয়েস্ট পাঠানোর সময় সরাসরি এই নম্বরে হোয়াটসঅ্যাপ মেসেজ পাঠাতে পারবেন।',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 22),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t.cancel),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    t.saveBtn,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isLoading ? null : _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _handleCheckUpdate(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('আপডেট চেক করা হচ্ছে...', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    ),
  );

  final info = await PwaInstallService.checkForUpdate();

  if (context.mounted) {
    Navigator.pop(context); // close loader
  }

  if (!context.mounted) return;

  if (info == null) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('আপডেট চেক ব্যর্থ হয়েছে'),
        content: const Text(
          'সার্ভারের সাথে সংযোগ স্থাপন করা যায়নি। আপনার ইন্টারনেট সংযোগ পরীক্ষা করে পুনরায় চেষ্টা করুন।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
    return;
  }

  if (!info.hasUpdate) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF1F9E5C)),
            SizedBox(width: 8),
            Text('অ্যাপ আপ-টু-ডেট আছে'),
          ],
        ),
        content: Text(
          'আপনার অ্যাপটি ইতিমধ্যে সর্বশেষ ভার্সনে (v${info.currentVersion}) আছে। নতুন কোনো আপডেট নেই।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
    return;
  }

  // Update is available
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1F9E5C).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.system_update_rounded, color: Color(0xFF1F9E5C)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'নতুন আপডেট পাওয়া গেছে! (v${info.latestVersion})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (info.releaseDate.isNotEmpty) ...[
              Text(
                'প্রকাশের তারিখ: ${info.releaseDate}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (info.changelog.isNotEmpty) ...[
              const Text(
                'নতুন কী আসছে:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(info.changelog, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
            ],
            Text(
              PwaInstallService.isWeb
                  ? 'এখনই আপডেট বোতামে চাপলে নতুন ফাইল লোড হয়ে অ্যাপ স্বয়ংক্রিয়ভাবে আপডেট হয়ে যাবে।'
                  : 'নতুন APK ফাইলটি ডাউনলোড করে ইনস্টল করে আপডেট সম্পন্ন করুন।',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('পরে'),
        ),
        if (PwaInstallService.isWeb) ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1F9E5C),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('এখনই আপডেট করুন'),
            onPressed: () async {
              Navigator.pop(ctx);
              await PwaInstallService.forceUpdateReload();
            },
          ),
        ] else ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1F9E5C),
            ),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('সব মোবাইলের APK'),
            onPressed: () async {
              Navigator.pop(ctx);
              await launchUrl(
                Uri.parse(info.apkUrlArm64),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('পুরাতন মোবাইলের APK'),
            onPressed: () async {
              Navigator.pop(ctx);
              await launchUrl(
                Uri.parse(info.apkUrlArmV7),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
        ],
      ],
    ),
  );
}
