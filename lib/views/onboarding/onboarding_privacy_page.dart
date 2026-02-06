import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';

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
                color: const Color(0xFF5E35B1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.privacy_tip_outlined,
                size: 64,
                color: Color(0xFF5E35B1),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            l10n.privacyPolicyTitle ?? 'Privacy & Data Policy',
            style: GoogleFonts.barlowCondensed(
              color: const Color(0xFF1A237E),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.privacyPolicyIntro ??
                'Your privacy is our top priority. Before we start, please review how we handle your data.',
            style: GoogleFonts.barlow(color: Colors.black54, fontSize: 16),
          ),
          const SizedBox(height: 32),

          // Policy Points
          _buildPolicyPoint(
            context,
            icon: Icons.smartphone,
            title: l10n.privacyLocalTitle ?? 'Local Storage First',
            description:
                l10n.privacyLocalDesc ??
                'Biometric data (Height, Weight, Gender) is stored securely on your device.',
          ),
          const SizedBox(height: 24),
          _buildPolicyPoint(
            context,
            icon: Icons.cloud_off,
            title: l10n.privacyGeminiTitle ?? 'Gemini AI Analysis',
            description:
                l10n.privacyGeminiDesc ??
                'We send minimal data to Gemini for real-time coaching. Your data is NOT used to train Google\'s models.',
          ),
          const SizedBox(height: 24),
          _buildPolicyPoint(
            context,
            icon: Icons.verified_user,
            title: l10n.privacyMinimalTitle ?? 'Minimal Collection',
            description:
                l10n.privacyMinimalDesc ??
                'We only collect email for secure sign-in. No other personal identifiers are shared.',
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
                      ? const Color(0xFF5E35B1)
                      : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: widget.isAgreed,
                    activeColor: const Color(0xFF5E35B1),
                    onChanged: (val) {
                      widget.onAgreementChanged(val ?? false);
                    },
                  ),
                  Expanded(
                    child: Text(
                      l10n.privacyAgreement ??
                          'I have read and agree to the Privacy Policy.',
                      style: GoogleFonts.barlow(
                        color: Colors.black87,
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
        Icon(icon, color: const Color(0xFF5E35B1), size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.barlow(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.barlow(
                  color: Colors.black54,
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
