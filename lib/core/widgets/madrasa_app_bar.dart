import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maktaba_ihsan/core/providers/settings_provider.dart';

class MadrasaAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const MadrasaAppBar(
      {super.key, required this.title, this.actions, this.leading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = ref.watch(appSettingsProvider).locale.languageCode;

    String titleFontFamily;
    if (locale == 'ar') {
      titleFontFamily = 'ArabicMyLotus';
    } else if (locale == 'ur') {
      titleFontFamily = 'UrduNastaleeq';
    } else {
      titleFontFamily = 'BengaliSolaiman';
    }

    // Force LTR so logo is always left, actions always right
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AppBar(
        leading: leading,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 32,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.school, size: 32, color: colorScheme.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'জামেআ মারকাযুল ইহসান ঢাকা',
                    style: TextStyle(
                      fontFamily: 'BengaliSolaiman',
                      fontSize: 24,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontFamily: titleFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: actions,
        toolbarHeight: 80,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80.0);
}
