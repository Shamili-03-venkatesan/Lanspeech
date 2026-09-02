import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/logo_painter.dart';
import '../models/auth_state.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _CustomLoadingIndicator extends StatelessWidget {
  final double size;
  const _CustomLoadingIndicator({this.size = 40.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(
        strokeWidth: 3.5,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.yellow),
      ),
    );
  }
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward().then((_) => _checkStateAndNavigate());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkStateAndNavigate() async {
    // Add a slight delay for realistic visual premium feel
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final authState = ref.read(authProvider);
    final prefs = ref.read(preferencesServiceProvider);
    final onboardingCompleted = prefs.isOnboardingCompleted();

    if (authState.status == AuthStatus.authenticated) {
      if (onboardingCompleted) {
        context.go('/dashboard');
      } else {
        context.go('/onboarding');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const LanSpeechLogo(
                        size: 130,
                        showText: true,
                        isDark: true,
                      ),
                      const SizedBox(height: 60),
                      const _CustomLoadingIndicator(size: 36),
                      const SizedBox(height: 16),
                      Text(
                        'Readying your exercises...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.lightBackground.withOpacity(0.7),
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
