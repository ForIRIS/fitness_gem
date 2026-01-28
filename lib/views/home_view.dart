import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../models/workout_curriculum.dart';
import '../models/user_profile.dart';
import '../models/session_analysis.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../services/cache_service.dart';
import 'camera_view.dart';
import 'ai_chat_view.dart';
import 'settings_view.dart';
import 'loading_view.dart';
import 'workout_detail_view.dart';
import '../widgets/shimmer_skeleton.dart';

/// HomeView - Dashboard Screen
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  WorkoutCurriculum? _todayCurriculum;
  UserProfile? _userProfile;
  List<SessionAnalysis> _sessionHistory = [];

  // Independent loading states
  bool _isProfileLoading = true;
  bool _isCurriculumLoading = false;

  bool _showDisclaimer = true;
  String? _generationError;

  Map<String, bool>? _taskCacheStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
    _showDisclaimerPopup();
  }

  Future<void> _loadData() async {
    try {
      // Load local data first
      _userProfile = await UserProfile.load();
      _todayCurriculum = await WorkoutCurriculum.load();
      _sessionHistory = await SessionAnalysis.loadAll();

      // Once local data is loaded, show the UI
      if (mounted) {
        setState(() {
          _isProfileLoading = false;
        });
      }

      // Check if we need to generate a new curriculum
      if (_todayCurriculum == null && _userProfile != null) {
        await _generateTodayCurriculum();
      } else if (_todayCurriculum != null) {
        // If loaded locally, just check cache status
        _updateCacheStatus();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isProfileLoading = false;
        });
      }
    }
  }

  Future<void> _generateTodayCurriculum() async {
    if (_userProfile == null) return;

    if (mounted) {
      setState(() {
        _isCurriculumLoading = true;
        _generationError = null;
      });
    }

    try {
      final firebaseService = FirebaseService();
      final geminiService = GeminiService();

      // Determine target category
      final category = _getCategoryFromTarget(_userProfile!.targetExercise);

      // Fetch workouts
      final workouts = await firebaseService.searchWorkoutParts(category);

      // Generate with timeout
      if (workouts.isEmpty) {
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
        _updateCacheStatus();
      }
    } catch (e) {
      debugPrint('Error generating curriculum: $e');
      if (mounted) {
        setState(() {
          try {
            _generationError = AppLocalizations.of(context)!.generationFailed;
          } catch (_) {
            _generationError = 'Failed to generate workout.';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isCurriculumLoading = false);
      }
    }
  }

  String _getCategoryFromTarget(String target) {
    final lower = target.toLowerCase();
    if (lower.contains('squat') || lower.contains('lower')) return 'squat';
    if (lower.contains('push') || lower.contains('upper')) return 'push';
    if (lower.contains('plank') || lower.contains('core')) return 'core';
    if (lower.contains('lunge') || lower.contains('lunge')) return 'lunge';
    return 'squat'; // Default
  }

  void _showDisclaimerPopup() {
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showDisclaimer = false);
      }
    });
  }

  void _startWorkout() async {
    if (_todayCurriculum == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.generatingWorkout),
        ),
      );
      return;
    }

    // Check cache
    final cacheService = CacheService();
    final isCached = await cacheService.areAllCurriculumResourcesCached(
      _todayCurriculum!,
    );

    if (isCached && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraView(curriculum: _todayCurriculum),
        ),
      );
      return;
    }

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingView(curriculum: _todayCurriculum!),
      ),
    );

    if (result == true && mounted) {
      _updateCacheStatus();
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
      _updateCacheStatus();
    }
  }

  Future<void> _updateCacheStatus() async {
    if (_todayCurriculum == null) return;

    final cacheService = CacheService();
    final newStatus = <String, bool>{};

    for (final task in _todayCurriculum!.workoutTaskList) {
      newStatus[task.id] = await cacheService.isTaskCached(task);
    }

    if (mounted) {
      setState(() => _taskCacheStatus = newStatus);
    }
  }

  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsView()),
    );
    // Reload local data when returning from settings
    _loadData();
  }

  void _downloadAllResources() async {
    if (_todayCurriculum == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingView(curriculum: _todayCurriculum!),
      ),
    );

    if (result == true && mounted) {
      _updateCacheStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.downloadComplete),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/fitness_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                );
              },
            ),
          ),
          // 2. Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Main Content
          SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _isProfileLoading
                          ? _buildSkeletonLoader()
                          : _buildMainContent(),
                    ),
                  ],
                ),

                if (_showDisclaimer) _buildDisclaimerPopup(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.appTitle,
                style: const TextStyle(
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
            _getWelcomeMessage(),
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Curriculum Card
          _buildCurriculumCard(),

          const SizedBox(height: 24),

          // Progress Card
          _buildProgressCard(),

          const Spacer(),

          // Buttons
          _buildBottomButtons(),
        ],
      ),
    );
  }

  String _getWelcomeMessage() {
    if (_userProfile == null) {
      return AppLocalizations.of(context)!.welcomeTrainee;
    }

    // Check if we have nickname
    if (_userProfile!.nickname != null && _userProfile!.nickname!.isNotEmpty) {
      // Use nickname format if user tier is present
      if (_userProfile!.userTier.isNotEmpty) {
        return AppLocalizations.of(
          context,
        )!.welcomeUserTier(_userProfile!.userTier, _userProfile!.nickname!);
      }
      return AppLocalizations.of(context)!.welcomeUser(_userProfile!.nickname!);
    }

    // Fallback to age/level format
    return AppLocalizations.of(context)!.welcomeMessage(
      _userProfile!.age.toString(),
      _userProfile!.experienceLevel,
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          image: const DecorationImage(
            image: AssetImage('assets/images/card_bg.png'),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade900.withValues(alpha: 0.95),
              Colors.grey.shade900.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.todayWorkout,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (_todayCurriculum != null &&
                    _taskCacheStatus != null &&
                    _taskCacheStatus!.containsValue(false))
                  IconButton(
                    onPressed: _downloadAllResources,
                    icon: const Icon(
                      Icons.download_for_offline,
                      color: Colors.white,
                    ),
                    tooltip: 'Download All',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(right: 8),
                  ),
                const Icon(
                  Icons.arrow_forward,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Content State
            if (_generationError != null)
              _buildErrorContent()
            else if (_isCurriculumLoading)
              const ShimmerSkeleton(
                width: double.infinity,
                height: 100, // Approximate text height
                borderRadius: 12,
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
              _buildEmptyCurriculumState(),

            const SizedBox(height: 8),

            // Subtitle / Details
            Text(
              _todayCurriculum != null
                  ? AppLocalizations.of(
                      context,
                    )!.estimatedTime(_todayCurriculum!.estimatedMinutes)
                  : (_isCurriculumLoading ? ' ' : '-'),
              style: const TextStyle(color: Colors.white60, fontSize: 16),
            ),

            if (_todayCurriculum != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _todayCurriculum!.workoutTaskList.map((task) {
                  final isCached = (_taskCacheStatus ?? {})[task.id] ?? false;
                  return Chip(
                    label: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCached ? Colors.black87 : Colors.white,
                        fontWeight: isCached
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    backgroundColor: isCached
                        ? Colors.white
                        : Colors.transparent,
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: Colors.white,
                        width: isCached ? 0 : 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    avatar: isCached
                        ? null
                        : const Icon(
                            Icons.download,
                            size: 14,
                            color: Colors.white70,
                          ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    bool isCached = false;
    if (_todayCurriculum != null && _taskCacheStatus != null) {
      isCached = !_taskCacheStatus!.containsValue(false);
    }

    // Smart Button Logic
    String buttonText = AppLocalizations.of(context)!.startWorkout;
    IconData buttonIcon = Icons.play_arrow;
    VoidCallback? onPressed = _startWorkout;

    if (_todayCurriculum == null) {
      if (_isCurriculumLoading) {
        buttonText = AppLocalizations.of(context)!.generatingWorkout;
        onPressed = null; // Disabled
        buttonIcon = Icons.hourglass_empty;
      } else {
        buttonText = AppLocalizations.of(context)!.createWorkout;
        buttonIcon = Icons.add_circle_outline;
        onPressed = _generateTodayCurriculum;
      }
    } else if (!isCached) {
      buttonText = AppLocalizations.of(context)!.downloadAndStart;
      buttonIcon = Icons.download;
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(buttonIcon),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Theme.of(
                context,
              ).primaryColor.withOpacity(0.5),
              disabledForegroundColor: Colors.white38,
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
            icon: const Icon(Icons.auto_awesome, size: 20),
            label: Text(AppLocalizations.of(context)!.aiChat),
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
    );
  }

  Widget _buildErrorContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.generationFailed.split('\n')[0],
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
          onPressed: _isCurriculumLoading ? null : _generateTodayCurriculum,
          icon: _isCurriculumLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh, size: 16),
          label: Text(
            _isCurriculumLoading
                ? AppLocalizations.of(context)!.generatingWorkout
                : AppLocalizations.of(context)!.retry,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent.withOpacity(0.2),
            foregroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCurriculumState() {
    return Center(
      child: Column(
        children: [
          const Text(
            'Create your daily workout',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _generateTodayCurriculum,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final recentSessions = _sessionHistory.take(7).toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.progress,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentSessions.isEmpty)
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.insights_rounded,
                      size: 32,
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.emptyProgressTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.noRecordMessage,
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
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
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Theme.of(context).primaryColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.2),
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
                child: Text(
                  AppLocalizations.of(context)!.medicalDisclaimerShort,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 16),
                onPressed: () => setState(() => _showDisclaimer = false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12), // Spacer to offset where Header was
          // Curriculum Card Skeleton
          const ShimmerSkeleton(
            width: double.infinity,
            height: 220,
            borderRadius: 24,
          ),

          const SizedBox(height: 24),

          // Progress Card Skeleton
          const ShimmerSkeleton(
            width: double.infinity,
            height: 180,
            borderRadius: 24,
          ),

          const Spacer(),

          // Buttons Skeleton
          Row(
            children: const [
              Expanded(
                flex: 2,
                child: ShimmerSkeleton(
                  width: double.infinity,
                  height: 56,
                  borderRadius: 12,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ShimmerSkeleton(
                  width: double.infinity,
                  height: 56,
                  borderRadius: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
