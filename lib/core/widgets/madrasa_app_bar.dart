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
                  height: 46,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.school, size: 46, color: colorScheme.primary),
                ),
                const SizedBox(width: 10),
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
                    height: 38,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF34D399)
                        : const Color(0xFF047857),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: titleFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF6EE7B7)
                        : const Color(0xFF047857),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: actions,
        toolbarHeight: 96,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(96.0);
}
