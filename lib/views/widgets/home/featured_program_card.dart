import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../domain/entities/featured_program.dart'; // Ensure this exists or use appropriate import

class FeaturedProgramCard extends StatelessWidget {
  final FeaturedProgram? program;
  final VoidCallback onApply;
  final VoidCallback onRetry;

  const FeaturedProgramCard({
    super.key,
    required this.program,
    required this.onApply,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (program == null) {
      // Show error message
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
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
        ),
      );
    }

    final validProgram = program!;
    final isNetworkImage = validProgram.imageUrl.startsWith('http');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          onApply();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Applied to dashboard')));
        },
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
                      ? Image.network(
                          validProgram.imageUrl,
                          fit: BoxFit.contain,
                        )
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
                        Column(
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
                        // Star/Dot Rating
                        Row(
                          children: List.generate(
                            5,
                            (index) => Container(
                              margin: const EdgeInsets.only(left: 4),
                              width: index == 4 ? 8 : 4,
                              height: index == 4 ? 8 : 4,
                              decoration: BoxDecoration(
                                color: index < validProgram.rating
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: index >= validProgram.rating
                                    ? Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                            ),
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
                                      color: Colors.grey[300],
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          validProgram.userAvatars[index],
                                        ),
                                        fit: BoxFit.cover,
                                      ),
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
                    SizedBox(
                      width: 250, // Constrain width to wrap text nicely
                      child: Text(
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
                    ),
                  ],
                ),
              ),

              // 3. Floating Action Button
              Positioned(
                bottom: 28,
                right: 28,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.arrow_outward,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
