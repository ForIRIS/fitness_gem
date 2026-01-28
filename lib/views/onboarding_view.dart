import '../widgets/ai_consultant_button.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import '../models/user_profile.dart';
import 'ai_interview_view.dart';
import '../services/gemini_service.dart';

// Sub-pages
import 'onboarding/onboarding_permissions_page.dart';
import 'onboarding/onboarding_profile_page.dart';
import 'onboarding/onboarding_exercise_page.dart';
import 'onboarding/onboarding_guardian_page.dart';
import 'home_view.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/fitness_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.black),
            ),
          ),
          // 2. Gradient Overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Content
          SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Progress indicator
                    _buildProgressIndicator(),

                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (page) =>
                            setState(() => _currentPage = page),
                        children: [
                          // 1. Permissions Page
                          OnboardingPermissionsPage(
                            onNext: _nextPage,
                            onShowApiKeyDialog: _showApiKeyDialog,
                          ),

                          // 2. Profile Page
                          OnboardingProfilePage(
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

                          // 3. Exercise Page
                          OnboardingExercisePage(
                            exerciseController: _exerciseController,
                          ),

                          // 4. Guardian Page
                          OnboardingGuardianPage(
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: index <= _currentPage
                    ? Colors.deepPurple
                    : Colors.grey[800],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomControls() {
    if (_currentPage == 0) {
      return const SizedBox.shrink();
    }

    // Add AI Consultant button if on Guardian Page (last page)
    if (_currentPage == 3) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _previousPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.previous,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onNextPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.start),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // AI Consultant 버튼
            SizedBox(
              width: double.infinity,
              child: AIConsultantButton(
                onPressed: () => _finishOnboarding(startAI: true),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.aiConsultantDescription,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // 다른 페이지들
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          // Previous button (Compact)
          ElevatedButton(
            onPressed: _previousPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            ),
            child: Text(
              AppLocalizations.of(context)!.previous,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          const SizedBox(width: 12),
          // Next button (Extended)
          Expanded(
            child: ElevatedButton(
              onPressed: _onNextPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(AppLocalizations.of(context)!.next),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    // 키보드 닫기
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
    // Start logic on last page (Skip AI)
    if (_currentPage == 3) {
      _finishOnboarding(startAI: false);
    } else {
      _nextPage();
    }
  }

  Future<void> _finishOnboarding({required bool startAI}) async {
    // Save logic is performed in _completeOnboardingAndNavigate
    // Show disclaimer popup and set path first
    setState(() {
      _pendingAIStart = startAI;
      _showDisclaimer = true;
    });
  }

  Widget _buildDisclaimerOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.disclaimerTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.disclaimerMessage,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() => _showDisclaimer = false);
                  _completeOnboardingAndNavigate();
                },
                child: Text(AppLocalizations.of(context)!.agreeAndStart),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeOnboardingAndNavigate() async {
    // Create & Save UserProfile
    final profile = UserProfile(
      nickname: _nicknameController.text.trim().isEmpty
          ? null
          : _nicknameController.text.trim(),
      age: _selectedAgeRange,
      injuryHistory: _showCustomInjury
          ? _customInjuryController.text
          : _selectedInjuries.join(', '),
      goal: _showCustomGoal
          ? _customGoalController.text
          : _selectedGoals.join(', '),
      experienceLevel: _experienceLevel,
      targetExercise: _exerciseController.text.isEmpty
          ? 'Squat'
          : _exerciseController.text, // Default value
      guardianPhone: _guardianController.text.isEmpty
          ? null
          : _completeGuardianPhone ?? _guardianController.text,
      fallDetectionEnabled: _fallDetectionEnabled,
    );

    await profile.save();

    if (!mounted) return;

    if (_pendingAIStart) {
      // Go to AI Interview
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AIInterviewView(userProfile: profile),
        ),
      );
    } else {
      // Go to Home
      Navigator.pushReplacementNamed(
        context,
        '/',
      ); // MainApp handles routes or just pop?
      // MainApp widget switches on 'showOnboarding' flag, but since we are replacing route,
      // it's safer to restart app or push HomeView directly.
      // Since 'home' is conditional, creating a fresh HomeView is fine.
      // Ideally, use a named route or pushReplacement.

      // Since OnboardingView is the 'home' of MaterialApp when showOnboarding is true,
      // replacing it with HomeView is correct.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeView()),
        (route) => false,
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
                  // Header
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
                  // Wheel Picker
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

  // --- API Key Dialog ---
  Future<void> _showApiKeyDialog() async {
    final geminiService = GeminiService();
    final currentKey = await geminiService.getUserApiKey();
    final controller = TextEditingController(text: currentKey);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.enterApiKeyHackathon),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "To prevent rate limits during the hackathon, you can input your own Google Gemini API Key.",
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "API Key",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await geminiService.setApiKey(controller.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
