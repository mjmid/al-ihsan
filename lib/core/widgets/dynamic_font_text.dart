import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DynamicFontText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const DynamicFontText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  String? _detectFontFamily(String text) {
    if (text.isEmpty) return null;

    // Urdu & Persian specific characters
    final urduRegex = RegExp(
        r'[\u067E\u0686\u0698\u06AF\u06D2\u06D3\u0688\u0691\u0679\u06BA\u06C1\u06C2\u06C3\u06BE\u0654\u0657\u0658\u06A9\u06CC]');
    if (urduRegex.hasMatch(text)) {
      return 'UrduNastaleeq';
    }

    // Arabic block (includes Urdu characters not matched above, but typically Arabic)
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    if (arabicRegex.hasMatch(text)) {
      return 'ArabicMyLotus';
    }

    // Bengali block
    final bengaliRegex = RegExp(r'[\u0980-\u09FF]');
    if (bengaliRegex.hasMatch(text)) {
      return 'BengaliSolaiman';
    }

    // Fallback for English/Latin
    return 'Nunito';
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = _detectFontFamily(text);

    TextStyle dynamicStyle = style ?? const TextStyle();
    
    // If no font size is explicitly provided, inherit from theme to ensure scaling works
    if (dynamicStyle.fontSize == null) {
      final defaultSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0;
      dynamicStyle = dynamicStyle.copyWith(fontSize: defaultSize);
    }

    final List<String> fallbackList;
    if (fontFamily == 'UrduNastaleeq') {
      fallbackList = const [
        'ArabicMyLotus',
        'ArabicUthmanic',
        'BengaliSolaiman',
        'sans-serif',
      ];
    } else if (fontFamily == 'ArabicMyLotus') {
      fallbackList = const [
        'UrduNastaleeq',
        'ArabicUthmanic',
        'BengaliSolaiman',
        'sans-serif',
      ];
    } else if (fontFamily == 'BengaliSolaiman') {
      fallbackList = const [
        'ArabicMyLotus',
        'UrduNastaleeq',
        'sans-serif',
      ];
    } else {
      fallbackList = const [
        'BengaliSolaiman',
        'ArabicMyLotus',
        'UrduNastaleeq',
        'sans-serif',
      ];
    }

    if (fontFamily == 'Nunito') {
      dynamicStyle = GoogleFonts.nunito(textStyle: dynamicStyle).copyWith(
        fontFamilyFallback: fallbackList,
      );
    } else if (fontFamily != null) {
      dynamicStyle = dynamicStyle.copyWith(
        fontFamily: fontFamily,
        fontFamilyFallback: fallbackList,
      );

      // Increase font size significantly for Arabic and Urdu for better readability
      if (fontFamily == 'UrduNastaleeq' && dynamicStyle.fontSize != null) {
        dynamicStyle =
            dynamicStyle.copyWith(fontSize: dynamicStyle.fontSize! * 1.5);
      } else if (fontFamily == 'ArabicMyLotus' && dynamicStyle.fontSize != null) {
        dynamicStyle =
            dynamicStyle.copyWith(fontSize: dynamicStyle.fontSize! * 1.5);
      }
    }

    return Text(
      text,
      style: dynamicStyle,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
