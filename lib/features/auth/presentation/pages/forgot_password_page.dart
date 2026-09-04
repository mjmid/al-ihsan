import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/user_model.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/widgets/maktaba_text_field.dart';
import '../../../../core/theme/neu_card.dart';
import '../../../../core/theme/neu_button.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _verifyFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isVerifying = false;
  bool _isResetting = false;
  bool _obscureNewPin = true;
  bool _obscureConfirmPin = true;

  User? _verifiedUser;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Step 1: Verify User Identity
  // ---------------------------------------------------------------------------
  Future<void> _handleVerify() async {
    if (!(_verifyFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isVerifying = true);

    try {
      final phone = _phoneController.text.trim();
      final name = _nameController.text.trim();

      final userRepo = ref.read(userRepositoryProvider);
      var user = await userRepo.findUserForPasswordReset(
        phone: phone,
        name: name,
      );

      // If not found locally, try syncing with remote database and check again
      if (user == null) {
        try {
          final syncService = await ref.read(syncServiceProvider.future);
          await syncService.syncAll();
          user = await userRepo.findUserForPasswordReset(
            phone: phone,
            name: name,
          );
        } catch (_) {}
      }

      if (!mounted) return;

      if (user != null) {
        setState(() {
          _verifiedUser = user;
          _isVerifying = false;
        });
      } else {
        setState(() => _isVerifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'সঠিক তথ্য পাওয়া যায়নি! আপনার নিবন্ধিত নাম ও মোবাইল নম্বর মিলিয়ে পুনরায় চেষ্টা করুন।',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('যাচাইকরণে ত্রুটি: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Step 2: Set New PIN
  // ---------------------------------------------------------------------------
  Future<void> _handleResetPassword() async {
    if (!(_resetFormKey.currentState?.validate() ?? false)) return;
    if (_verifiedUser == null) return;

    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (newPin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('উভয় পাসওয়ার্ড হুবহু এক হতে হবে'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isResetting = true);

    try {
      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.resetPin(
        userId: _verifiedUser!.userId,
        newPin: newPin,
      );

      if (!mounted) return;
      setState(() => _isResetting = false);

      // Show success modal
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF1F9E5C), size: 28),
              SizedBox(width: 8),
              Text('পাসওয়ার্ড সফল!'),
            ],
          ),
          content: const Text(
            'আপনার নতুন পাসওয়ার্ড সফলভাবে সংরক্ষিত হয়েছে। এখন আপনি এই নতুন পাসওয়ার্ড দিয়ে লগইন করতে পারবেন।',
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F9E5C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx); // close dialog
                Navigator.pop(context); // back to login
              },
              child: const Text('লগইন পেজে যান'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResetting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('পাসওয়ার্ড সংরক্ষণে ত্রুটি: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // WhatsApp Support Helper
  // ---------------------------------------------------------------------------
  Future<void> _contactAdminViaWhatsApp() async {
    final adminPhone = ref.read(appSettingsProvider).adminWhatsAppNumber;
    if (adminPhone == null || adminPhone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অ্যাডমিনের হোয়াটসঅ্যাপ নম্বর সেট করা নেই। সরাসরি যোগাযোগ করুন।'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final formattedPhone = adminPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final teacherName = _nameController.text.trim();
    final teacherPhone = _phoneController.text.trim();

    final message = StringBuffer('আসসালামু আলাইকুম।\n');
    message.writeln('আমি মাকতাবাতুল ইহসান অ্যাপের পাসওয়ার্ড ভুলে গেছি।');
    if (teacherName.isNotEmpty) {
      message.writeln('নাম: $teacherName');
    }
    if (teacherPhone.isNotEmpty) {
      message.writeln('মোবাইল: $teacherPhone');
    }
    message.writeln('দয়া করে আমাকে নতুন পাসওয়ার্ড সেট করতে সাহায্য করুন।');

    final encodedMessage = Uri.encodeComponent(message.toString());
    final whatsappUrl = Uri.parse("whatsapp://send?phone=$formattedPhone&text=$encodedMessage");

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      final fallbackUrl = Uri.parse("https://wa.me/$formattedPhone?text=$encodedMessage");
      await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('পাসওয়ার্ড রিসেট'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Header
                    Icon(
                      _verifiedUser == null ? Icons.lock_reset : Icons.lock_open,
                      size: 64,
                      color: colorScheme.primary,
                    ).animate().scale(duration: 400.ms),
                    const SizedBox(height: 12),
                    Text(
                      _verifiedUser == null
                          ? 'পাসওয়ার্ড ভুলে গেছেন?'
                          : 'নতুন পাসওয়ার্ড দিন',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _verifiedUser == null
                          ? 'আপনার অ্যাকাউন্টের নিবন্ধিত তথ্য দিয়ে নিজেকে যাচাই করুন'
                          : 'নিচের ঘরে আপনার নতুন পাসওয়ার্ড লিখে সংরক্ষণ করুন',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Card with Step 1 or Step 2
                    NeuCard(
                      padding: const EdgeInsets.all(24.0),
                      child: _verifiedUser == null
                          ? _buildVerificationStep(colorScheme)
                          : _buildResetStep(colorScheme),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                    const SizedBox(height: 24),

                    // WhatsApp Support Option
                    TextButton.icon(
                      onPressed: _contactAdminViaWhatsApp,
                      icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                      label: Text(
                        'সমস্যা হচ্ছে? হোয়াটসঅ্যাপে সাহায্য নিন',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.85),
                          fontWeight: FontWeight.w600,
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

  // ---------------------------------------------------------------------------
  // UI Step 1: Verification Form
  // ---------------------------------------------------------------------------
  Widget _buildVerificationStep(ColorScheme colorScheme) {
    return Form(
      key: _verifyFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MaktabaTextField(
            label: 'নিবন্ধিত নাম',
            hint: 'যেমন: মাওলানা আব্দুল্লাহ',
            controller: _nameController,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'দয়া করে আপনার নাম দিন';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          MaktabaTextField(
            label: 'নিবন্ধিত মোবাইল নম্বর',
            hint: 'যেমন: 017XXXXXXXX',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'দয়া করে মোবাইল নম্বর দিন';
              }
              if (val.trim().length < 8) {
                return 'সঠিক মোবাইল নম্বর দিন';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          NeuButton(
            onPressed: _isVerifying ? null : _handleVerify,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: _isVerifying
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'যাচাই করুন',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI Step 2: New PIN Form
  // ---------------------------------------------------------------------------
  Widget _buildResetStep(ColorScheme colorScheme) {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User Confirmation Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user, color: colorScheme.primary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _verifiedUser!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'পদবি: ${_verifiedUser!.type.displayLabel} | ${_verifiedUser!.phone ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // New PIN
          MaktabaTextField(
            label: 'নতুন পাসওয়ার্ড / পিন',
            hint: '••••••••',
            controller: _newPinController,
            obscureText: _obscureNewPin,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPin ? Icons.visibility : Icons.visibility_off,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
              onPressed: () {
                setState(() => _obscureNewPin = !_obscureNewPin);
              },
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'দয়া করে নতুন পাসওয়ার্ড দিন';
              }
              if (val.trim().length < 4) {
                return 'পাসওয়ার্ড অন্তত ৪ অক্ষরের হতে হবে';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm New PIN
          MaktabaTextField(
            label: 'পাসওয়ার্ড নিশ্চিত করুন',
            hint: '••••••••',
            controller: _confirmPinController,
            obscureText: _obscureConfirmPin,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPin ? Icons.visibility : Icons.visibility_off,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
              onPressed: () {
                setState(() => _obscureConfirmPin = !_obscureConfirmPin);
              },
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'পুনরায় পাসওয়ার্ড লিখুন';
              }
              if (val.trim() != _newPinController.text.trim()) {
                return 'উভয় পাসওয়ার্ড এক হতে হবে';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Submit Button
          NeuButton(
            onPressed: _isResetting ? null : _handleResetPassword,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: _isResetting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'পাসওয়ার্ড সংরক্ষণ করুন',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),

          // Cancel / Back to Step 1
          TextButton(
            onPressed: () {
              setState(() {
                _verifiedUser = null;
                _newPinController.clear();
                _confirmPinController.clear();
              });
            },
            child: const Text('ভুল একাউন্ট? পুনরায় তথ্য লিখুন'),
          ),
        ],
      ),
    );
  }
}
