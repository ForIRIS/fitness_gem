import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../models/workout_curriculum.dart';
import '../models/user_profile.dart';
import '../models/session_analysis.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import 'camera_view.dart';
import 'ai_chat_view.dart';
import 'settings_view.dart';
import 'loading_view.dart';
import '../widgets/animated_loading_text.dart';
import 'workout_detail_view.dart';

/// HomeView - 홈 화면
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  WorkoutCurriculum? _todayCurriculum;
  UserProfile? _userProfile;
  List<SessionAnalysis> _sessionHistory = [];
  bool _isLoading = true;
  bool _showDisclaimer = true;

  String? _generationError;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _showDisclaimerPopup();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _generationError = null;
    });

    try {
      // 사용자 프로필 로드
      _userProfile = await UserProfile.load();

      // 오늘의 커리큘럼 로드 (없으면 생성)
      _todayCurriculum = await WorkoutCurriculum.load();

      // 세션 히스토리 로드
      _sessionHistory = await SessionAnalysis.loadAll();

      if (_todayCurriculum == null && _userProfile != null) {
        await _generateTodayCurriculum();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generateTodayCurriculum() async {
    if (_userProfile == null) return;

    if (mounted) {
      setState(() {
        _isGenerating = true;
        _generationError = null;
      });
    }

    try {
      final firebaseService = FirebaseService();
      final geminiService = GeminiService();

      // 사용자의 타겟 운동 카테고리 결정
      final category = _getCategoryFromTarget(_userProfile!.targetExercise);

      // 해당 카테고리 운동 목록 가져오기
      final workouts = await firebaseService.searchWorkoutParts(category);

      // 타임아웃 30초 설정
      if (workouts.isEmpty) {
        // 전체 운동 목록 가져오기
        final allWorkouts = await firebaseService.fetchWorkoutAllList();
        _todayCurriculum = await geminiService
            .generateCurriculum(
              profile: _userProfile!,
              category: category,
              availableWorkouts: allWorkouts,
            )
            .timeout(const Duration(seconds: 30));
      } else {
        _todayCurriculum = await geminiService
            .generateCurriculum(
              profile: _userProfile!,
              category: category,
              availableWorkouts: workouts,
            )
            .timeout(const Duration(seconds: 30));
      }

      if (_todayCurriculum != null) {
        await WorkoutCurriculum.save(_todayCurriculum!);
      }
    } catch (e) {
      debugPrint('Error generating curriculum: $e');
      if (mounted) {
        setState(() {
          _generationError = '운동 생성에 실패했습니다.\n다시 시도해주세요. (${e.toString()})';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  String _getCategoryFromTarget(String target) {
    final lower = target.toLowerCase();
    if (lower.contains('squat') || lower.contains('하체')) return 'squat';
    if (lower.contains('push') || lower.contains('상체')) return 'push';
    if (lower.contains('plank') || lower.contains('코어')) return 'core';
    if (lower.contains('lunge') || lower.contains('런지')) return 'lunge';
    return 'squat'; // 기본값
  }

  void _showDisclaimerPopup() {
    // 3초 후 자동 사라짐
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showDisclaimer = false);
      }
    });
  }

  void _startWorkout() async {
    if (_todayCurriculum == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('커리큘럼을 생성 중입니다. 잠시 후 다시 시도해주세요.')),
      );
      return;
    }

    // 리소스 캐싱 화면으로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingView(curriculum: _todayCurriculum!),
      ),
    );

    // 캐싱 완료 시 운동 화면으로 이동
    if (result == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraView(curriculum: _todayCurriculum),
        ),
      );
    }
  }

  void _openAIChat() async {
    final newCurriculum = await Navigator.push<WorkoutCurriculum>(
      context,
      MaterialPageRoute(
        builder: (context) => AIChatView(userProfile: _userProfile!),
      ),
    );

    if (newCurriculum != null) {
      setState(() {
        _todayCurriculum = newCurriculum;
      });
      await WorkoutCurriculum.save(newCurriculum);
    }
  }

  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsView()),
    );
    // 설정에서 돌아오면 데이터 다시 로드
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 메인 콘텐츠
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMainContent(),

            // 면책 팝업
            if (_showDisclaimer) _buildDisclaimerPopup(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fitness Gem',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70),
                onPressed: _openSettings,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '안녕하세요, ${_userProfile?.age ?? ''}세 ${_userProfile?.experienceLevel ?? ''} 회원님!',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),

          const SizedBox(height: 32),

          // 오늘의 커리큘럼 카드
          _buildCurriculumCard(),

          const SizedBox(height: 24),

          // 진척도 그래프 (플레이스홀더)
          _buildProgressCard(),

          const Spacer(),

          // 버튼들
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _startWorkout,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('운동 시작'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openAIChat,
                  icon: const Icon(Icons.chat),
                  label: const Text('AI 상담'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumCard() {
    return GestureDetector(
      onTap: () {
        if (_todayCurriculum != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  WorkoutDetailView(curriculum: _todayCurriculum!),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.fitness_center,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '오늘의 운동',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white38,
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_generationError != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '생성 실패',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _generationError!,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateTodayCurriculum,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh, size: 16),
                    label: Text(_isGenerating ? '생성 중...' : '다시 시도'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.2),
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              )
            else if (_todayCurriculum != null)
              Text(
                _todayCurriculum!.summaryText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              AnimatedLoadingText(
                baseText: 'Generating workout',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              _todayCurriculum != null
                  ? '약 ${_todayCurriculum!.estimatedMinutes}분'
                  : '-',
              style: const TextStyle(color: Colors.white60, fontSize: 16),
            ),
            if (_todayCurriculum != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _todayCurriculum!.workoutTaskList
                    .map(
                      (task) => Chip(
                        label: Text(
                          task.title,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.white24,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    // 최근 7개 세션 데이터
    final recentSessions = _sessionHistory.take(7).toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text(
                '진척도',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentSessions.isEmpty)
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '운동 기록이 쌓이면 그래프가 표시됩니다',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < recentSessions.length) {
                            final date = recentSessions[index].date;
                            return Text(
                              '${date.month}/${date.day}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 22,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (recentSessions.length - 1).toDouble(),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: recentSessions.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.totalScore.toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.deepPurple,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.deepPurple,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.deepPurple.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerPopup() {
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: AnimatedOpacity(
        opacity: _showDisclaimer ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade900,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: const Text(
                  '본 앱은 의료 조언을 제공하지 않습니다.\n부상 시 즉시 운동을 중단하세요.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
