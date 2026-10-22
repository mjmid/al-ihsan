// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

class PwaPlatformHelper {
  static bool get isWebPlatform => true;

  static bool isAppInstalled() {
    try {
      // 1. Check standalone display mode (Chrome / Edge / Android)
      final isStandaloneMedia =
          html.window.matchMedia('(display-mode: standalone)').matches;
      if (isStandaloneMedia) return true;

      // 2. Check iOS Safari standalone
      final nav = html.window.navigator;
      try {
        final isNavStandalone = (nav as dynamic).standalone;
        if (isNavStandalone == true) return true;
      } catch (_) {}

      // 3. Check persistent localStorage flag set upon installation
      if (html.window.localStorage['maktaba_pwa_installed'] == 'true') {
        return true;
      }
    } catch (_) {}
    return false;
  }

  static bool isInstallPromptAvailable() {
    try {
      return js.context['pwaDeferredPrompt'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> promptPwaInstall() async {
    final completer = Completer<bool>();
    try {
      if (js.context.hasProperty('promptInstallPwa')) {
        js.context.callMethod('promptInstallPwa', [
          js.allowInterop((dynamic accepted) {
            completer.complete(accepted == true);
          })
        ]);
        // Timeout after 15 seconds if user leaves prompt open
        return completer.future.timeout(
          const Duration(seconds: 15),
          onTimeout: () => false,
        );
      }
    } catch (e) {
      if (!completer.isCompleted) completer.complete(false);
    }
    return false;
  }

  static String getPlatformName() {
    try {
      final ua = html.window.navigator.userAgent.toLowerCase();
      if (ua.contains('iphone') ||
          ua.contains('ipad') ||
          ua.contains('ipod') ||
          (ua.contains('macintosh') && (html.window.navigator.maxTouchPoints ?? 0) > 1)) {
        return 'ios';
      }
      if (ua.contains('android')) {
        return 'android';
      }
      return 'desktop';
    } catch (_) {
      return 'desktop';
    }
  }

  static Future<void> forceUpdateReload() async {
    try {
      if (js.context.hasProperty('forceAppUpdateReload')) {
        js.context.callMethod('forceAppUpdateReload');
      } else {
        html.window.location.reload();
      }
    } catch (_) {
      html.window.location.reload();
    }
  }
}
