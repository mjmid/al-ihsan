import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maktaba_ihsan/core/providers/settings_provider.dart';

class MadrasaAppBarTitle extends ConsumerWidget {
  final String title;
  const MadrasaAppBarTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = ref.watch(appSettingsProvider).locale.languageCode;

    // Pick the right font for the page title based on current language
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

    return Directionality(
      // Force LTR so logo/calligraphy always stays on the left
      textDirection: TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                logoAsset,
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.school, size: 48, color: colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Image.asset(
                'assets/images/calligraphy.png',
                height: 38,
                fit: BoxFit.contain,
                color: calligraphyColor,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontFamily: titleFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}


