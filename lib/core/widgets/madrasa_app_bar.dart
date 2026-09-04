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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset =
        isDark ? 'assets/images/logo_dark.png' : 'assets/images/logo_light.png';
    final calligraphyColor = isDark ? Colors.white : colorScheme.onSurface;

    // Force LTR so logo/calligraphy is always left, actions always right
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AppBar(
        leading: leading,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  logoAsset,
                  height: 34,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.school, size: 34, color: colorScheme.primary),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/images/calligraphy.png',
                  height: 26,
                  fit: BoxFit.contain,
                  color: calligraphyColor,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontFamily: titleFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withOpacity(0.85),
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
