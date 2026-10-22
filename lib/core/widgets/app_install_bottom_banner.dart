import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/pwa_install/pwa_install_service.dart';

class AppInstallBottomBanner extends StatefulWidget {
  const AppInstallBottomBanner({super.key});

  /// Opens the device-appropriate installation dialog from anywhere in the app (e.g. Settings).
  static Future<void> showInstallDialog(BuildContext context) async {
    final platform = PwaInstallService.getPlatform();

    if (platform == 'ios') {
      await _showIosInstallModal(context);
    } else if (platform == 'android') {
      await _showAndroidInstallModal(context);
    } else {
      // Desktop / PC
      if (PwaInstallService.isInstallPromptAvailable()) {
        final accepted = await PwaInstallService.promptPwaInstall();
        if (accepted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('অ্যাপ সফলভাবে ইনস্টল হচ্ছে!'),
                backgroundColor: Color(0xFF1F9E5C),
              ),
            );
          }
          return;
        }
      }
      if (context.mounted) {
        await _showDesktopInstallModal(context);
      }
    }
  }

  static Future<void> _showIosInstallModal(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F9E5C).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.apple, color: Color(0xFF1F9E5C), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'আইফোনে আল ইহসান ইনস্টল',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'সাফারি ব্রাউজার থেকে সরাসরি হোম স্ক্রিনে যুক্ত করুন',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildStepItem(
                ctx,
                number: '১',
                icon: Icons.ios_share_rounded,
                title: 'শেয়ার আইকনে চাপুন',
                desc: 'সাফারি ব্রাউজারের নিচে থাকা শেয়ার [↑] বোতামটি চাপুন।',
              ),
              const SizedBox(height: 12),
              _buildStepItem(
                ctx,
                number: '২',
                icon: Icons.add_box_outlined,
                title: 'হোম স্ক্রিনে যোগ করুন',
                desc: 'মেনু থেকে স্ক্রোল করে "Add to Home Screen" বা "হোম স্ক্রিনে যোগ করুন" চাপুন।',
              ),
              const SizedBox(height: 12),
              _buildStepItem(
                ctx,
                number: '৩',
                icon: Icons.check_circle_outline_rounded,
                title: 'Add চাপুন',
                desc: 'উপরে ডানপাশের "Add" বোতামে চাপলেই অ্যাপটি আপনার আইফোনে ইনস্টল হয়ে যাবে।',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1F9E5C),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    PwaInstallService.markDismissedOrInstalled();
                    Navigator.pop(ctx);
                  },
                  child: const Text('বুঝেছি', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _showDesktopInstallModal(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F9E5C).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.desktop_windows_rounded, color: Color(0xFF1F9E5C), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('পিসিতে অ্যাপ ইনস্টল', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'আপনার কম্পিউটার বা ল্যাপটপে সরাসরি অ্যাপ হিসেবে ব্যবহারের জন্য:',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              _buildStepItem(
                ctx,
                number: '১',
                icon: Icons.install_desktop_rounded,
                title: 'ইনস্টল আইকনে ক্লিক করুন',
                desc: 'ক্রোম বা এজ ব্রাউজারের অ্যাড্রেস বারের ডানপাশে থাকা (+) Install আইকনে ক্লিক করুন।',
              ),
              const SizedBox(height: 10),
              _buildStepItem(
                ctx,
                number: '২',
                icon: Icons.more_vert_rounded,
                title: 'বিকল্প পদ্ধতি (ব্রাউজার মেনু)',
                desc: 'অথবা ব্রাউজারের Menu (⋮) -> "Install Al Ihsan" এ ক্লিক করুন।',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                PwaInstallService.markDismissedOrInstalled();
                Navigator.pop(ctx);
              },
              child: const Text('ঠিক আছে'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showAndroidInstallModal(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F9E5C).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.android_rounded, color: Color(0xFF1F9E5C), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'অ্যান্ড্রয়েডে আল ইহসান ইনস্টল',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'আপনার সুবিধামত ইনস্টল পদ্ধতি বেছে নিন',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Option 1: PWA Install
              InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  if (PwaInstallService.isInstallPromptAvailable()) {
                    await PwaInstallService.promptPwaInstall();
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ব্রাউজারের মেনু (⋮) থেকে "Add to Home screen" চাপুন'),
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_to_home_screen_rounded, color: Colors.blue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ওয়েব অ্যাপ হিসেবে ইনস্টল (PWA)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'কোনো স্টোরেজ খরচ হবে না, স্বয়ংক্রিয়ভাবে আপডেট হবে',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Option 2: Direct APK Download
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F9E5C).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.file_download_outlined, color: Color(0xFF1F9E5C), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'অ্যান্ড্রয়েড APK সরাসরি ডাউনলোড',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                'অফলাইনে স্থায়ী ব্যবহারের জন্য (আকার < ২০ MB)',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1F9E5C),
                              side: const BorderSide(color: Color(0xFF1F9E5C)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.android, size: 18),
                            label: const Text('সব মোবাইলের জন্য', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await PwaInstallService.markDismissedOrInstalled();
                              final url = Uri.parse('https://maktabatu-ihsan.web.app/apk/al-ihsan-all-phones.apk');
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal,
                              side: const BorderSide(color: Colors.teal),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.phone_android_rounded, size: 18),
                            label: const Text('পুরাতন মোবাইলের জন্য', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await PwaInstallService.markDismissedOrInstalled();
                              final url = Uri.parse('https://maktabatu-ihsan.web.app/apk/al-ihsan-old-phones.apk');
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildStepItem(
    BuildContext context, {
    required String number,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF1F9E5C),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  State<AppInstallBottomBanner> createState() => _AppInstallBottomBannerState();
}

class _AppInstallBottomBannerState extends State<AppInstallBottomBanner>
    with SingleTickerProviderStateMixin {
  bool _visible = false;
  late AnimationController _animController;
  late Animation<Offset> _offsetAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _offsetAnim = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    // Wait briefly so initial screen transitions settle smoothly
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final shouldShow = await PwaInstallService.shouldShowInstallPopup();
    if (shouldShow && mounted) {
      setState(() => _visible = true);
      _animController.forward();
    }
  }

  void _dismissBanner() async {
    await _animController.reverse();
    if (mounted) {
      setState(() => _visible = false);
    }
    await PwaInstallService.markDismissedOrInstalled();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final platform = PwaInstallService.getPlatform();

    final String platformDesc;
    final IconData platformIcon;
    if (platform == 'ios') {
      platformIcon = Icons.apple;
      platformDesc = 'আইফোনে সহজে ব্যবহারের জন্য হোম স্ক্রিনে ইনস্টল করুন';
    } else if (platform == 'android') {
      platformIcon = Icons.android;
      platformDesc = 'অ্যান্ড্রয়েড মোবাইলে সরাসরি অ্যাপ হিসেবে ইনস্টল করুন';
    } else {
      platformIcon = Icons.desktop_windows_rounded;
      platformDesc = 'কম্পিউটার বা পিসিতে সরাসরি অ্যাপ হিসেবে ইনস্টল করুন';
    }

    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _offsetAnim,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Material(
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.surface,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1F9E5C).withOpacity(0.3),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F9E5C).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(platformIcon, color: const Color(0xFF1F9E5C), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'আল ইহসান অ্যাপ ইনস্টল করুন',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            platformDesc,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1F9E5C),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        _dismissBanner();
                        AppInstallBottomBanner.showInstallDialog(context);
                      },
                      child: const Text(
                        'ইনস্টল',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _dismissBanner,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
