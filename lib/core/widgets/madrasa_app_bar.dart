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
                  height: 42,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.school, size: 42, color: colorScheme.primary),
                ),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF6EE7B7), Color(0xFF10B981)]
                        : const [Color(0xFF1F9E5C), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Image.asset(
                    'assets/images/calligraphy.png',
                    height: 34,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
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
