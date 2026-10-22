import 'dart:io';

class PwaPlatformHelper {
  static bool get isWebPlatform => false;

  static bool isAppInstalled() {
    // If running natively on Android, iOS, Windows, etc., the app is already installed.
    return true;
  }

  static bool isInstallPromptAvailable() {
    return false;
  }

  static Future<bool> promptPwaInstall() async {
    return false;
  }

  static String getPlatformName() {
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      return 'desktop';
    } catch (_) {
      return 'unknown';
    }
  }

  static Future<void> forceUpdateReload() async {
    // Native apps do not reload via browser service worker
  }
}
