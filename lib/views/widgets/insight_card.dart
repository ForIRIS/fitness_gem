import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/post_workout_summary.dart';

/// InsightCard - Premium summary card for workout insights
/// Displays headline, subtitle, and bullet points with theme coloring.
class InsightCard extends StatelessWidget {
  final HeadlineCard headline;
  final List<String> bulletPoints;

  const InsightCard({
    super.key,
    required this.headline,
    required this.bulletPoints,
  });

  Color get _themeColor {
    switch (headline.themeColor) {
      case ThemeColor.green:
        return const Color(0xFF4ADE80);
      case ThemeColor.amber:
        return const Color(0xFFFBBF24);
      case ThemeColor.blue:
        return const Color(0xFF60A5FA);
    }
  }

  Color get _backgroundColor {
    switch (headline.themeColor) {
      case ThemeColor.green:
        return const Color(0xFF166534);
      case ThemeColor.amber:
        return const Color(0xFF92400E);
      case ThemeColor.blue:
        return const Color(0xFF1E40AF);
    }
  }

  IconData get _icon {
    switch (headline.themeColor) {
      case ThemeColor.green:
        return Icons.trending_up;
      case ThemeColor.amber:
        return Icons.lightbulb_outline;
      case ThemeColor.blue:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_backgroundColor, _backgroundColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _themeColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Pattern
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              _icon,
              size: 150,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, color: Colors.white, size: 24),
                ),

                const SizedBox(height: 16),

                // Title
                Text(
                  headline.title,
                  style: GoogleFonts.barlowCondensed(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  headline.subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),

                if (bulletPoints.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 16),

                  // Bullet Points
                  ...bulletPoints.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _themeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              point,
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
