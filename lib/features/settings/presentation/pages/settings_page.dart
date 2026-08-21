import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maktaba_ihsan/core/providers/settings_provider.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import 'package:maktaba_ihsan/core/theme/neu_card.dart';
import 'package:maktaba_ihsan/features/auth/presentation/pages/login_page.dart';
import 'package:maktaba_ihsan/core/providers/auth_provider.dart';
import 'package:maktaba_ihsan/core/providers/mode_provider.dart';
import 'package:maktaba_ihsan/core/models/user_model.dart';

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
          _AdminWhatsAppField(
            initialValue: settings.adminWhatsAppNumber ?? '',
            onChanged: (val) {
              ref.read(appSettingsProvider.notifier).setAdminWhatsAppNumber(val);
            },
          ),
          const SizedBox(height: 24),
        ],

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
    final role = authState.userType == UserType.admin ? 'Owner' : 'Teacher';

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

class _AdminWhatsAppField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _AdminWhatsAppField({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_AdminWhatsAppField> createState() => _AdminWhatsAppFieldState();
}

class _AdminWhatsAppFieldState extends State<_AdminWhatsAppField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.phone_android, color: Colors.green),
          const SizedBox(width: 16),
          Expanded(
              child: TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'অ্যাডমিন হোয়াটসঅ্যাপ নাম্বার',
                  hintText: 'যেমন +88017xxxxxxxx',
                  border: InputBorder.none,
                ),
                onChanged: widget.onChanged,
              ),
          ),
        ],
      ),
    );
  }
}
