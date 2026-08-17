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

    // Urdu specific characters
    final urduRegex = RegExp(
        r'[\u067E\u0686\u0698\u06AF\u06D2\u0688\u0691\u0679\u06BA\u06C1\u06BE]');
    if (urduRegex.hasMatch(text)) {
      return 'UrduNastaleeq';
    }

    // Arabic block (includes Urdu characters not matched above, but typically Arabic)
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    if (arabicRegex.hasMatch(text)) {
      return 'ArabicUthmanic';
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

    if (fontFamily == 'Nunito') {
      dynamicStyle = GoogleFonts.nunito(textStyle: dynamicStyle);
    } else if (fontFamily != null) {
      dynamicStyle = dynamicStyle.copyWith(fontFamily: fontFamily);

      // Increase font size significantly for Arabic and Urdu for better readability
      if (fontFamily == 'UrduNastaleeq' && dynamicStyle.fontSize != null) {
        dynamicStyle =
            dynamicStyle.copyWith(fontSize: dynamicStyle.fontSize! * 1.5);
      } else if (fontFamily == 'ArabicUthmanic' && dynamicStyle.fontSize != null) {
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
