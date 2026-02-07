import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class OnboardingFitnessGoalsPage extends StatelessWidget {
  final Set<String> selectedInjuries;
  final void Function(String, bool) onInjurySelected;
  final bool showCustomInjury;
  final TextEditingController customInjuryController;
  final Set<String> selectedGoals;
  final void Function(String, bool) onGoalSelected;
  final bool showCustomGoal;
  final TextEditingController customGoalController;
  final String experienceLevel;
  final void Function(String) onExperienceLevelChanged;

  const OnboardingFitnessGoalsPage({
    super.key,
    required this.selectedInjuries,
    required this.onInjurySelected,
    required this.showCustomInjury,
    required this.customInjuryController,
    required this.selectedGoals,
    required this.onGoalSelected,
    required this.showCustomGoal,
    required this.customGoalController,
    required this.experienceLevel,
    required this.onExperienceLevelChanged,
  });

  // Getters for options (need context)
  List<String> _getInjuryOptions(BuildContext context) => [
    AppLocalizations.of(context)!.none,
    AppLocalizations.of(context)!.neckShoulder,
    AppLocalizations.of(context)!.lowerBack,
    AppLocalizations.of(context)!.knee,
    AppLocalizations.of(context)!.ankle,
    AppLocalizations.of(context)!.wrist,
    AppLocalizations.of(context)!.elbow,
    AppLocalizations.of(context)!.hip,
    AppLocalizations.of(context)!.other,
  ];

  List<String> _getGoalOptions(BuildContext context) => [
    AppLocalizations.of(context)!.strengthBuilding,
    AppLocalizations.of(context)!.weightLoss,
    AppLocalizations.of(context)!.endurance,
    AppLocalizations.of(context)!.flexibility,
    AppLocalizations.of(context)!.postureCorrection,
    AppLocalizations.of(context)!.rehabilitation,
    AppLocalizations.of(context)!.other,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.fitnessGoal,
            style: GoogleFonts.outfit(
              color: AppTheme.indigoInk,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.fitnessGoalDesc,
            style: GoogleFonts.outfit(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),

          // Injury History
          _buildInputLabel(l10n.injuryHistory),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _getInjuryOptions(context).map((injury) {
              final isSelected = selectedInjuries.contains(injury);
              return FilterChip(
                label: Text(injury),
                selected: isSelected,
                selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                backgroundColor: Colors.white,
                checkmarkColor: AppTheme.primary,
                labelStyle: GoogleFonts.outfit(
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                elevation: isSelected ? 2 : 0,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF5E35B1)
                        : Colors.transparent,
                  ),
                ),
                onSelected: (selected) => onInjurySelected(injury, selected),
              );
            }).toList(),
          ),
          if (showCustomInjury) ...[
            const SizedBox(height: 12),
            TextField(
              controller: customInjuryController,
              style: GoogleFonts.outfit(color: AppTheme.textPrimary),
              decoration: _buildInputDecoration(l10n.enterInjuryDetails),
            ),
          ],

          const SizedBox(height: 32),

          // Fitness Goal
          _buildInputLabel(l10n.fitnessGoal),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _getGoalOptions(context).map((goal) {
              final isSelected = selectedGoals.contains(goal);
              return FilterChip(
                label: Text(goal),
                selected: isSelected,
                selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                backgroundColor: Colors.white,
                checkmarkColor: AppTheme.primary,
                labelStyle: GoogleFonts.outfit(
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                elevation: isSelected ? 2 : 0,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF5E35B1)
                        : Colors.transparent,
                  ),
                ),
                onSelected: (selected) => onGoalSelected(goal, selected),
              );
            }).toList(),
          ),
          if (showCustomGoal) ...[
            const SizedBox(height: 12),
            TextField(
              controller: customGoalController,
              style: GoogleFonts.outfit(color: AppTheme.textPrimary),
              decoration: _buildInputDecoration(l10n.enterGoalDetails),
            ),
          ],

          const SizedBox(height: 32),

          // Experience Level
          _buildInputLabel(l10n.experienceLevel),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: experienceLevel,
                isExpanded: true,
                dropdownColor: Colors.white,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.textSecondary,
                ),
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'Beginner',
                    child: Text(l10n.beginner),
                  ),
                  DropdownMenuItem(
                    value: 'Intermediate',
                    child: Text(l10n.intermediate),
                  ),
                  DropdownMenuItem(
                    value: 'Advanced',
                    child: Text(l10n.advanced),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) onExperienceLevelChanged(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: AppTheme.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(
        color: AppTheme.textSecondary.withValues(alpha: 0.5),
      ),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }
}
