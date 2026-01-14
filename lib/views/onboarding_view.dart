import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_profile.dart';
import 'home_view.dart';

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
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _injuryController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  String _experienceLevel = 'Beginner';
  final TextEditingController _exerciseController = TextEditingController();
  final TextEditingController _guardianController = TextEditingController();

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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAllGranted ? Icons.check_circle_outline : Icons.security,
            size: 80,
            color: isAllGranted ? Colors.greenAccent : Colors.deepPurple,
          ),
          const SizedBox(height: 24),
          Text(
            isAllGranted ? "권한 확인 완료" : "권한 요청",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isAllGranted
                ? "모든 권한이 허용되었습니다.\n다음 단계로 이동해주세요."
                : "자세 분석을 위해 카메라와 마이크 접근 권한이 필요합니다.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 48),
          if (!isAllGranted)
            ElevatedButton.icon(
              onPressed: () async {
                await [Permission.camera, Permission.microphone].request();
                await _checkPermissions();
                if (_isCameraGranted && _isMicGranted) {
                  _nextPage();
                }
              },
              icon: const Icon(Icons.check),
              label: const Text("권한 허용"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _nextPage,
              icon: const Icon(Icons.arrow_forward),
              label: const Text("다음"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          if (!isAllGranted) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: _nextPage,
              child: const Text(
                "건너뛰기 (기능 제한됨)",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
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
          const Text(
            "프로필 정보",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "맞춤 운동 추천을 위해 정보를 입력해주세요.",
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 24),

          _buildTextField("나이", _ageController, TextInputType.number),
          _buildTextField("부상 이력 (예: 오른쪽 무릎)", _injuryController),
          _buildTextField("운동 목표 (예: 근력 강화)", _goalController),

          const SizedBox(height: 16),
          const Text("운동 경험", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
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
                const DropdownMenuItem(
                  value: 'Beginner',
                  child: Text('입문 (1년 미만)'),
                ),
                const DropdownMenuItem(
                  value: 'Intermediate',
                  child: Text('중급 (1~3년)'),
                ),
                const DropdownMenuItem(
                  value: 'Advanced',
                  child: Text('고급 (3년 이상)'),
                ),
              ],
              onChanged: (val) => setState(() => _experienceLevel = val!),
            ),
          ),
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
          const Text(
            "타겟 운동",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "집중하고 싶은 운동 부위를 선택하세요.",
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children:
                [
                  {'name': '하체 (스쿼트)', 'value': 'Squat'},
                  {'name': '상체 (푸시업)', 'value': 'Push-up'},
                  {'name': '런지', 'value': 'Lunge'},
                  {'name': '코어 (플랭크)', 'value': 'Plank'},
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
          const Text(
            "안전 설정",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "낙상 감지 및 비상 연락처를 설정합니다.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
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
              title: const Text(
                '낙상 감지 기능 사용',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                '운동 중 넘어짐을 감지합니다.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              value: _fallDetectionEnabled,
              onChanged: (val) => setState(() => _fallDetectionEnabled = val),
              activeColor: Colors.deepPurple,
            ),
          ),

          const SizedBox(height: 24),

          if (_fallDetectionEnabled) ...[
            _buildTextField(
              "보호자 전화번호 (선택)",
              _guardianController,
              TextInputType.phone,
            ),
            const SizedBox(height: 8),
            const Text(
              "비상 시 SMS 알림을 보낼 번호입니다.",
              style: TextStyle(color: Colors.white30, fontSize: 12),
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
            child: const Text(
              "나중에 설정할게요",
              style: TextStyle(color: Colors.white54),
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

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _previousPage,
            child: const Text("이전", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: _onNextPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: Text(_currentPage == 3 ? "시작하기" : "다음"),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
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
              const Text(
                "⚠️ 의료 조언 면책",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "본 앱은 의료 조언을 제공하지 않습니다.\n"
                "운동 전 전문 의료진과 상담하세요.\n"
                "부상이나 통증 발생 시 즉시 운동을 중단하세요.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 24),
              const Text(
                "3초 후 자동으로 넘어갑니다...",
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onFinish() async {
    final profile = UserProfile(
      age: _ageController.text,
      injuryHistory: _injuryController.text,
      goal: _goalController.text,
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

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _injuryController.dispose();
    _goalController.dispose();
    _exerciseController.dispose();
    _guardianController.dispose();
    super.dispose();
  }
}
