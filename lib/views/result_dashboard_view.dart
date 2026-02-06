import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';

import '../core/di/injection.dart';
import '../domain/entities/post_workout_summary.dart';
import '../domain/entities/user_profile.dart';
import '../domain/usecases/ai/generate_post_workout_summary_usecase.dart';
import '../services/tts_service.dart';

import 'widgets/smart_wait_widget.dart';
import 'widgets/insight_card.dart';
import 'widgets/comparison_bar_chart.dart';

/// ResultDashboardView - Post-workout summary with Storyteller insights
/// Shows loading, then transitions to results with TTS.
class ResultDashboardView extends StatefulWidget {
  final UserProfile? userProfile;
  final String exerciseName;
  final int sessionStability;
  final int totalReps;
  final String? primaryFault;

  const ResultDashboardView({
    super.key,
    required this.userProfile,
    required this.exerciseName,
    required this.sessionStability,
    required this.totalReps,
    this.primaryFault,
  });

  @override
  State<ResultDashboardView> createState() => _ResultDashboardViewState();
}

class _ResultDashboardViewState extends State<ResultDashboardView>
    with SingleTickerProviderStateMixin {
  PostWorkoutSummary? _summary;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TTSService _ttsService = getIt<TTSService>();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final useCase = getIt<GeneratePostWorkoutSummaryUseCase>();

    // Get baseline from user profile
    final initialStability = (widget.userProfile?.stabilityBaseline ?? 50)
        .toInt();
    final initialMobility = (widget.userProfile?.mobilityScore ?? 50).toInt();

    // Get language
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final userLanguage = locale.languageCode == 'ko' ? 'ko' : 'en';

    final result = await useCase.execute(
      userLanguage: userLanguage,
      exerciseName: widget.exerciseName,
      initialStability: initialStability,
      initialMobility: initialMobility,
      sessionStability: widget.sessionStability,
      totalReps: widget.totalReps,
      primaryFaultDetected: widget.primaryFault,
    );

    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = failure.message;
          });
        }
      },
      (summary) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _summary = summary;
          });
          _fadeController.forward();

          // Play TTS after transition
          if (summary != null) {
            Future.delayed(const Duration(milliseconds: 800), () {
              _ttsService.speak(summary.ttsScript);
            });
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? SmartWaitWidget(
              onComplete: () {
                // Loading will be managed by Gemini response
              },
            )
          : _hasError
          ? _buildErrorView()
          : _buildResultsView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber, color: Colors.amber, size: 64),
            const SizedBox(height: 16),
            Text(
              'Could not generate summary',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text('Return Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    final summary = _summary;
    if (summary == null) {
      return _buildFallbackView();
    }

    // Get baseline for display
    final baselineScore = (widget.userProfile?.stabilityBaseline ?? 50).toInt();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1a1a2e), Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Workout Complete',
                        style: GoogleFonts.barlowCondensed(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Insight Card (Hero Animation Target)
                  Hero(
                    tag: 'workout_complete',
                    child: InsightCard(
                      headline: summary.headlineCard,
                      bulletPoints: summary.insightBulletPoints,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Comparison Chart
                  ComparisonBarChart(
                    baselineScore: baselineScore,
                    currentScore: widget.sessionStability,
                    comparisonText: summary.visualizationMeta.comparisonText,
                    themeColor: summary.headlineCard.themeColor,
                  ),

                  const SizedBox(height: 32),

                  // Session Stats
                  _buildSessionStats(),

                  const SizedBox(height: 32),

                  // Return Home Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.returnHome,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
          const SizedBox(height: 16),
          Text(
            'Great Workout!',
            style: GoogleFonts.barlowCondensed(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: Text(AppLocalizations.of(context)!.returnHome),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            'Stability',
            '${widget.sessionStability}',
            Icons.balance,
          ),
          Container(height: 40, width: 1, color: Colors.grey.shade700),
          _buildStatColumn('Total Reps', '${widget.totalReps}', Icons.repeat),
          Container(height: 40, width: 1, color: Colors.grey.shade700),
          _buildStatColumn(
            'Exercise',
            widget.exerciseName.split(' ').first,
            Icons.fitness_center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurple.shade300, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.barlowCondensed(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12),
        ),
      ],
    );
  }
}
