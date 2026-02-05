import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';

/// Abstract Strategy for Guardian Page Content
abstract class GuardianStrategy {
  Widget buildContent(
    BuildContext context, {
    required bool fallDetectionEnabled,
    required Function(bool) onFallDetectionChanged,
    required TextEditingController guardianController,
    required Function(String) onPhoneChanged,
  });

  String getTitle(BuildContext context);
  String getDescription(BuildContext context);
  IconData getIcon();
  Color getThemeColor();
}

/// SMS Strategy: SMS Emergency Contact (Primary for Android)
class SMSGuardianStrategy implements GuardianStrategy {
  @override
  String getTitle(BuildContext context) =>
      AppLocalizations.of(context)!.safetySettings;

  @override
  String getDescription(BuildContext context) =>
      AppLocalizations.of(context)!.safetyDescription;

  @override
  IconData getIcon() => Icons.emergency;

  @override
  Color getThemeColor() => Colors.orange;

  @override
  Widget buildContent(
    BuildContext context, {
    required bool fallDetectionEnabled,
    required Function(bool) onFallDetectionChanged,
    required TextEditingController guardianController,
    required Function(String) onPhoneChanged,
  }) {
    return Column(
      children: [
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
            value: fallDetectionEnabled,
            onChanged: onFallDetectionChanged,
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

        if (fallDetectionEnabled) ...[
          IntlPhoneField(
            controller: guardianController,
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
              onPhoneChanged(phone.completeNumber);
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
    );
  }
}

/// Push Strategy: AI Safety Consulting (Push Notifications for iOS, Web, Desktop)
class PushGuardianStrategy implements GuardianStrategy {
  @override
  String getTitle(BuildContext context) =>
      AppLocalizations.of(context)!.safetyGuardianTitle;

  @override
  String getDescription(BuildContext context) =>
      AppLocalizations.of(context)!.safetyGuardianDescription;

  @override
  IconData getIcon() => Icons.celebration; // Celebration icon for final page

  @override
  Color getThemeColor() => const Color(0xFF5E35B1); // Deep Purple

  @override
  Widget buildContent(
    BuildContext context, {
    required bool fallDetectionEnabled,
    required Function(bool) onFallDetectionChanged,
    required TextEditingController guardianController,
    required Function(String) onPhoneChanged,
  }) {
    return Column(
      children: [
        // AI Consulting Opt-in Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5E35B1).withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.safetyGuardianTitle,
                          style: GoogleFonts.barlow(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.safetyGuardianDescription,
                          style: GoogleFonts.barlow(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              _buildBenefitItem(
                Icons.check_circle_outline,
                AppLocalizations.of(context)!.benefitFallDetectionTitle,
                AppLocalizations.of(context)!.benefitFallDetectionDesc,
              ),
              const SizedBox(height: 12),
              _buildBenefitItem(
                Icons.sms_outlined,
                AppLocalizations.of(context)!.benefitGuardianEmailTitle,
                AppLocalizations.of(context)!.benefitGuardianEmailDesc,
              ),
              const SizedBox(height: 12),
              _buildBenefitItem(
                Icons.security,
                AppLocalizations.of(context)!.benefitEmergencyPushTitle,
                AppLocalizations.of(context)!.benefitEmergencyPushDesc,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.guardianEmailNotice,
                  style: GoogleFonts.barlow(
                    color: Colors.orange[800],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black45),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.barlow(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.barlow(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Simple Factory to get Strategy
class GuardianStrategyFactory {
  static GuardianStrategy getStrategy(TargetPlatform platform) {
    if (!kIsWeb && platform == TargetPlatform.android) {
      return SMSGuardianStrategy();
    } else {
      return PushGuardianStrategy();
    }
  }
}
