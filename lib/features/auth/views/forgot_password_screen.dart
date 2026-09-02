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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _linkSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleReset() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      await ref
          .read(authProvider.notifier)
          .forgotPassword(_emailController.text.trim());

      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.verificationSent) {
        setState(() {
          _linkSent = true;
        });
      } else if (authState.status == AuthStatus.error && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.errorMessage ?? 'An error occurred.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.white : AppColors.navy,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LanSpeechLogo(size: 72, showText: false),
                  const SizedBox(height: 24),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 400),
                    crossFadeState: _linkSent
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Column(
                      children: [
                        Text(
                          'Forgot Password?',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                fontSize: 26,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Don't worry, enter your email below and we'll send you instructions to reset your password.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.lightBackground.withOpacity(0.8)
                                    : AppColors.grey,
                              ),
                        ),
                        const SizedBox(height: 32),
                        Card(
                          color: isDark
                              ? const Color(0xFF194148)
                              : AppColors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                CustomTextField(
                                  controller: _emailController,
                                  labelText: 'Email Address',
                                  hintText: 'you@example.com',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter your email.';
                                    }
                                    final regex =
                                        RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                    if (!regex.hasMatch(val.trim())) {
                                      return 'Please enter a valid email address.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                CustomButton(
                                  text: 'Send Reset Link',
                                  isLoading:
                                      authState.status == AuthStatus.loading,
                                  onPressed: _handleReset,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    secondChild: Card(
                      color: isDark ? const Color(0xFF194148) : AppColors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: AppColors.yellow,
                              size: 72,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Email Sent!',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: isDark
                                        ? AppColors.white
                                        : AppColors.navy,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "We've sent a password reset link to ${_emailController.text}. Please check your inbox and spam folders.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: isDark
                                    ? AppColors.lightBackground.withOpacity(0.8)
                                    : AppColors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 32),
                            CustomButton(
                              text: 'Back to Login',
                              onPressed: () {
                                context.go('/login');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
