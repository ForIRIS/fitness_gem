import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';

/// Amber Mode Content Widget
/// Displayed when a fall is suspected but not yet confirmed.
/// Shows a semi-transparent amber overlay with "I'm OK" dismissal button.
class AmberModeContent extends StatelessWidget {
  final VoidCallback onDismiss;

  const AmberModeContent({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.orange.withValues(alpha: 0.85),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.visibility,
                color: Colors.white,
                size: 64,
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              AppLocalizations.of(context)!.emergencyCheckingStatus,
              style: GoogleFonts.barlowCondensed(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Subtitle
            Text(
              AppLocalizations.of(context)!.emergencyPleaseRest,
              style: GoogleFonts.barlow(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 18,
              ),
            ),

            const Spacer(flex: 1),

            // Loading Indicator
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),

            const Spacer(flex: 2),

            // Dismiss Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange[800],
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.emergencyImOk,
                    style: GoogleFonts.barlow(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
