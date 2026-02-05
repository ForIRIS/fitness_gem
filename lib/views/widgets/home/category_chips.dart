import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final bool isLoading;
  final String? selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.isLoading,
    this.selectedCategory,
    required this.onCategorySelected,
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
              fontSize: 16,
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
              final isSelected = category == selectedCategory;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GestureDetector(
                  onTap: () => onCategorySelected(category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [AppTheme.capri, AppTheme.irisOrchid],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      border: isSelected
                          ? null
                          : Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.irisOrchid.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      category,
                      style: GoogleFonts.outfit(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
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
