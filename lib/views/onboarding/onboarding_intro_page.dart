import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Welcome Illustration
                  Expanded(
                    flex: 4,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        image: const DecorationImage(
                          image: AssetImage('images/onboarding_welcome.png'),
                          fit: BoxFit.contain,
                        ),
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
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A237E),
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.onboardingWelcomeSubtitle,
                          style: GoogleFonts.barlow(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Roadmap Steps
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                  ),

                  // Bottom Controls
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: onNext,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: Text(
                              AppLocalizations.of(context)!.getStarted,
                              style: GoogleFonts.barlow(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5E35B1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: onShowApiKeyDialog,
                          icon: const Icon(
                            Icons.key,
                            size: 16,
                            color: Colors.black26,
                          ),
                          label: Text(
                            // Reusing existing string for API key
                            AppLocalizations.of(context)!.enterApiKeyHackathon,
                            style: GoogleFonts.barlow(
                              color: Colors.black26,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
                color: const Color(0xFF5E35B1).withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF5E35B1), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.barlow(
              fontSize: 14,
              color: Colors.black87,
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
        color: const Color(0xFF5E35B1).withValues(alpha: 0.2),
      ),
    );
  }
}
