import '../widgets/ai_consultant_button.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_profile.dart';
import 'home_view.dart';
import 'ai_interview_view.dart';
import '../services/gemini_service.dart';
import 'package:flutter/services.dart';

/// OnboardingView - 온보딩 화면
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form Controllers
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

  // 나이 범위 목록
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

  // 부상 이력 목록
  // 부상 이력 목록 (Getter for Localization)
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

  // 운동 목표 목록
  // 운동 목표 목록 (Getter for Localization)
  List<String> get _goalOptions => [
    AppLocalizations.of(context)!.strengthBuilding,
    AppLocalizations.of(context)!.weightLoss,
    AppLocalizations.of(context)!.endurance,
    AppLocalizations.of(context)!.flexibility,
    AppLocalizations.of(context)!.postureCorrection,
    AppLocalizations.of(context)!.rehabilitation,
    AppLocalizations.of(context)!.other,
  ];

  // 면책 팝업 표시 여부
  bool _showDisclaimer = false;

  // 기능 설정
  bool _fallDetectionEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 진행 표시기
                _buildProgressIndicator(),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    children: [
                      _buildPermissionsPage(),
                      _buildProfilePage(),
                      _buildExercisePage(),
                      _buildGuardianPage(),
                    ],
                  ),
                ),
                _buildBottomControls(),
              ],
            ),

            // 면책 팝업
            if (_showDisclaimer) _buildDisclaimerOverlay(),
          ],
        ),
      ),
    );
  }

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

  bool _isCameraGranted = false;
  bool _isMicGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final camera = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    if (mounted) {
      setState(() {
        _isCameraGranted = camera.isGranted;
        _isMicGranted = mic.isGranted;
      });
    }
  }

  Widget _buildPermissionsPage() {
    final isAllGranted = _isCameraGranted && _isMicGranted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(
            isAllGranted ? Icons.check_circle_outline : Icons.security,
            size: 80,
            color: isAllGranted ? Colors.greenAccent : Colors.deepPurple,
          ),
          const SizedBox(height: 24),
          Text(
            isAllGranted
                ? AppLocalizations.of(context)!.permissionGrantedTitle
                : AppLocalizations.of(context)!.permissionTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isAllGranted
                ? AppLocalizations.of(context)!.permissionGrantedMessage
                : AppLocalizations.of(context)!.permissionMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const Spacer(),
          // 메인 버튼 - 전체 너비
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isAllGranted
                  ? _nextPage
                  : () async {
                      // 권한 요청
                      final statuses = await [
                        Permission.camera,
                        Permission.microphone,
                      ].request();

                      debugPrint('Permission statuses: $statuses');

                      await _checkPermissions();

                      if (_isCameraGranted && _isMicGranted) {
                        _nextPage();
                      } else {
                        // 권한이 영구 거부된 경우 설정으로 이동
                        final cameraPermanentlyDenied =
                            await Permission.camera.isPermanentlyDenied;
                        final micPermanentlyDenied =
                            await Permission.microphone.isPermanentlyDenied;

                        if ((cameraPermanentlyDenied || micPermanentlyDenied) &&
                            mounted) {
                          debugPrint('Showing settings dialog...');
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: const Text(
                                '권한 필요',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                '카메라와 마이크 권한이 거부되었습니다.\n설정에서 직접 권한을 허용해주세요.',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    AppLocalizations.of(context)!.cancel,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    openAppSettings();
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.openSettings,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
              icon: Icon(isAllGranted ? Icons.arrow_forward : Icons.check),
              label: Text(
                isAllGranted
                    ? AppLocalizations.of(context)!.next
                    : AppLocalizations.of(context)!.grantPermission,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAllGranted
                    ? Colors.green
                    : Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          if (!isAllGranted) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _nextPage,
                child: Text(
                  AppLocalizations.of(context)!.skip,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
            ),
          ],

          const Spacer(),

          TextButton.icon(
            onPressed: _showApiKeyDialog,
            icon: const Icon(Icons.key, size: 16, color: Colors.white30),
            label: Text(
              AppLocalizations.of(context)!.enterApiKeyHackathon,
              style: const TextStyle(color: Colors.white30, fontSize: 12),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
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
            onTap: () => _showAgePickerBottomSheet(),
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
                    _selectedAgeRange,
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
              final isSelected = _selectedInjuries.contains(injury);
              return FilterChip(
                label: Text(injury),
                selected: isSelected,
                selectedColor: Colors.deepPurple,
                backgroundColor: Colors.grey[800],
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (injury == AppLocalizations.of(context)!.none) {
                      // '없음' 선택 시 다른 모든 선택 해제
                      _selectedInjuries.clear();
                      if (selected) _selectedInjuries.add(injury);
                      _showCustomInjury = false;
                    } else {
                      // 다른 부상 선택 시 '없음' 해제
                      _selectedInjuries.remove(
                        AppLocalizations.of(context)!.none,
                      );
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
                },
              );
            }).toList(),
          ),
          if (_showCustomInjury) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customInjuryController,
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
              final isSelected = _selectedGoals.contains(goal);
              return FilterChip(
                label: Text(goal),
                selected: isSelected,
                selectedColor: Colors.deepPurple,
                backgroundColor: Colors.grey[800],
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                ),
                onSelected: (selected) {
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
                },
              );
            }).toList(),
          ),
          if (_showCustomGoal) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customGoalController,
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
              value: _experienceLevel,
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
              onChanged: (val) => setState(() => _experienceLevel = val!),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildExercisePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.targetExercise,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.selectExercise,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children:
                [
                  {
                    'name': AppLocalizations.of(context)!.exerciseSquat,
                    'value': 'Squat',
                  },
                  {
                    'name': AppLocalizations.of(context)!.exercisePushup,
                    'value': 'Push-up',
                  },
                  {
                    'name': AppLocalizations.of(context)!.exerciseLunge,
                    'value': 'Lunge',
                  },
                  {
                    'name': AppLocalizations.of(context)!.exercisePlank,
                    'value': 'Plank',
                  },
                ].map((exercise) {
                  final isSelected =
                      _exerciseController.text == exercise['value'];
                  return ChoiceChip(
                    label: Text(exercise['name']!),
                    selected: isSelected,
                    selectedColor: Colors.deepPurple,
                    backgroundColor: Colors.grey[800],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                    onSelected: (selected) {
                      setState(
                        () => _exerciseController.text = exercise['value']!,
                      );
                    },
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianPage() {
    return SingleChildScrollView(
      // 키보드 문제 방지
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emergency, size: 60, color: Colors.orange),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.safetySettings,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.safetyDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),

          // 낙상 감지 토글
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: SwitchListTile(
              title: Text(
                AppLocalizations.of(context)!.enableFallDetection,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.fallDetectionDescription,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              value: _fallDetectionEnabled,
              onChanged: (val) => setState(() => _fallDetectionEnabled = val),
              activeThumbColor: Colors.deepPurple,
            ),
          ),

          const SizedBox(height: 24),

          if (_fallDetectionEnabled) ...[
            _buildTextField(
              AppLocalizations.of(context)!.guardianPhone,
              _guardianController,
              TextInputType.phone,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.guardianPhoneDescription,
              style: const TextStyle(color: Colors.white30, fontSize: 12),
            ),
          ],

          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // 건너뛰기
              _guardianController.clear();
              setState(() => _fallDetectionEnabled = false);
              _onNextPressed();
            },
            child: Text(
              AppLocalizations.of(context)!.setUpLater,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, [
    TextInputType? type,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
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
    );
  }

  Widget _buildBottomControls() {
    if (_currentPage == 0) {
      return const SizedBox.shrink();
    }

    // Guardian Page (마지막 페이지)일 경우 AI Consultant 버튼 추가
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
              child: AIConsultantButton(onPressed: _startAIInterview),
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
          // 이전 버튼 (컴팩트)
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
          // 다음 버튼 (확장)
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
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onNextPressed() async {
    if (_currentPage < 3) {
      _nextPage();
    } else {
      // 마지막 페이지 - 면책 팝업 표시 후 완료
      setState(() => _showDisclaimer = true);

      // 3초 후 자동 사라짐
      Timer(const Duration(seconds: 3), () {
        if (mounted && _showDisclaimer) {
          setState(() {
            _showDisclaimer = false;
          });
          _onFinish();
        }
      });
    }
  }

  /// AI 인터뷰 시작
  Future<void> _startAIInterview() async {
    // 현재까지 입력된 프로필 생성
    final injuryText = _buildInjuryText();
    final goalText = _buildGoalText();

    final profile = UserProfile(
      age: _selectedAgeRange,
      injuryHistory: injuryText,
      goal: goalText,
      experienceLevel: _experienceLevel,
      targetExercise: _exerciseController.text.isEmpty
          ? "Squat"
          : _exerciseController.text,
      guardianPhone: _guardianController.text.isEmpty
          ? null
          : _guardianController.text,
      fallDetectionEnabled: _fallDetectionEnabled,
    );

    // AI 인터뷰 화면으로 이동
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AIInterviewView(userProfile: profile, isFromOnboarding: true),
      ),
    );

    // 인터뷰 완료 또는 스킵 시 홈으로 이동
    if (mounted) {
      // 프로필은 인터뷰 화면에서 이미 저장됨
      // 스킵한 경우에도 기본 프로필 저장
      if (result == false) {
        await UserProfile.save(profile);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeView()),
      );
    }
  }

  Widget _buildDisclaimerOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.orange.shade900,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, size: 60, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.disclaimer,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.disclaimerContent,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.autoRedirect,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAgePickerBottomSheet() {
    int initialIndex = _ageRanges.indexOf(_selectedAgeRange);
    if (initialIndex < 0) initialIndex = 2; // default to 25~29

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String tempSelection = _selectedAgeRange;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 헤더
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '나이대 선택',
                        style: TextStyle(
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
                                fontSize: isSelected ? 22 : 16,
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

  Future<void> _onFinish() async {
    final injuryText = _buildInjuryText();
    final goalText = _buildGoalText();

    final profile = UserProfile(
      age: _selectedAgeRange,
      injuryHistory: injuryText,
      goal: goalText,
      experienceLevel: _experienceLevel,
      targetExercise: _exerciseController.text.isEmpty
          ? "Squat"
          : _exerciseController.text,
      guardianPhone: _guardianController.text.isEmpty
          ? null
          : _guardianController.text,
      fallDetectionEnabled: _fallDetectionEnabled,
    );

    await UserProfile.save(profile);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeView()),
      );
    }
  }

  void _showApiKeyDialog() {
    final TextEditingController keyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          AppLocalizations.of(context)!.apiKeyDialogTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.apiKeyDialogDescription,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.apiKeyLabel,
                labelStyle: const TextStyle(color: Colors.white54),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurple),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (keyController.text.trim().isNotEmpty) {
                final geminiService = GeminiService();
                await geminiService.setApiKey(keyController.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.apiKeySaved),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  String _buildInjuryText() {
    if (_selectedInjuries.isEmpty || _selectedInjuries.contains('없음')) {
      return '없음';
    }
    final injuries = _selectedInjuries.where((i) => i != '기타').toList();
    if (_selectedInjuries.contains('기타') &&
        _customInjuryController.text.isNotEmpty) {
      injuries.add(_customInjuryController.text);
    }
    return injuries.join(', ');
  }

  String _buildGoalText() {
    if (_selectedGoals.isEmpty) return 'General Fitness';
    final goals = _selectedGoals.where((g) => g != '기타').toList();
    if (_selectedGoals.contains('기타') &&
        _customGoalController.text.isNotEmpty) {
      goals.add(_customGoalController.text);
    }
    return goals.join(', ');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _customInjuryController.dispose();
    _customGoalController.dispose();
    _exerciseController.dispose();
    _guardianController.dispose();
    super.dispose();
  }
}
