import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lanspeech/core/constants/colors.dart';
import 'package:lanspeech/features/auth/providers/auth_provider.dart';
import 'package:lanspeech/features/curriculum/providers/curriculum_progress_provider.dart';
import 'package:lanspeech/features/gamification/providers/gamification_provider.dart';
import 'package:lanspeech/features/gamification/widgets/stat_block.dart';
import 'package:lanspeech/features/profile/widgets/reminder_settings_tile.dart';
import 'package:lanspeech/features/profile/widgets/subscription_card.dart';

/// The Profile tab, per the MVP brief's User Profile requirement: edit
/// profile, view statistics, manage subscription, change reminder
/// settings.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isSavingName = false;

  Future<void> _editDisplayName(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF194148) : AppColors.white,
        title: Text(
          'Edit Name',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.navy,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == currentName) return;

    setState(() => _isSavingName = true);
    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.updateDisplayName(newName);
      // Refresh authProvider so the new name shows immediately everywhere
      // it's used (this screen, the dashboard greeting, etc.) rather than
      // only after the next natural auth-state event.
      ref.invalidate(authProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  void _handleLogout() async {
    await ref.read(authProvider.notifier).logout();
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final gamification = ref.watch(gamificationProvider);
    final progress = ref.watch(curriculumProgressProvider);

    final displayName =
        authState.user?.userMetadata?['display_name'] as String? ??
            'Speech Learner';
    final email = authState.user?.email ?? authState.demoEmail ?? '';

    return Scaffold(
      backgroundColor: isDark ? AppColors.navy : AppColors.offWhite,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.teal,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'L',
                    style: GoogleFonts.poppins(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontSize: 18),
                      ),
                      Text(
                        email,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _isSavingName
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          Icons.edit_rounded,
                          color: isDark ? AppColors.yellow : AppColors.teal,
                        ),
                        onPressed: () => _editDisplayName(displayName),
                      ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Your Statistics',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 10),
            StatRow(
              stats: [
                StatBlock(
                  value: '${gamification.totalXp}',
                  label: 'XP',
                  icon: Icons.bolt_rounded,
                  iconColor: AppColors.yellow,
                ),
                StatBlock(
                  value: '${gamification.currentStreak}',
                  label: 'Streak',
                  icon: Icons.local_fire_department_rounded,
                  iconColor: Colors.orange,
                ),
                StatBlock(
                  value: '${progress.completedExerciseIds.length}',
                  label: 'Completed',
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.teal,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Subscription',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 10),
            const SubscriptionCard(),
            const SizedBox(height: 24),
            Text(
              'Settings',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 10),
            const ReminderSettingsTile(),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF194148) : AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? AppColors.teal.withOpacity(0.25)
                      : AppColors.lightGrey,
                  width: 1.5,
                ),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                leading:
                    const Icon(Icons.logout_rounded, color: AppColors.error),
                title: Text(
                  'Sign Out',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                onTap: _handleLogout,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
