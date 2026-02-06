import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:fitness_gem/l10n/app_localizations.dart';
import '../domain/entities/user_profile.dart';
import '../core/di/injection.dart';
import '../domain/usecases/ai/get_api_key_usecase.dart';
import '../domain/usecases/ai/set_api_key_usecase.dart';
import '../domain/usecases/user/update_user_profile.dart';
import 'onboarding/onboarding_intro_page.dart';
import 'onboarding/onboarding_basic_info_page.dart';
import 'onboarding/onboarding_photo_page.dart';
import 'onboarding/onboarding_body_stats_page.dart';
import 'onboarding/onboarding_fitness_goals_page.dart';
import 'onboarding/onboarding_exercise_page.dart';
import 'onboarding/onboarding_guardian_page.dart';
import 'onboarding/onboarding_privacy_page.dart';
import 'dart:io';

import 'ai_interview_view.dart';
import 'home_view.dart' as home;

/// OnboardingView - Onboarding Screen
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form Controllers
  final TextEditingController _nicknameController = TextEditingController();
  String _selectedAgeRange = '25~29';
  String _selectedGender = 'prefer_not_to_say';
  File? _profilePhoto;
  double _height = 170.0;
  double _weight = 70.0;

  final Set<String> _selectedInjuries = {};
  final TextEditingController _customInjuryController = TextEditingController();
  bool _showCustomInjury = false;
  final Set<String> _selectedGoals = {};
  final TextEditingController _customGoalController = TextEditingController();
  bool _showCustomGoal = false;
  String _experienceLevel = 'Beginner';
  final TextEditingController _exerciseController = TextEditingController();
  final TextEditingController _guardianController = TextEditingController();
  String? _completeGuardianPhone;

  // Age range list
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

  // Whether to show disclaimer popup
  bool _showDisclaimer = false;
  bool _pendingAIStart =
      false; // Whether to go to AI after agreeing to disclaimer

  // Feature settings
  bool _fallDetectionEnabled = false;
  bool _privacyAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5), // Light purple/pink background
      body: Stack(
        children: [
          // 1. Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE1BEE7), // Lighter Purple
                    Color(0xFFF3E5F5), // Base
                    Color(0xFFE3F2FD), // Light Blue tint
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // 2. Content
          SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Progress indicator (Maintain height to avoid jump)
                    SizedBox(
                      height: 100, // Increased height for more breathing room
                      child:
                          _currentPage >
                              1 // Hide on Privacy (0) and Intro (1) ? Or just Privacy?
                          ? _buildProgressIndicator()
                          : null,
                    ),

                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (page) =>
                            setState(() => _currentPage = page),
                        children: [
                          // 1. Privacy Page (Index 0)
                          OnboardingPrivacyPage(
                            isAgreed: _privacyAgreed,
                            onAgreementChanged: (val) =>
                                setState(() => _privacyAgreed = val),
                          ),

                          // 2. Intro Page (Index 1)
                          OnboardingIntroPage(
                            key: const ValueKey('onboarding_intro'),
                            onNext: _nextPage,
                            onShowApiKeyDialog: _showApiKeyDialog,
                          ),

                          // 3. Basic Info (Index 2)
                          OnboardingBasicInfoPage(
                            key: const ValueKey('onboarding_basic_info'),
                            nicknameController: _nicknameController,
                            selectedAgeRange: _selectedAgeRange,
                            onAgePickerTap: _showAgePickerBottomSheet,
                            selectedGender: _selectedGender,
                            onGenderSelected: (val) =>
                                setState(() => _selectedGender = val),
                          ),

                          // 4. Photo (Index 3)
                          OnboardingPhotoPage(
                            key: const ValueKey('onboarding_photo'),
                            selectedImage: _profilePhoto,
                            onImageSelected: (file) =>
                                setState(() => _profilePhoto = file),
                          ),

                          // 5. Body Stats (Index 4)
                          OnboardingBodyStatsPage(
                            key: const ValueKey('onboarding_body_stats'),
                            height: _height,
                            onHeightChanged: (val) =>
                                setState(() => _height = val),
                            weight: _weight,
                            onWeightChanged: (val) =>
                                setState(() => _weight = val),
                          ),

                          // 6. Fitness Goals (Index 5)
                          OnboardingFitnessGoalsPage(
                            key: const ValueKey('onboarding_fitness_goals'),
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

                          // 7. Exercise (Index 6)
                          OnboardingExercisePage(
                            key: const ValueKey('onboarding_exercise'),
                            exerciseController: _exerciseController,
                          ),

                          // 8. Guardian (Index 7)
                          OnboardingGuardianPage(
                            key: const ValueKey('onboarding_guardian'),
                            fallDetectionEnabled: _fallDetectionEnabled,
                            onFallDetectionChanged: (val) =>
                                setState(() => _fallDetectionEnabled = val),
                            guardianController: _guardianController,
                            onPhoneChanged: (phone) =>
                                setState(() => _completeGuardianPhone = phone),
                            onSkip: () {
                              _guardianController.clear();
                              setState(() => _fallDetectionEnabled = false);
                              _onNextPressed();
                            },
                          ),
                        ],
                      ),
                    ),
                    _buildBottomControls(),
                  ],
                ),

                // Disclaimer popup
                if (_showDisclaimer) _buildDisclaimerOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Callbacks for Child Widgets ---

  void _onInjurySelected(String injury, bool selected) {
    setState(() {
      if (injury == AppLocalizations.of(context)!.none) {
        // Clear all others if 'None' is selected
        _selectedInjuries.clear();
        if (selected) _selectedInjuries.add(injury);
        _showCustomInjury = false;
      } else {
        // Remove 'None' if another injury is selected
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

  // --- Helpers ---

  Widget _buildProgressIndicator() {
    // We show progress for steps 3 to 8 (Index 2 to 7)
    // Step 1 maps to Index 2 (Basic Info).
    // Total steps shown in indicator: 6 (Basic Info, Photo, Body, Goals, Exercise, Guardian)

    int currentStepIndex =
        _currentPage - 1; // 1-based index for display (1 to 6)
    int totalSteps = 6;

    String stepTitle = '';
    final l10n = AppLocalizations.of(context)!;

    switch (_currentPage) {
      case 2:
        stepTitle = l10n.profileInfo ?? 'Basic Info';
        break;
      case 3:
        stepTitle = l10n.profilePhotoTitle ?? 'Photo';
        break;
      case 4:
        stepTitle = l10n.bodyStatsTitle ?? 'Body Stats';
        break;
      case 5:
        stepTitle = l10n.fitnessGoal ?? 'Goals';
        break;
      case 6: // Exercise
        stepTitle = 'Target Exercise'; // Need l10n?
        break;
      case 7: // Guardian
        stepTitle = 'Guardian'; // Need l10n?
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.onboardingStepPreview(currentStepIndex, stepTitle),
                style: GoogleFonts.barlow(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
              ),
              Text(
                "$currentStepIndex/$totalSteps",
                style: GoogleFonts.barlow(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(totalSteps, (index) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  decoration: BoxDecoration(
                    color: index < currentStepIndex
                        ? const Color(0xFF5E35B1) // Deep Purple
                        : Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    // 1. Privacy Page Controls (Index 0)
    if (_currentPage == 0) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: AnimatedOpacity(
          opacity: _privacyAgreed ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 300),
          child: SizedBox(
            width: double.infinity,
            child: _buildPrimaryButton(
              onPressed: _privacyAgreed ? _nextPage : () {},
              label: AppLocalizations.of(context)!.agreeAndStart,
            ),
          ),
        ),
      );
    }

    // 2. Intro Page Controls (Index 1) - Handled internally by Intro Page
    if (_currentPage == 1) {
      return const SizedBox.shrink();
    }

    // 3. Last Page Global Controls (Guardian - Index 7)
    if (_currentPage == 7) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI Consultant Button handled in Guardian Page specific UI if needed,
            // but here we provide the main flow button
            SizedBox(
              width: double.infinity,
              child: _buildPrimaryButton(
                onPressed: _completeOnboardingAndNavigate,
                label:
                    AppLocalizations.of(context)!.getStarted ?? 'Start Journey',
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _previousPage,
              child: Text(
                AppLocalizations.of(context)!.previous ?? 'Back',
                style: GoogleFonts.barlow(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 4. Standard Controls (Basic Info, Photo, Body, Goals, Exercise - Index 2-6)
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: _buildPrimaryButton(
              onPressed: _onNextPressed,
              label: AppLocalizations.of(context)!.next ?? 'Next',
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _previousPage,
            child: Text(
              AppLocalizations.of(context)!.previous ?? 'Back',
              style: GoogleFonts.barlow(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E35B1).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: const LinearGradient(
          colors: [Color(0xFF5E35B1), Color(0xFF9575CD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.barlow(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    FocusScope.of(context).unfocus();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onNextPressed() {
    _nextPage();
  }

  Future<void> _finishOnboarding({required bool startAI}) async {
    setState(() {
      _pendingAIStart = startAI;
      _showDisclaimer = true;
    });
  }

  Widget _buildDisclaimerOverlay() {
    return Stack(
      children: [
        // Backdrop Filter
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Color(0xFF5E35B1),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.disclaimerTitle,
                  style: GoogleFonts.barlow(
                    color: const Color(0xFF1A237E),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.disclaimerMessage,
                  style: GoogleFonts.barlow(
                    color: Colors.black54,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: _buildPrimaryButton(
                    onPressed: () {
                      setState(() => _showDisclaimer = false);
                      _completeOnboardingAndNavigate();
                    },
                    label: AppLocalizations.of(context)!.agreeAndStart,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _completeOnboardingAndNavigate() async {
    // Parse Age
    int age = 30; // Default
    try {
      if (_selectedAgeRange.contains('-')) {
        age = int.parse(_selectedAgeRange.split('-')[0]);
      } else if (_selectedAgeRange.contains('~')) {
        age = int.parse(_selectedAgeRange.split('~')[0]);
      } else {
        age = int.parse(_selectedAgeRange.replaceAll(RegExp(r'[^0-9]'), ''));
      }
    } catch (_) {}

    final goalsString = _selectedGoals.isNotEmpty
        ? _selectedGoals.join(', ')
        : 'None';
    final injuriesString = _selectedInjuries.isNotEmpty
        ? _selectedInjuries.join(', ')
        : 'None';

    // Construct UserProfile
    final userProfile = UserProfile(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      nickname: _nicknameController.text.isNotEmpty
          ? _nicknameController.text
          : 'Gemini User',
      age: age + 2,
      gender: _selectedGender,
      height: _height,
      weight: _weight,
      profilePhotoPath: _profilePhoto?.path,
      fitnessLevel: _experienceLevel,
      targetExercise: _exerciseController.text.isNotEmpty
          ? _exerciseController.text
          : 'Full Body Workout',
      healthConditions: injuriesString,
      goal: goalsString,
      userTier: 'free',
      guardianPhone:
          _completeGuardianPhone, // Ensure this variable exists or remove if unused
      fallDetectionEnabled: _fallDetectionEnabled,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final updateUserProfile = getIt<UpdateUserProfileUseCase>();
      debugPrint('Onboarding: Saving profile for ${userProfile.nickname}...');
      final result = await updateUserProfile.execute(userProfile);

      result.fold(
        (failure) => debugPrint(
          'Onboarding: Failed to save profile: ${failure.message}',
        ),
        (savedProfile) => debugPrint(
          'Onboarding: Profile saved successfully: ${savedProfile.nickname}',
        ),
      );
    } catch (e) {
      debugPrint('Onboarding: Error saving profile: $e');
    }

    debugPrint(
      'Onboarding complete - Profile created: ${userProfile.nickname}',
    );

    if (!mounted) return;

    if (_pendingAIStart) {
      // Go to AI Interview
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AIInterviewView(userProfile: userProfile),
        ),
      );
    } else {
      // Go to Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const home.HomeView()),
      );
    }
  }

  // --- Bottom Sheet for Age Picker ---
  void _showAgePickerBottomSheet() {
    int initialIndex = _ageRanges.indexOf(_selectedAgeRange);
    if (initialIndex == -1) initialIndex = 2; // Default 25~29

    String tempSelection = _selectedAgeRange;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 350,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.selectAgeRange,
                        style: GoogleFonts.barlow(
                          color: const Color(0xFF1A237E),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _selectedAgeRange = tempSelection);
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.check,
                          color: Color(0xFF5E35B1),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Wheel Picker
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: FixedExtentScrollController(
                        initialItem: initialIndex,
                      ),
                      itemExtent: 50,
                      diameterRatio: 1.5,
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
                              style: GoogleFonts.barlow(
                                color: isSelected
                                    ? const Color(0xFF5E35B1)
                                    : Colors.black26,
                                fontSize: isSelected ? 24 : 18,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
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

  // --- API Key Dialog ---
  Future<void> _showApiKeyDialog() async {
    final getApiKeyUseCase = getIt<GetApiKeyUseCase>();
    final setApiKeyUseCase = getIt<SetApiKeyUseCase>();

    final result = await getApiKeyUseCase.execute();
    String currentKey = '';
    result.fold((l) => null, (r) => currentKey = r);
    final controller = TextEditingController(text: currentKey);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Gemini API Key",
          style: GoogleFonts.barlow(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A237E),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Enter your Gemini API Key to enable AI features.",
              style: GoogleFonts.barlow(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: GoogleFonts.barlow(color: Colors.black87),
              decoration: InputDecoration(
                labelText: "API Key",
                labelStyle: TextStyle(color: Colors.black45),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color(0xFF5E35B1)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.barlow(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await setApiKeyUseCase.execute(controller.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E35B1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text("Save", style: GoogleFonts.barlow()),
          ),
        ],
      ),
    );
  }
}
