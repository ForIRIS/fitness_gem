import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';

class OnboardingProfilePage extends StatefulWidget {
  final String selectedAgeRange;
  final VoidCallback onAgePickerTap;
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.profileDescription,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),

          // 나이 범위 선택 (탭하면 Bottom Sheet)
          Text(
            AppLocalizations.of(context)!.ageRange,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: widget.onAgePickerTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.selectedAgeRange,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white54),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 부상 이력 (Multi-Select)
          Text(
            AppLocalizations.of(context)!.injuryHistory,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _injuryOptions.map((injury) {
              final isSelected = widget.selectedInjuries.contains(injury);
              return FilterChip(
                label: Text(injury),
                selected: isSelected,
                selectedColor: Colors.deepPurple,
                backgroundColor: Colors.grey[800],
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
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
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterInjuryDetails,
                hintStyle: const TextStyle(color: Colors.white38),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.deepPurple),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // 운동 목표 (Single Select)
          Text(
            AppLocalizations.of(context)!.fitnessGoal,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _goalOptions.map((goal) {
              final isSelected = widget.selectedGoals.contains(goal);
              return FilterChip(
                label: Text(goal),
                selected: isSelected,
                selectedColor: Colors.deepPurple,
                backgroundColor: Colors.grey[800],
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                ),
                onSelected: (selected) => widget.onGoalSelected(goal, selected),
              );
            }).toList(),
          ),
          if (widget.showCustomGoal) ...[
            const SizedBox(height: 12),
            TextField(
              controller: widget.customGoalController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterGoalDetails,
                hintStyle: const TextStyle(color: Colors.white38),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.deepPurple),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // 운동 경험
          Text(
            AppLocalizations.of(context)!.experienceLevel,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: widget.experienceLevel,
              isExpanded: true,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              underline: const SizedBox(),
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
