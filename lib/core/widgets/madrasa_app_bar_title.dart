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
      titleFontFamily = 'ArabicMyLotus';
    } else {
      titleFontFamily = 'BengaliSolaiman';
    }

    return Directionality(
      // Force LTR so logo/name always stays on the left
      textDirection: TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 52,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.school, size: 52, color: colorScheme.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'à¦œà¦¾à¦®à§‡à¦† à¦®à¦¾à¦°à¦•à¦¾à¦¯à§à¦² à¦‡à¦¹à¦¸à¦¾à¦¨ à¦¢à¦¾à¦•à¦¾',
                    // Always use SolaimanLipi for the Bangla madrasa name
                    style: TextStyle(
                      fontFamily: 'BengaliSolaiman',
                      fontSize: 34,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontFamily: titleFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}


