import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/logo_painter.dart';
import '../models/auth_state.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _termsAccepted = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (!_termsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please accept the Terms & Conditions to create an account.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      FocusScope.of(context).unfocus();
      await ref.read(authProvider.notifier).register(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text,
          );

      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.verificationSent && mounted) {
        _showSuccessDialog();
      } else if (authState.status == AuthStatus.authenticated && mounted) {
        context.go('/onboarding');
      } else if (authState.status == AuthStatus.error && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.errorMessage ?? 'Registration failed.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? const Color(0xFF194148) : AppColors.white,
          title: Row(
            children: [
              const Icon(Icons.mark_email_unread_rounded,
                  color: AppColors.yellow, size: 28),
              const SizedBox(width: 12),
              Text(
                'Verify Your Email',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.navy,
                ),
              ),
            ],
          ),
          content: Text(
            'We have sent a verification link to your email address. Please click the link to verify your email and complete your account registration.',
            style: GoogleFonts.poppins(
              color: isDark
                  ? AppColors.lightBackground.withOpacity(0.9)
                  : AppColors.navy,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // dismiss dialog
                context.go('/login'); // go to login
              },
              child: const Text('Back to Login'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header Logo Widget
                      const LanSpeechLogo(size: 64, showText: false),
                      const SizedBox(height: 16),
                      Text(
                        'Join LanSpeech',
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontSize: 26,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start your custom path to daily practice and speaking clarity.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.lightBackground.withOpacity(0.8)
                                  : AppColors.grey,
                            ),
                      ),
                      const SizedBox(height: 28),

                      // Form Card
                      Card(
                        color:
                            isDark ? const Color(0xFF194148) : AppColors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Full Name
                              CustomTextField(
                                controller: _nameController,
                                labelText: 'Your Name',
                                hintText: 'John Doe',
                                prefixIcon: Icons.person_outline_rounded,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter your name.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Email
                              CustomTextField(
                                controller: _emailController,
                                labelText: 'Email Address',
                                hintText: 'you@example.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter your email.';
                                  }
                                  final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                  if (!regex.hasMatch(val.trim())) {
                                    return 'Please enter a valid email address.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password
                              CustomTextField(
                                controller: _passwordController,
                                labelText: 'Password',
                                hintText: '••••••••',
                                prefixIcon: Icons.lock_outlined,
                                isPassword: true,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Please enter a password.';
                                  }
                                  if (val.length < 6) {
                                    return 'Password must be at least 6 characters.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Confirm Password
                              CustomTextField(
                                controller: _confirmPasswordController,
                                labelText: 'Confirm Password',
                                hintText: '••••••••',
                                prefixIcon: Icons.lock_clock_outlined,
                                isPassword: true,
                                textInputAction: TextInputAction.done,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Please confirm your password.';
                                  }
                                  if (val != _passwordController.text) {
                                    return 'Passwords do not match.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Terms & Conditions Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _termsAccepted,
                                      activeColor: AppColors.teal,
                                      checkColor: AppColors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          _termsAccepted = val ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _termsAccepted = !_termsAccepted;
                                        });
                                      },
                                      child: RichText(
                                        text: TextSpan(
                                          text: 'I agree to the ',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.white
                                                : AppColors.navy,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'Terms & Conditions',
                                              style: GoogleFonts.poppins(
                                                color: isDark
                                                    ? AppColors.yellow
                                                    : AppColors.teal,
                                                fontWeight: FontWeight.bold,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Create Account Button
                              CustomButton(
                                text: 'Create Account',
                                isLoading:
                                    authState.status == AuthStatus.loading,
                                onPressed: _handleRegister,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Sign In redirect link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: GoogleFonts.poppins(
                              color: isDark
                                  ? AppColors.lightBackground.withOpacity(0.8)
                                  : AppColors.grey,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Text(
                              'Log In',
                              style: GoogleFonts.poppins(
                                color:
                                    isDark ? AppColors.yellow : AppColors.teal,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
