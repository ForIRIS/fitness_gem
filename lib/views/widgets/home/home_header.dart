import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../domain/entities/user_profile.dart';

class HomeHeader extends StatelessWidget {
  final UserProfile? userProfile;
  final VoidCallback onOpenAIChat;
  final VoidCallback onOpenSettings;
  final VoidCallback? onOpenStatistics;
  final bool isCompleted;
  final bool isInProgress;
  final bool areNotificationsEnabled;
  final bool hasUnreadNotifications;
  final VoidCallback? onNotificationTap;

  const HomeHeader({
    super.key,
    required this.userProfile,
    required this.onOpenAIChat,
    required this.onOpenSettings,
    this.onOpenStatistics,
    this.isCompleted = false,
    this.isInProgress = false,
    this.areNotificationsEnabled = false,
    this.hasUnreadNotifications = false,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final nickname = userProfile?.nickname;
    final displayName = (nickname != null && nickname.isNotEmpty)
        ? nickname
        : 'Trainee';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted
                      ? AppLocalizations.of(context)!.workoutWellDone
                      : AppLocalizations.of(context)!.welcomeUser(displayName),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCompleted
                      ? AppLocalizations.of(context)!.continueTomorrow
                      : (isInProgress
                            ? AppLocalizations.of(context)!.resumeWorkout
                            : AppLocalizations.of(context)!.readyToWorkout),
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: onNotificationTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.brightMarigold,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        areNotificationsEnabled
                            ? Icons.notifications_none
                            : Icons.notifications_off_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    if (areNotificationsEnabled && hasUnreadNotifications)
                      Positioned(
                        top: 6,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onOpenStatistics,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brightMarigold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onOpenSettings,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brightMarigold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
