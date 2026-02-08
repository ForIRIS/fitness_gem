import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class OnboardingIntroPage extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onShowApiKeyDialog;

  const OnboardingIntroPage({
    super.key,
    required this.onNext,
    required this.onShowApiKeyDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Scrollable Content
        SingleChildScrollView(
          padding: const EdgeInsets.only(
            bottom: 200,
          ), // Space for floating bottom
          child: Column(
            children: [
              // Welcome Illustration
              Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/images/onboarding_welcome.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title & Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.onboardingWelcomeTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.indigoInk,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.onboardingWelcomeSubtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Roadmap Steps
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    _buildStepItem(
                      context,
                      icon: Icons.person_outline_rounded,
                      text: AppLocalizations.of(
                        context,
                      )!.onboardingStep1Description,
                      isFirst: true,
                    ),
                    _buildConnector(),
                    _buildStepItem(
                      context,
                      icon: Icons.mic_none_rounded,
                      text: AppLocalizations.of(
                        context,
                      )!.onboardingStep2Description,
                    ),
                    _buildConnector(),
                    _buildStepItem(
                      context,
                      icon: Icons.camera_alt_outlined,
                      text: AppLocalizations.of(
                        context,
                      )!.onboardingStep3Description,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. Floating Bottom Controls
        Positioned(
          left: 24,
          right: 24,
          bottom: -24,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        AppLocalizations.of(context)!.getStarted,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onShowApiKeyDialog,
                    icon: const Icon(
                      Icons.key,
                      size: 16,
                      color: Colors.black26,
                    ),
                    label: Text(
                      AppLocalizations.of(context)!.enterApiKeyHackathon,
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: AppTheme.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnector() {
    return Container(
      margin: const EdgeInsets.only(left: 24),
      padding: const EdgeInsets.symmetric(vertical: 4),
      alignment: Alignment.centerLeft,
      child: Container(
        height: 24,
        width: 2,
        color: AppTheme.primary.withValues(alpha: 0.2),
      ),
    );
  }
}
