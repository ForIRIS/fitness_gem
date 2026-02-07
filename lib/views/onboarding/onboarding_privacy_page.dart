import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class OnboardingPrivacyPage extends StatefulWidget {
  final bool isAgreed;
  final ValueChanged<bool> onAgreementChanged;

  const OnboardingPrivacyPage({
    super.key,
    required this.isAgreed,
    required this.onAgreementChanged,
  });

  @override
  State<OnboardingPrivacyPage> createState() => _OnboardingPrivacyPageState();
}

class _OnboardingPrivacyPageState extends State<OnboardingPrivacyPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.privacy_tip_outlined,
                size: 64,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            l10n.privacyPolicyTitle,
            style: GoogleFonts.outfit(
              color: AppTheme.indigoInk,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.privacyPolicyIntro,
            style: GoogleFonts.outfit(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),

          // Policy Points
          _buildPolicyPoint(
            context,
            icon: Icons.smartphone,
            title: l10n.privacyLocalTitle,
            description: l10n.privacyLocalDesc,
          ),
          const SizedBox(height: 24),
          _buildPolicyPoint(
            context,
            icon: Icons.cloud_off,
            title: l10n.privacyGeminiTitle,
            description: l10n.privacyGeminiDesc,
          ),
          const SizedBox(height: 24),
          _buildPolicyPoint(
            context,
            icon: Icons.verified_user,
            title: l10n.privacyMinimalTitle,
            description: l10n.privacyMinimalDesc,
          ),

          const SizedBox(height: 48),

          // Agreement Checkbox
          InkWell(
            onTap: () => widget.onAgreementChanged(!widget.isAgreed),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.isAgreed
                      ? AppTheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: widget.isAgreed,
                    activeColor: AppTheme.primary,
                    onChanged: (val) {
                      widget.onAgreementChanged(val ?? false);
                    },
                  ),
                  Expanded(
                    child: Text(
                      l10n.privacyAgreement,
                      style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyPoint(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primary, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.outfit(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
