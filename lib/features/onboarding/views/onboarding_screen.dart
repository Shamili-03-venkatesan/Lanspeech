import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:lanspeech/core/constants/colors.dart';
import 'package:lanspeech/core/widgets/custom_button.dart';
import 'package:lanspeech/core/widgets/logo_painter.dart';
import 'package:lanspeech/features/curriculum/widgets/coach_voice_player.dart';
import 'package:lanspeech/features/onboarding/providers/onboarding_provider.dart';
import 'package:lanspeech/features/onboarding/models/onboarding_state.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navy : AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Duolingo-style Progress Bar Row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  // Back arrow if not on screen 1
                  AnimatedOpacity(
                    opacity: _currentPage > 0 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: _currentPage == 0,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: isDark ? AppColors.white : AppColors.navy,
                          size: 20,
                        ),
                        onPressed: _prevPage,
                      ),
                    ),
                  ),

                  // Progress Track
                  Expanded(
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF194148)
                            : AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutQuad,
                            width: MediaQuery.of(context).size.width *
                                0.7 *
                                ((_currentPage + 1) / _totalPages),
                            decoration: BoxDecoration(
                              color: AppColors.teal,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.darkTeal,
                                  offset: Offset(0, 2),
                                  blurRadius: 0,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Progress numbers
                  Text(
                    '${_currentPage + 1}/$_totalPages',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? AppColors.yellow : AppColors.teal,
                    ),
                  ),
                ],
              ),
            ),

            // Content Slider
            Expanded(
              child: PageView(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Force guided path buttons
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _PageWelcome(onNext: _nextPage, onSkip: _completeOnboarding),
                  _PageGoals(onNext: _nextPage, state: state, ref: ref),
                  _PageReminder(onNext: _nextPage, state: state, ref: ref),
                  _PageJourney(onNext: _nextPage),
                  _PageReady(onFinish: _completeOnboarding),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SCREEN 1: WELCOME ====================
class _PageWelcome extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _PageWelcome({required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          const LanSpeechLogo(size: 110, showText: false),
          const SizedBox(height: 36),
          Text(
            'Welcome to LanSpeech!',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .displayMedium
                ?.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 16),
          Text(
            'Helping you build speaking confidence one conversation at a time. Through gamified exercises and friendly routines, we make speech practice exciting.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? AppColors.lightBackground.withOpacity(0.9)
                      : AppColors.grey,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 40),
          const _OnboardingCoachVoice(
            text:
                'Welcome to LanSpeech. We will build your speaking confidence together, one comfortable conversation at a time.',
          ),

          // Creative Illustration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF194148) : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded,
                    color: AppColors.teal, size: 28),
                const SizedBox(width: 12),
                Text(
                  'No judgment. Just progress.',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkTeal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          CustomButton(
            text: 'Let\'s Begin!',
            onPressed: onNext,
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Skip Onboarding',
            type: ButtonType.text,
            onPressed: onSkip,
          ),
        ],
      ),
    );
  }
}

// ==================== SCREEN 2: GOALS ====================
class _PageGoals extends StatelessWidget {
  final VoidCallback onNext;
  final OnboardingState state;
  final WidgetRef ref;

  const _PageGoals({
    required this.onNext,
    required this.state,
    required this.ref,
  });

  static const List<Map<String, dynamic>> _goalsData = [
    {
      'title': 'Improve Confidence',
      'desc': 'Overcome social speaking anxiety and share thoughts freely.',
      'icon': Icons.favorite_rounded,
    },
    {
      'title': 'Reduce Stuttering',
      'desc': 'Apply speech pacing, breath control, and sound blending.',
      'icon': Icons.spatial_tracking_rounded,
    },
    {
      'title': 'Speak More Clearly',
      'desc': 'Articulate sounds comfortably with targeted oral exercises.',
      'icon': Icons.volume_up_rounded,
    },
    {
      'title': 'Build Daily Practice',
      'desc': 'Establish a fun, solid, Duolingo-like micro-learning habit.',
      'icon': Icons.bolt_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            'Set Your Speech Goals',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .displayMedium
                ?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            'Select as many as you like. We will customize your daily program.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.lightBackground.withOpacity(0.7)
                      : AppColors.grey,
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: _goalsData.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final goal = _goalsData[index];
                final isSelected = state.selectedGoals.contains(goal['title']);

                return GestureDetector(
                  onTap: () {
                    ref
                        .read(onboardingProvider.notifier)
                        .toggleGoal(goal['title']);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? const Color(0xFF14585C)
                              : AppColors.lightBackground)
                          : (isDark
                              ? const Color(0xFF194148)
                              : AppColors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.teal
                            : (isDark
                                ? Colors.transparent
                                : AppColors.lightGrey),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.teal
                                : AppColors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            goal['icon'],
                            color:
                                isSelected ? AppColors.white : AppColors.teal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal['title'],
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color:
                                      isDark ? AppColors.white : AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                goal['desc'],
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.lightBackground
                                          .withOpacity(0.8)
                                      : AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Checkbox representation
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color:
                              isSelected ? AppColors.teal : AppColors.lightGrey,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const _OnboardingCoachVoice(
            text:
                'Choose the speech goals that matter most to you. Your selections help shape a practice routine that fits your needs.',
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Continue',
            onPressed: state.selectedGoals.isNotEmpty ? onNext : null,
          ),
        ],
      ),
    );
  }
}

// ==================== SCREEN 3: REMINDERS ====================
class _PageReminder extends StatelessWidget {
  final VoidCallback onNext;
  final OnboardingState state;
  final WidgetRef ref;

