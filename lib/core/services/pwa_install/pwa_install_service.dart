import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'pwa_install_stub.dart'
    if (dart.library.html) 'pwa_install_web.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final int latestBuildNumber;
  final String releaseDate;
  final String changelog;
  final String apkUrlArm64;
  final String apkUrlArmV7;

  AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.releaseDate,
    required this.changelog,
    required this.apkUrlArm64,
    required this.apkUrlArmV7,
  });
}

class PwaInstallService {
  static const String currentVersion = '1.0.9';
  static const int currentBuildNumber = 9;

  static const String _kDismissedOrInstalledKey = 'maktaba_pwa_installed_or_dismissed';

  /// Check if running on web
  static bool get isWeb => kIsWeb || PwaPlatformHelper.isWebPlatform;

  /// Check if running in installed mode (standalone PWA or native app)
  static bool isAppInstalled() {
    if (!kIsWeb) return true; // Compiled native app
    return PwaPlatformHelper.isAppInstalled();
  }

  /// Device platform name: 'ios', 'android', 'desktop', etc.
  static String getPlatform() {
    return PwaPlatformHelper.getPlatformName();
  }

  /// Whether the browser has an install prompt ready
  static bool isInstallPromptAvailable() {
    return PwaPlatformHelper.isInstallPromptAvailable();
  }

  /// Request browser to show PWA install prompt
  static Future<bool> promptPwaInstall() async {
    final result = await PwaPlatformHelper.promptPwaInstall();
    if (result) {
      await markDismissedOrInstalled();
    }
    return result;
  }

  /// Reload web app and bypass service worker cache
  static Future<void> forceUpdateReload() async {
    await PwaPlatformHelper.forceUpdateReload();
  }

  /// Should the bottom installation popup be displayed?
  /// User requirement:
  /// "তবে যে একবার ইনস্টল করবে তার কাছে পপআপটা আসবে না। শুধু একবারই আসবে, যতক্ষণ না সে ইনস্টল করে।"
  static Future<bool> shouldShowInstallPopup() async {
    // 1. If not running on web, never show PWA install popup
    if (!kIsWeb) return false;

    // 2. If app is already installed / opened in standalone mode, do not show
    if (isAppInstalled()) return false;

    // 3. If user previously dismissed or installed, do not show
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool(_kDismissedOrInstalledKey) ?? false;
      if (hasSeen) return false;
    } catch (_) {}

    return true;
  }

  /// Mark that the user has either installed or dismissed the install popup
  static Future<void> markDismissedOrInstalled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDismissedOrInstalledKey, true);
    } catch (_) {}
  }

  /// Reset the install prompt state (e.g. if requested from Settings)
  static Future<void> resetDismissedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kDismissedOrInstalledKey);
    } catch (_) {}
  }

  /// Check remote version.json for updates
  static Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final uri = Uri.parse('https://maktabatu-ihsan.web.app/version.json?t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final latestVersion = data['version']?.toString() ?? currentVersion;
        final latestBuild = int.tryParse(data['buildNumber']?.toString() ?? '0') ?? 0;
        final releaseDate = data['releaseDate']?.toString() ?? '';
        final changelog = data['changelog']?.toString() ?? '';
        final apkUrlArm64 = data['apkUrlArm64']?.toString() ??
            'https://maktabatu-ihsan.web.app/apk/al-ihsan-all-phones.apk';
        final apkUrlArmV7 = data['apkUrlArmV7']?.toString() ??
            'https://maktabatu-ihsan.web.app/apk/al-ihsan-old-phones.apk';

        final hasUpdate = latestBuild > currentBuildNumber ||
            _compareVersions(latestVersion, currentVersion) > 0;

        return AppUpdateInfo(
          hasUpdate: hasUpdate,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          latestBuildNumber: latestBuild,
          releaseDate: releaseDate,
          changelog: changelog,
          apkUrlArm64: apkUrlArm64,
          apkUrlArmV7: apkUrlArmV7,
        );
      }
    } catch (e) {
      debugPrint('[PwaInstallService] Check update error: $e');
    }
    return null;
  }

  static int _compareVersions(String v1, String v2) {
    final p1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final p2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final len = p1.length > p2.length ? p1.length : p2.length;
    for (int i = 0; i < len; i++) {
      final num1 = i < p1.length ? p1[i] : 0;
      final num2 = i < p2.length ? p2[i] : 0;
      if (num1 != num2) {
        return num1.compareTo(num2);
      }
    }
    return 0;
  }
}
