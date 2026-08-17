import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/widgets/maktaba_button.dart';
import '../../../../core/widgets/maktaba_text_field.dart';
import '../../../../core/theme/neu_card.dart';
import '../../../../core/theme/neu_button.dart';
import 'package:maktaba_ihsan/core/models/user_model.dart';

import 'package:maktaba_ihsan/features/dashboard/presentation/pages/root_dashboard_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authProvider).isAuthenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RootDashboardPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      final nameOrPhone = _usernameController.text.trim();
      final pin = _pinController.text.trim();

      final success =
          await ref.read(authProvider.notifier).login(nameOrPhone, pin);

      if (!mounted) return;

      if (success) {
        final authState = ref.read(authProvider);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RootDashboardPage()),
        );
      } else {
        final error =
            ref.read(authProvider).errorMessage ?? 'লগইনে সমস্যা হয়েছে';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!previous!.isAuthenticated && next.isAuthenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RootDashboardPage()),
        );
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Title
            Padding(
              padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
              child: Column(
                children: [
                  Text(
                    'মাকতাবাতুল ইহসান',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2),
                  const SizedBox(height: 16),
                  Icon(
                    Icons.menu_book,
                    size: 80,
                    color: colorScheme.primary,
                  ).animate().scale(delay: 400.ms, duration: 600.ms),
                ],
              ),
            ),

            // Form Card
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: NeuCard(
                        padding: const EdgeInsets.all(32.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'লগইন',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ).animate().fadeIn(delay: 600.ms).scale(),
                              const SizedBox(height: 8),
                              Text(
                                'আপনার একাউন্টে প্রবেশ করুন',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                                textAlign: TextAlign.center,
                              ).animate().fadeIn(delay: 700.ms),
                              const SizedBox(height: 32),
                              MaktabaTextField(
                                label: 'ইউজারনেম',
                                hint: 'example_user',
                                controller: _usernameController,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'দয়া করে ইউজারনেম দিন';
                                  }
                                  return null;
                                },
                              )
                                  .animate()
                                  .fadeIn(delay: 800.ms)
                                  .slideX(begin: -0.1),
                              const SizedBox(height: 20),
                              MaktabaTextField(
                                label: 'পাসওয়ার্ড',
                                hint: '••••••••',
                                controller: _pinController,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'দয়া করে পাসওয়ার্ড দিন';
                                  }
                                  return null;
                                },
                              )
                                  .animate()
                                  .fadeIn(delay: 900.ms)
                                  .slideX(begin: 0.1),
                              const SizedBox(height: 32),
                              NeuButton(
                                onPressed:
                                    authState.isLoading ? null : _handleLogin,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: authState.isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : Text(
                                          'লগইন করুন',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 1000.ms)
                                  .slideY(begin: 0.2),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Developer Name
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0, top: 16.0),
              child: Text(
                'Developed by Habibullah Foridi',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(delay: 1200.ms),
            ),
          ],
        ),
      ),
    );
  }
}