  const _PageReminder({
    required this.onNext,
    required this.state,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Formatting 24h time to 12h for friendly presentation
    String formatTimeString(String time24h) {
      try {
        final parsed = DateFormat('HH:mm').parse(time24h);
        return DateFormat('h:mm a').format(parsed);
      } catch (_) {
        return time24h;
      }
    }

    void openCustomTimePicker() async {
      TimeOfDay initialTime = const TimeOfDay(hour: 9, minute: 0);
      try {
        final parts = state.reminderTime.split(':');
        initialTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {}

      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.teal,
                onPrimary: AppColors.white,
                onSurface: isDark ? AppColors.white : AppColors.navy,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        final hour = picked.hour.toString().padLeft(2, '0');
        final minute = picked.minute.toString().padLeft(2, '0');
        ref
            .read(onboardingProvider.notifier)
            .setCustomReminderTime('$hour:$minute');
      }
    }

    Widget optionCard(String label, String timeStr, IconData icon) {
      final isSelected = state.reminderLabel == label;
      return GestureDetector(
        onTap: () {
          if (label == 'Custom') {
            openCustomTimePicker();
          } else {
            ref.read(onboardingProvider.notifier).setReminderLabel(label);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF14585C) : AppColors.lightBackground)
                : (isDark ? const Color(0xFF194148) : AppColors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.teal
                  : (isDark ? Colors.transparent : AppColors.lightGrey),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.teal, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? AppColors.white : AppColors.navy,
                      ),
                    ),
                    if (label == 'Custom' && isSelected) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Tap to change time',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    ]
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.teal
                      : AppColors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  timeStr,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSelected ? AppColors.white : AppColors.teal,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            'Daily Speech Reminders',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .displayMedium
                ?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            'Consistency builds fluency! Select a time to practice speaking daily.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.lightBackground.withOpacity(0.7)
                      : AppColors.grey,
                ),
          ),
          const SizedBox(height: 36),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  optionCard('Morning', '8:00 AM', Icons.wb_sunny_rounded),
                  const SizedBox(height: 12),
                  optionCard('Afternoon', '1:00 PM', Icons.sunny_snowing),
                  const SizedBox(height: 12),
                  optionCard('Evening', '7:00 PM', Icons.nightlight_round),
                  const SizedBox(height: 12),
                  optionCard(
                    'Custom',
                    state.reminderLabel == 'Custom'
                        ? formatTimeString(state.reminderTime)
                        : 'Choose time',
                    Icons.alarm_rounded,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _OnboardingCoachVoice(
            text:
                'Pick a reminder time that feels easy to keep. A small daily habit can make speaking practice feel natural.',
          ),
          CustomButton(
            text: 'Continue',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

// ==================== SCREEN 4: LEARNING JOURNEY ====================
class _PageJourney extends StatelessWidget {
  final VoidCallback onNext;

  const _PageJourney({required this.onNext});

  static const List<Map<String, dynamic>> _features = [
    {
      'title': 'Daily Lessons',
      'desc': 'Interactive 5-minute speech pacing exercises.',
      'icon': Icons.menu_book_rounded,
      'color': Colors.blue,
    },
    {
      'title': 'XP & Achievements',
      'desc': 'Earn points as you reach speech fluency thresholds.',
      'icon': Icons.emoji_events_rounded,
      'color': AppColors.yellow,
    },
    {
      'title': 'Practice Streaks',
      'desc': 'Keep your momentum active. Build daily speaking confidence.',
      'icon': Icons.local_fire_department_rounded,
      'color': Colors.orange,
    },
    {
      'title': '30-Day Programs',
      'desc': 'Gradually progress across difficulty chapters at your own rate.',
      'icon': Icons.calendar_month_rounded,
      'color': AppColors.teal,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            'Your Learning Journey',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .displayMedium
                ?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            'Here is what to expect inside your friendly daily speech companion.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.lightBackground.withOpacity(0.7)
                      : AppColors.grey,
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useSingleColumn = constraints.maxWidth < 380;
                return GridView.builder(
                  itemCount: _features.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: useSingleColumn ? 1 : 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: useSingleColumn ? 3.2 : 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final item = _features[index];
                    return Card(
                  color: isDark ? const Color(0xFF194148) : AppColors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item['color'].withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'],
                            color: item['color'],
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item['title'],
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? AppColors.white : AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            item['desc'],
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.lightBackground.withOpacity(0.8)
                                  : AppColors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const _OnboardingCoachVoice(
            text:
                'Your learning journey combines short lessons, progress rewards, practice streaks, and a gradual thirty-day program.',
          ),
          CustomButton(
            text: 'Explore Program',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

// ==================== SCREEN 5: READY ====================
class _PageReady extends StatelessWidget {
  final VoidCallback onFinish;

  const _PageReady({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),

          // Huge premium victory badge represent ready state
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkTeal,
                      offset: Offset(0, 4),
                      blurRadius: 0,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.sentiment_very_satisfied_rounded,
                  color: AppColors.yellow,
                  size: 56,
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
          Text(
            'Ready to Speak!',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .displayMedium
                ?.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'Your personalized roadmap is set up. Step into your speech space and practice confidently daily with LanSpeech!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? AppColors.lightBackground.withOpacity(0.9)
                      : AppColors.grey,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 24),
          const _OnboardingCoachVoice(
            text:
                'You are ready to speak. Open your dashboard whenever you are ready, and we will take the next step together.',
          ),

          const SizedBox(height: 24),
          CustomButton(
            text: 'Enter Dashboard',
            onPressed: onFinish,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _OnboardingCoachVoice extends StatelessWidget {
  final String text;

  const _OnboardingCoachVoice({required this.text});

  @override
  Widget build(BuildContext context) {
    return CoachVoicePlayer(
      text: text,
      autoPlay: false,
    );
  }
}
