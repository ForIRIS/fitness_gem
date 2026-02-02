import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final bool isLoading;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            AppLocalizations.of(context)!.dailyHotCategories,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.textPrimary, // Dark text
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  elevation: 0,
                  backgroundColor: Colors.white,
                  shape: const StadiumBorder(
                    side: BorderSide(color: Color(0xFFE2E8F0)),
                  ), // Slate 200 border
                  label: Text(
                    category,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B), // Slate 500
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
