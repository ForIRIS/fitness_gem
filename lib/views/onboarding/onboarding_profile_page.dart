import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingProfilePage extends StatefulWidget {
  final String selectedAgeRange;
  final VoidCallback onAgePickerTap;
  final TextEditingController nicknameController;
  final Set<String> selectedInjuries;
  final Function(String, bool) onInjurySelected;
  final bool showCustomInjury;
  final TextEditingController customInjuryController;
  final Set<String> selectedGoals;
  final Function(String, bool) onGoalSelected;
  final bool showCustomGoal;
  final TextEditingController customGoalController;
  final String experienceLevel;
  final Function(String) onExperienceLevelChanged;

  const OnboardingProfilePage({
    super.key,
    required this.selectedAgeRange,
    required this.onAgePickerTap,
    required this.nicknameController,
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

  @override
  State<OnboardingProfilePage> createState() => _OnboardingProfilePageState();
}

class _OnboardingProfilePageState extends State<OnboardingProfilePage> {
  // Getters for options (must be here to access context for localization)
  List<String> get _injuryOptions => [
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

  List<String> get _goalOptions => [
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.profileInfo,
            style: GoogleFonts.barlowCondensed(
              color: const Color(0xFF1A237E),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.profileDescription,
            style: GoogleFonts.barlow(color: Colors.black54, fontSize: 16),
          ),
          const SizedBox(height: 32),

          // Nickname Input
          _buildInputLabel(AppLocalizations.of(context)!.nickname),
          const SizedBox(height: 12),
          TextField(
            controller: widget.nicknameController,
            style: GoogleFonts.barlow(color: Colors.black87),
            decoration: _buildInputDecoration(
              AppLocalizations.of(context)!.enterNickname,
            ),
          ),
          const SizedBox(height: 32),

          // Age Range Selection (Show Bottom Sheet on Tap)
          _buildInputLabel(AppLocalizations.of(context)!.ageRange),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: widget.onAgePickerTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.selectedAgeRange,
                    style: GoogleFonts.barlow(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.black54),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Injury History (Multi-Select)
          _buildInputLabel(AppLocalizations.of(context)!.injuryHistory),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _injuryOptions.map((injury) {
              final isSelected = widget.selectedInjuries.contains(injury);
              return FilterChip(
                label: Text(injury),
                selected: isSelected,
                selectedColor: const Color(0xFFE1BEE7),
                backgroundColor: Colors.white,
                checkmarkColor: const Color(0xFF5E35B1),
                labelStyle: GoogleFonts.barlow(
                  color: isSelected ? const Color(0xFF5E35B1) : Colors.black54,
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
                onSelected: (selected) =>
                    widget.onInjurySelected(injury, selected),
              );
            }).toList(),
          ),
          if (widget.showCustomInjury) ...[
            const SizedBox(height: 12),
            TextField(
              controller: widget.customInjuryController,
              style: GoogleFonts.barlow(color: Colors.black87),
              decoration: _buildInputDecoration(
                AppLocalizations.of(context)!.enterInjuryDetails,
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Fitness Goal (Single Select)
          _buildInputLabel(AppLocalizations.of(context)!.fitnessGoal),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _goalOptions.map((goal) {
              final isSelected = widget.selectedGoals.contains(goal);
              return FilterChip(
                label: Text(goal),
                selected: isSelected,
                selectedColor: const Color(0xFFE1BEE7),
                backgroundColor: Colors.white,
                checkmarkColor: const Color(0xFF5E35B1),
                labelStyle: GoogleFonts.barlow(
                  color: isSelected ? const Color(0xFF5E35B1) : Colors.black54,
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
                onSelected: (selected) => widget.onGoalSelected(goal, selected),
              );
            }).toList(),
          ),
          if (widget.showCustomGoal) ...[
            const SizedBox(height: 12),
            TextField(
              controller: widget.customGoalController,
              style: GoogleFonts.barlow(color: Colors.black87),
              decoration: _buildInputDecoration(
                AppLocalizations.of(context)!.enterGoalDetails,
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Experience Level
          _buildInputLabel(AppLocalizations.of(context)!.experienceLevel),
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
                value: widget.experienceLevel,
                isExpanded: true,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                style: GoogleFonts.barlow(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'Beginner',
                    child: Text(AppLocalizations.of(context)!.beginner),
                  ),
                  DropdownMenuItem(
                    value: 'Intermediate',
                    child: Text(AppLocalizations.of(context)!.intermediate),
                  ),
                  DropdownMenuItem(
                    value: 'Advanced',
                    child: Text(AppLocalizations.of(context)!.advanced),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) widget.onExperienceLevelChanged(val);
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
      style: GoogleFonts.barlow(
        color: Colors.black54,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.barlow(color: Colors.black38),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF5E35B1), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }
}
