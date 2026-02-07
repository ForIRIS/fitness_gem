import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../theme/app_theme.dart';

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
  Color getThemeColor() => Colors.orange; // Keep orange for warning/safety context

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
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.fallDetectionDescription,
              style: GoogleFonts.outfit(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            value: fallDetectionEnabled,
            onChanged: onFallDetectionChanged,
            activeThumbColor: AppTheme.primary,
            activeTrackColor: AppTheme.primary.withValues(alpha: 0.2),
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
              labelStyle: GoogleFonts.outfit(color: AppTheme.textSecondary),
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
                  color: AppTheme.primary,
                  width: 1.5,
                ),
              ),
              counterStyle: GoogleFonts.outfit(color: AppTheme.textSecondary),
            ),
            initialCountryCode:
                Localizations.localeOf(context).countryCode ?? 'KR',
            style: GoogleFonts.outfit(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            dropdownTextStyle: GoogleFonts.outfit(color: AppTheme.textPrimary),
            dropdownIcon: const Icon(
              Icons.arrow_drop_down,
              color: AppTheme.textSecondary,
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
                    style: GoogleFonts.outfit(
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
            style: GoogleFonts.outfit(
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
              fontSize: 13,
            ),
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
  Color getThemeColor() => AppTheme.primary;

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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
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
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.guardianEmailNotice,
                  style: GoogleFonts.outfit(
                    color: Colors.orange[800],
                    fontSize: 12,
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
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
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
