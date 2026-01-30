import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import 'dart:async';
import '../models/workout_curriculum.dart';
import '../models/user_profile.dart';
import '../models/session_analysis.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../services/cache_service.dart';
import 'camera_view.dart';
import 'settings_view.dart';
import 'loading_view.dart';
import 'ai_chat_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

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
  bool _isCurriculumLoading = false;
  bool _isHistoryLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load local data first
      _userProfile = await UserProfile.load();
      _todayCurriculum = await WorkoutCurriculum.load();
      _loadHistory();

      // Check if we need to generate a new curriculum
      if (_todayCurriculum == null && _userProfile != null) {
        await _generateTodayCurriculum();
      } else if (_todayCurriculum != null) {
        // If loaded locally, just check cache status
        // _updateCacheStatus();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _isHistoryLoading = true);
    try {
      final history = await SessionAnalysis.loadAll();
      if (mounted) {
        setState(() {
          _sessionHistory = history;
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      if (mounted) {
        setState(() => _isHistoryLoading = false);
      }
    }
  }

  Future<void> _generateTodayCurriculum() async {
    if (_userProfile == null) return;

    if (mounted) {
      setState(() {
        _isCurriculumLoading = true;
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
      }
    } catch (e) {
      debugPrint('Error generating curriculum: $e');
      if (mounted) {}
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

  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsView()),
    );
    // Reload local data when returning from settings
    _loadData();
  }

  void _openAIChat() {
    if (_userProfile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIChatView(userProfile: _userProfile!),
        ),
      );
    }
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
      // Reload history when returning
      _loadHistory();
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
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraView(curriculum: _todayCurriculum),
        ),
      );
      // Reload history when returning
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF3E5F5,
      ), // Light purple/pink background from reference
      body: Stack(
        children: [
          // Background Gradient (Subtle)
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

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      12,
                      24,
                      100,
                    ), // Bottom padding for floating nav
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildDailyStats(),
                        const SizedBox(height: 24),
                        _buildCategoryChips(),
                        const SizedBox(height: 32),
                        _buildFeaturedProgramCard(),
                        const SizedBox(height: 32),
                        _buildCurriculumList(),
                        const SizedBox(height: 32),
                        _buildRecentActivity(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Bottom Navigation
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: _buildFloatingBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final name = _userProfile?.nickname ?? 'Trainee';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello $name',
              style: GoogleFonts.barlow(
                color: Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ready to Workout',
              style: GoogleFonts.barlowCondensed(
                color: const Color(0xFF1A237E), // Dark Blue
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Colors.black87,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyStats() {
    // Determine displayed stats
    final minutes = _todayCurriculum?.estimatedMinutes ?? 20;
    final focus =
        _todayCurriculum?.workoutTaskList.firstOrNull?.categoryDisplayName ??
        'Upper Body';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$minutes',
              style: GoogleFonts.barlow(
                color: const Color(0xFF1A237E),
                fontSize: 64,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Min $focus',
                  style: GoogleFonts.barlow(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Activities',
                  style: GoogleFonts.barlow(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
        const Icon(Icons.tune, color: Colors.black54, size: 28),
      ],
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['Upper Body', 'Build Strength', 'Beginner'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              category,
              style: GoogleFonts.barlow(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeaturedProgramCard() {
    final hasWorkout = _todayCurriculum != null;
    final title = hasWorkout ? _todayCurriculum!.summaryText : 'Pick A Program';
    final subtitle = hasWorkout
        ? 'Ready to verify'
        : 'Fully Customisable Program';
    final isLoading = _isCurriculumLoading;

    return GestureDetector(
      onTap: hasWorkout ? _startWorkout : _generateTodayCurriculum,
      child: Container(
        height: 380,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF64B5F6), // Light Blue
              Color(0xFF9575CD), // Purple
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9575CD).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Image Placeholder (if any)
            Positioned(
              right: -40,
              bottom: 0,
              child: Opacity(
                opacity: 0.9,
                child: Image.asset(
                  'assets/images/fitness_bg.png', // Fallback or a person image
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) => const SizedBox(),
                ),
              ),
            ),

            // Glass Overlay Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.black.withOpacity(0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.barlow(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: GoogleFonts.barlow(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Dots
                      Row(
                        children: List.generate(5, (index) {
                          return Container(
                            margin: const EdgeInsets.only(left: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: index == 4 ? Colors.white : Colors.white38,
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),

                  const Spacer(),

                  if (hasWorkout) ...[
                    // Members faces (Fake for now)
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          height: 32,
                          child: Stack(
                            children: [
                              _buildFace(0, Colors.orange),
                              _buildFace(20, Colors.blue),
                              _buildFace(40, Colors.red),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '5.8k+\nMembers',
                          style: GoogleFonts.barlow(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          isLoading
                              ? 'Generating...'
                              : (hasWorkout
                                    ? 'Get Set, Stay\nIgnite, Finish Proud.\nJoin The Flow.'
                                    : 'Create Your\nPerfect Routine\nToday.'),
                          style: GoogleFonts.barlow(
                            color: Colors.white,
                            fontSize: 28,
                            height: 1.1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Explicit Start Action
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: hasWorkout
                          ? _startWorkout
                          : _generateTodayCurriculum,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF5E35B1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              hasWorkout ? 'START SESSION' : 'GENERATE WORKOUT',
                              style: GoogleFonts.barlow(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurriculumList() {
    if (_todayCurriculum == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workout Plan',
          style: GoogleFonts.barlowCondensed(
            color: const Color(0xFF1A237E),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: _todayCurriculum!.workoutTaskList.map((task) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Color(0xFF1565C0),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: GoogleFonts.barlow(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${task.adjustedReps} Reps',
                          style: GoogleFonts.barlow(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_outline, color: Colors.black12),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    if (_isHistoryLoading && _sessionHistory.isEmpty)
      return const SizedBox.shrink();
    if (_sessionHistory.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.barlowCondensed(
            color: const Color(0xFF1A237E),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _sessionHistory.map((session) {
              final date = DateFormat.MMMd().format(session.date);
              final exerciseCount = session.taskAnalyses.length;
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: GoogleFonts.barlow(
                        color: Colors.black45,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${session.totalScore} Pts',
                      style: GoogleFonts.barlow(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$exerciseCount Activities',
                      style: GoogleFonts.barlow(
                        color: const Color(0xFF5E35B1),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFace(double left, Color color) {
    return Positioned(
      left: left,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.person, size: 20, color: Colors.white70),
      ),
    );
  }

  Widget _buildFloatingBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E), // Dark Navy
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavIcon(
            Icons.auto_awesome,
            'Generator',
            false,
            onTap: _generateTodayCurriculum,
          ),
          _buildNavPill('Programs'),
          _buildNavIcon(
            Icons.chat_bubble_outline,
            'AI Coach',
            false,
            onTap: _openAIChat,
          ),
          _buildNavIcon(
            Icons.person_outline,
            'Profile',
            false,
            onTap: _openSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildNavPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF5E35B1), // Deep Purple
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const Icon(Icons.layers, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.barlow(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(
    IconData icon,
    String label,
    bool isActive, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 22),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.barlow(
                color: Colors.white30,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
