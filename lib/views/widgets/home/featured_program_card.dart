import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../domain/entities/featured_program.dart'; // Ensure this exists or use appropriate import

class FeaturedProgramCard extends StatelessWidget {
  final FeaturedProgram? program;
  final VoidCallback onRetry;
  final VoidCallback onTapCard;

  const FeaturedProgramCard({
    super.key,
    required this.program,
    required this.onRetry,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    if (program == null) {
      // Show error message
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.failedToLoadFeatured,
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    final validProgram = program!;
    final isNetworkImage = validProgram.imageUrl.startsWith('http');

    return GestureDetector(
      onTap: onTapCard,
      child: Container(
        height: 420, // Taller card as per design
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              AppTheme.capri, // Blue (15-4722 TCX)
              AppTheme.irisOrchid, // Purple (17-3323 TCX)
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.irisOrchid.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 1. Workout Image (Dynamic Placement)
            if (validProgram.imageUrl.isNotEmpty)
              Positioned(
                right: -40,
                top: 60,
                bottom: 0,
                child: isNetworkImage
                    ? Image.network(validProgram.imageUrl, fit: BoxFit.contain)
                    : Image.asset(validProgram.imageUrl, fit: BoxFit.contain),
              ),

            // 1.5 Blur Gradient Effect (Bottom-Center)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      AppTheme.irisOrchid.withValues(
                        alpha: 0.9,
                      ), // Deep blurred effect at bottom
                      AppTheme.irisOrchid.withValues(alpha: 0.0), // Fades out
                    ],
                  ),
                ),
              ),
            ),

            // 2. Content Overlay
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              validProgram.title,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              validProgram.slogan,
                              style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Avatar Group
                  Row(
                    children: [
                      SizedBox(
                        width: 60,
                        height: 24,
                        child: Stack(
                          children: List.generate(
                            validProgram.userAvatars.length.clamp(0, 3),
                            (index) {
                              // Mock Avatar Colors
                              final colors = [
                                const Color(0xFF5E35B1), // Purple
                                const Color(0xFFEF5350), // Red
                                const Color(0xFF26A69A), // Teal
                              ];

                              return Positioned(
                                left: index * 16.0,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                    color: colors[index % colors.length],
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${validProgram.membersCount}\n${AppLocalizations.of(context)!.members}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 10,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Main Title Description
                  Text(
                    validProgram.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ), // End content padding
          ],
        ),
      ),
    );
  }
}
