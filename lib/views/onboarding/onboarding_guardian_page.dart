import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:google_fonts/google_fonts.dart';

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
                  color: Colors.orange.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.emergency, size: 64, color: Colors.orange),
          ),
          const SizedBox(height: 32),
          Text(
            AppLocalizations.of(context)!.safetySettings,
            textAlign: TextAlign.center,
            style: GoogleFonts.barlowCondensed(
              color: const Color(0xFF1A237E),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.safetyDescription,
            textAlign: TextAlign.center,
            style: GoogleFonts.barlow(color: Colors.black54, fontSize: 16),
          ),
          const SizedBox(height: 48),

          // Fall Detection Toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SwitchListTile(
              title: Text(
                AppLocalizations.of(context)!.enableFallDetection,
                style: GoogleFonts.barlow(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.fallDetectionDescription,
                style: GoogleFonts.barlow(color: Colors.black45, fontSize: 13),
              ),
              value: widget.fallDetectionEnabled,
              onChanged: widget.onFallDetectionChanged,
              activeThumbColor: const Color(0xFF5E35B1),
              activeTrackColor: const Color(0xFFD1C4E9),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.withValues(alpha: 0.2),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
            ),
          ),

          const SizedBox(height: 24),

          if (widget.fallDetectionEnabled) ...[
            IntlPhoneField(
              controller: widget.guardianController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.guardianPhone,
                labelStyle: GoogleFonts.barlow(color: Colors.black45),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF5E35B1),
                    width: 1.5,
                  ),
                ),
                counterStyle: GoogleFonts.barlow(color: Colors.black54),
              ),
              initialCountryCode:
                  Localizations.localeOf(context).countryCode ?? 'KR',
              style: GoogleFonts.barlow(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              dropdownTextStyle: GoogleFonts.barlow(color: Colors.black87),
              dropdownIcon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.black54,
              ),
              onChanged: (phone) {
                widget.onPhoneChanged(phone.completeNumber);
              },
              onCountryChanged: (country) {
                // Country changed
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.guardianStorageNotice,
                      style: GoogleFonts.barlow(
                        color: Colors.green[800],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.guardianPhoneDescription,
              style: GoogleFonts.barlow(color: Colors.black38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
