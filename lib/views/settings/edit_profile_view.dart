import 'package:flutter/material.dart';
import '../../domain/entities/user_profile.dart';
import '../onboarding/onboarding_profile_page.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';

class EditProfileView extends StatefulWidget {
  final UserProfile profile;

  const EditProfileView({super.key, required this.profile});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  // Config options (copied from OnboardingView for consistency)
  static const List<String> _ageRanges = [
    '16~19',
    '20~24',
    '25~29',
    '30~34',
    '35~39',
    '40~44',
    '45~49',
    '50~54',
    '55~59',
    '60~64',
    '65+',
  ];

  // State
  late TextEditingController _nicknameController;
  late String _selectedAgeRange;
  final Set<String> _selectedInjuries = {};
  late TextEditingController _customInjuryController;
  late bool _showCustomInjury;
  final Set<String> _selectedGoals = {};
  late TextEditingController _customGoalController;
  late bool _showCustomGoal;
  late String _experienceLevel;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    final p = widget.profile;
    _nicknameController = TextEditingController(text: p.nickname);
    _selectedAgeRange = p.age.toString(); // Convert int to string
    _experienceLevel = p.fitnessLevel; // Use fitnessLevel

    // Injuries
    _customInjuryController = TextEditingController();
    _showCustomInjury = false;

    // Parse injuries (healthConditions)
    if (p.healthConditions.isNotEmpty) {
      final injuries = p.healthConditions.split(', ');
      for (var injury in injuries) {
        _selectedInjuries.add(injury);
      }
    }

    // Goals
    _customGoalController = TextEditingController();
    _showCustomGoal = false;
    if (p.goal.isNotEmpty) {
      final goals = p.goal.split(', ');
      _selectedGoals.addAll(goals);
    }
  }

  // Need context for 'Other', so we might need to adjust after build or in build.
  // Actually, OnboardingView logic was based on "Other" in the set.
  // If the saved string was "Neck/Shoulder, Custom Injury", parsing it back is hard without delimiters.
  // The UserProfile saves as comma joined string.

  // IMPROVEMENT: For a proper edit view, we should ideally parse better.
  // But given it's stored as plain string "A, B, C", we will just load it.
  // The OnboardingProfilePage checks `selectedInjuries.contains('Other')`.
  // So if 'Other' token is lost or translated, it breaks.
  // We'll trust the user to re-enter if it looks weird.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          AppLocalizations.of(context)!.profileInfo,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              AppLocalizations.of(context)!.save,
              style: const TextStyle(
                color: Colors.deepPurpleAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : OnboardingProfilePage(
              selectedAgeRange: _selectedAgeRange,
              onAgePickerTap: _showAgePickerBottomSheet,
              nicknameController: _nicknameController,
              selectedInjuries: _selectedInjuries,
              onInjurySelected: _onInjurySelected,
              showCustomInjury: _showCustomInjury,
              customInjuryController: _customInjuryController,
              selectedGoals: _selectedGoals,
              onGoalSelected: _onGoalSelected,
              showCustomGoal: _showCustomGoal,
              customGoalController: _customGoalController,
              experienceLevel: _experienceLevel,
              onExperienceLevelChanged: (val) =>
                  setState(() => _experienceLevel = val),
            ),
    );
  }

  void _onInjurySelected(String injury, bool selected) {
    setState(() {
      if (injury == AppLocalizations.of(context)!.none) {
        _selectedInjuries.clear();
        if (selected) _selectedInjuries.add(injury);
        _showCustomInjury = false;
      } else {
        _selectedInjuries.remove(AppLocalizations.of(context)!.none);
        if (selected) {
          _selectedInjuries.add(injury);
        } else {
          _selectedInjuries.remove(injury);
        }
        _showCustomInjury = _selectedInjuries.contains(
          AppLocalizations.of(context)!.other,
        );
      }
    });
  }

  void _onGoalSelected(String goal, bool selected) {
    setState(() {
      if (selected) {
        _selectedGoals.add(goal);
      } else {
        _selectedGoals.remove(goal);
      }
      _showCustomGoal = _selectedGoals.contains(
        AppLocalizations.of(context)!.other,
      );
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    // Create updated profile using copyWith (immutable)
    final updatedProfile = widget.profile.copyWith(
      nickname: _nicknameController.text.trim().isEmpty
          ? 'Trainee'
          : _nicknameController.text.trim(),
      age:
          int.tryParse(_selectedAgeRange.split('~').first) ??
          widget.profile.age,
      fitnessLevel: _experienceLevel,
      healthConditions: _showCustomInjury
          ? _customInjuryController.text
          : _selectedInjuries.join(', '),
      goal: _showCustomGoal
          ? _customGoalController.text
          : _selectedGoals.join(', '),
      updatedAt: DateTime.now(),
    );

    // Note: Profile persistence not supported with immutable entities
    // TODO: Save through repository when available
    // await UserProfile.saveProfile(updatedProfile);

    debugPrint('Profile updated: ${updatedProfile.nickname}');

    if (!mounted) return;
    Navigator.pop(context, updatedProfile); // Return updated profile
  }

  // --- Bottom Sheet for Age Picker (Copied) ---
  void _showAgePickerBottomSheet() {
    int initialIndex = _ageRanges.indexOf(_selectedAgeRange);
    if (initialIndex == -1) initialIndex = 2;

    String tempSelection = _selectedAgeRange;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.selectAgeRange,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _selectedAgeRange = tempSelection);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: FixedExtentScrollController(
                        initialItem: initialIndex,
                      ),
                      itemExtent: 44,
                      diameterRatio: 1.2,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setModalState(() {
                          tempSelection = _ageRanges[index];
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: _ageRanges.length,
                        builder: (context, index) {
                          final isSelected = _ageRanges[index] == tempSelection;
                          return Center(
                            child: Text(
                              _ageRanges[index],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.deepPurple
                                    : Colors.white54,
                                fontSize: isSelected ? 20 : 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _customInjuryController.dispose();
    _customGoalController.dispose();
    super.dispose();
  }
}
