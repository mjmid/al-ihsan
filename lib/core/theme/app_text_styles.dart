import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  /// For large Arabic text like titles or highlighted ayah/hadith.
  static TextStyle arabicDisplay(BuildContext context) {
    return const TextStyle(
      fontFamily: 'ArabicNaskh',
      fontSize: 28,
      height: 1.5,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle arabicBody(BuildContext context) {
    return const TextStyle(
      fontFamily: 'ArabicNaskh',
      fontSize: 16,
      height: 1.6,
    );
  }

  /// For standard Bengali reading text.
  static TextStyle bengaliBody(BuildContext context) {
    return const TextStyle(
      fontFamily: 'BengaliSolaiman',
      fontSize: 14,
      height: 1.4,
    );
  }

  /// For main Bengali titles (e.g., App bar, headers).
  static TextStyle bengaliDisplay(BuildContext context) {
    return const TextStyle(
      fontFamily: 'BengaliSolaiman',
      fontSize: 20,
      fontWeight: FontWeight.bold,
    );
  }

  // General
  static TextStyle displayLarge(BuildContext context) {
    return GoogleFonts.nunito(
      textStyle: Theme.of(context).textTheme.displayLarge,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle headlineMedium(BuildContext context) {
    return GoogleFonts.nunito(
      textStyle: Theme.of(context).textTheme.headlineMedium,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle bodyLarge(BuildContext context) {
    return GoogleFonts.nunito(
      textStyle: Theme.of(context).textTheme.bodyLarge,
    );
  }

  static TextStyle labelSmall(BuildContext context) {
    return GoogleFonts.nunito(
      textStyle: Theme.of(context).textTheme.labelSmall,
    );
  }
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}
