import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_constants.dart';
import '../core/providers/settings_provider.dart';
import '../features/auth/presentation/pages/login_page.dart';

/// ============================================================
/// MaktabaApp — Root Widget
/// ============================================================
///
/// Responsibilities:
///   - Configure Material 3 themes (Light / Dark / System)
///   - Configure localization (Arabic, Bengali, English, Urdu)
///   - Read theme and language settings from Hive via Riverpod
///   - Route to the initial page (Login)
/// ============================================================

class MaktabaApp extends ConsumerWidget {
  const MaktabaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch settings — rebuilds when theme or language changes
    final settings = ref.watch(appSettingsProvider);
    final locale = settings.locale.languageCode;

    // Primary font based on selected language
    String appFontFamily;
    // Fallback list always includes all scripts so mixed text renders correctly
    List<String> fontFallback;
    if (locale == 'ar') {
      appFontFamily = 'ArabicMyLotus';
      fontFallback = ['BengaliSolaiman', 'UrduNastaleeq'];
    } else if (locale == 'ur') {
      appFontFamily = 'UrduNastaleeq';
      fontFallback = ['ArabicMyLotus', 'BengaliSolaiman'];
    } else {
      appFontFamily = 'BengaliSolaiman';
      fontFallback = ['ArabicMyLotus', 'UrduNastaleeq'];
    }

    return MaterialApp(
      // ── App Identity ────────────────────────────────────────────────────
      title: kAppNameEn,
      debugShowCheckedModeBanner: false,

      // ── Theme Configuration ─────────────────────────────────────────────
      theme: FlexThemeData.light(
        colors: const FlexSchemeColor(
          primary: Color(0xFF1F9E5C),
          primaryContainer: Color(0xFF1F9E5C),
          secondary: Color(0xFFEA580C),
          secondaryContainer: Color(0xFFF6EFE9),
          tertiary: Color(0xFF3B82F6),
          tertiaryContainer: Color(0xFF3B82F6),
          appBarColor: Color(0xFFF6EFE9),
          error: Color(0xFFEF4444),
        ),
        surface: const Color(0xFFEBE0D4),
        background: const Color(0xFFF6EFE9),
        scaffoldBackground: const Color(0xFFF6EFE9),
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 0,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          blendOnColors: false,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          adaptiveAppBarScrollUnderOff: FlexAdaptive.all(),
          elevatedButtonSchemeColor: SchemeColor.onPrimary,
          elevatedButtonSecondarySchemeColor: SchemeColor.primary,
          inputDecoratorSchemeColor: SchemeColor.primary,
          inputDecoratorBackgroundAlpha: 21,
          inputDecoratorRadius: 12.0,
          cardRadius: 18.0,
          popupMenuRadius: 8.0,
          dialogRadius: 16.0,
          bottomSheetRadius: 20.0,
        ),
        useMaterial3: true,
        fontFamily: appFontFamily,
        fontFamilyFallback: fontFallback,
      ),

      darkTheme: FlexThemeData.dark(
        colors: const FlexSchemeColor(
          primary: Color(0xFF1F9E5C),
          primaryContainer: Color(0xFF1F9E5C),
          secondary: Color(0xFFFB923C),
          secondaryContainer: Color(0xFF182A30),
          tertiary: Color(0xFF60A5FA),
          tertiaryContainer: Color(0xFF60A5FA),
          appBarColor: Color(0xFF14242A),
          error: Color(0xFFF87171),
        ),
        surface: const Color(0xFF182A30),
        background: const Color(0xFF14242A),
        scaffoldBackground: const Color(0xFF14242A),
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 0,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          adaptiveAppBarScrollUnderOff: FlexAdaptive.all(),
          elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
          elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
          inputDecoratorSchemeColor: SchemeColor.primary,
          inputDecoratorBackgroundAlpha: 43,
          inputDecoratorRadius: 12.0,
          cardRadius: 18.0,
          popupMenuRadius: 8.0,
          dialogRadius: 16.0,
          bottomSheetRadius: 20.0,
        ),
        useMaterial3: true,
        fontFamily: appFontFamily,
        fontFamilyFallback: fontFallback,
      ),

      // Follow system theme by default — overrideable in settings
      themeMode: settings.themeMode,

      // ── Localization ────────────────────────────────────────────────────
      locale: settings.locale,
      supportedLocales: const [
        Locale('en'), // English
        Locale('bn'), // Bengali
        Locale('ar'), // Arabic
        Locale('ur'), // Urdu
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Initial Route ───────────────────────────────────────────────────
      home: const LoginPage(),
    );
  }
}
