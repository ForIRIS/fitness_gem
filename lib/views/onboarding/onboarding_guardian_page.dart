import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

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
          const Icon(Icons.emergency, size: 60, color: Colors.orange),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.safetySettings,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.safetyDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Fall Detection Toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: SwitchListTile(
              title: Text(
                AppLocalizations.of(context)!.enableFallDetection,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.fallDetectionDescription,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              value: widget.fallDetectionEnabled,
              onChanged: widget.onFallDetectionChanged,
              activeThumbColor: Colors.deepPurple,
            ),
          ),

          const SizedBox(height: 24),

          if (widget.fallDetectionEnabled) ...[
            IntlPhoneField(
              controller: widget.guardianController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.guardianPhone,
                labelStyle: const TextStyle(color: Colors.white54),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurple),
                ),
                counterStyle: const TextStyle(color: Colors.white54),
              ),
              initialCountryCode:
                  Localizations.localeOf(context).countryCode ?? 'KR',
              style: const TextStyle(color: Colors.white),
              dropdownTextStyle: const TextStyle(color: Colors.white),
              dropdownIcon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.white,
              ),
              onChanged: (phone) {
                widget.onPhoneChanged(phone.completeNumber);
              },
              onCountryChanged: (country) {
                // Country changed, but completeNumber updates in onChanged when text changes.
              },
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.guardianPhoneDescription,
              style: const TextStyle(color: Colors.white30, fontSize: 12),
            ),
          ],

          const SizedBox(height: 16),
          TextButton(
            onPressed: widget.onSkip,
            child: Text(
              AppLocalizations.of(context)!.setUpLater,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
