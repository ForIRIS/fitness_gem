import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'guardian_strategy.dart';

class OnboardingGuardianPage extends StatefulWidget {
  final bool fallDetectionEnabled;
  final Function(bool) onFallDetectionChanged;
  final TextEditingController guardianController;
  final Function(String) onPhoneChanged;
  final VoidCallback onSkip;

  const OnboardingGuardianPage({
    super.key,
    required this.fallDetectionEnabled,
    required this.onFallDetectionChanged,
    required this.guardianController,
    required this.onPhoneChanged,
    required this.onSkip,
  });

  @override
  State<OnboardingGuardianPage> createState() => _OnboardingGuardianPageState();
}

class _OnboardingGuardianPageState extends State<OnboardingGuardianPage> {
  GuardianStrategy? _strategy;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_strategy == null) {
      final platform = Theme.of(context).platform;
      _strategy = GuardianStrategyFactory.getStrategy(platform);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Prevent keyboard overlap issues
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _strategy!.getThemeColor().withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              _strategy!.getIcon(),
              size: 64,
              color: _strategy!.getThemeColor(),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            AppLocalizations.of(context)!.welcomeReady, // "준비가 되었습니다!" (Ready!)
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: AppTheme.indigoInk,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppLocalizations.of(context)!.onboardingWelcomeSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppTheme.textSecondary,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Feature Spotlight: Safety Guardian
          Text(
            _strategy!.getTitle(context),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: _strategy!.getThemeColor(),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _strategy!.getDescription(context),
            textAlign: TextAlign.start,
            style: GoogleFonts.outfit(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Strategy Content
          _strategy!.buildContent(
            context,
            fallDetectionEnabled: widget.fallDetectionEnabled,
            onFallDetectionChanged: widget.onFallDetectionChanged,
            guardianController: widget.guardianController,
            onPhoneChanged: widget.onPhoneChanged,
          ),
        ],
      ),
    );
  }
}
