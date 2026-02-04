import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../domain/entities/user_profile.dart';
import '../../presentation/controllers/baseline_assessment_controller.dart';
import '../../l10n/app_localizations.dart';
import '../home_view.dart';
import '../widgets/ai_pose_camera_preview.dart';

class BaselineAssessmentView extends StatefulWidget {
  final UserProfile userProfile;

  const BaselineAssessmentView({super.key, required this.userProfile});

  @override
  State<BaselineAssessmentView> createState() => _BaselineAssessmentViewState();
}

class _BaselineAssessmentViewState extends State<BaselineAssessmentView> {
  late final BaselineAssessmentController _controller;

  // Constants
  static const int _kRecordingDuration = 10;
  static const double _kMetricValueFontSize = 48.0;
  static const double _kMetricLabelFontSize = 12.0;

  @override
  void initState() {
    super.initState();
    _controller = BaselineAssessmentController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.initialize(
          widget.userProfile,
          AppLocalizations.of(context)!,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final controller = _controller;
          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Camera Feed (Back layer)
              _buildCameraFeed(controller),

              // 2. Glass Overlay for Instructions / Feedback
              _buildOverlay(context, controller),

              // 3. Header
              _buildHeader(context),

              // 4. Phase-Specific Overlays
              if (controller.phase == AssessmentPhase.analyzing)
                _buildAnalyzingOverlay(context),

              if (controller.phase == AssessmentPhase.completed)
                _buildCompletedOverlay(context, controller),

              if (controller.phase == AssessmentPhase.error)
                _buildErrorOverlay(context, controller),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCameraFeed(BaselineAssessmentController controller) {
    return AIPoseCameraPreview(cameraManager: controller.cameraManager);
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.baselineTitle,
                style: GoogleFonts.barlowCondensed(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(
    BuildContext context,
    BaselineAssessmentController controller,
  ) {
    if (controller.phase == AssessmentPhase.instructions) {
      return _buildInstructionSlide(context, controller);
    }

    if (controller.phase == AssessmentPhase.ready) {
      return _buildReadyPoseGuidance(context, controller);
    }

    if (controller.phase == AssessmentPhase.countdown) {
      return _buildCountdown(controller);
    }

    if (controller.phase == AssessmentPhase.recording) {
      return _buildRecordingUI(context, controller);
    }

    return const SizedBox.shrink();
  }

  Widget _buildInstructionSlide(
    BuildContext context,
    BaselineAssessmentController controller,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.accessibility_new,
                        color: Colors.amber,
                        size: 64,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.baselineMovementBenchmark,
                        style: GoogleFonts.barlow(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.baselineInstructions,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: controller.startReadyPhase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(l10n.baselineImReady),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyPoseGuidance(
    BuildContext context,
    BaselineAssessmentController controller,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!controller.isFullBodyVisible) ...[
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.baselineFullBodyNotVisible,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              l10n.baselineMoveBack,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ] else ...[
            CircularProgressIndicator(
              value: (controller.holdSeconds / 5).clamp(0.0, 1.0),
              color: Colors.cyanAccent,
              strokeWidth: 8,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.baselineHoldingPosition,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountdown(BaselineAssessmentController controller) {
    return Center(
      child: Text(
        "${controller.countdownSeconds}",
        style: GoogleFonts.barlowCondensed(
          color: Colors.amber,
          fontSize: 180,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildRecordingUI(
    BuildContext context,
    BaselineAssessmentController controller,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final remainingSeconds = _kRecordingDuration - controller.recordingSeconds;

    return Positioned(
      bottom: 64,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: Colors.white, size: 12),
                const SizedBox(width: 8),
                Text(
                  "${l10n.baselineRecording} ${remainingSeconds}s",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.baselinePerformSquats,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingOverlay(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.deepPurpleAccent),
            const SizedBox(height: 24),
            Text(
              l10n.baselineAnalyzing,
              style: GoogleFonts.barlowCondensed(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.baselineExtractingMarkers,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedOverlay(
    BuildContext context,
    BaselineAssessmentController controller,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final result = controller.analysisResult;
    final stability = (result?['stability_score'] as num?)?.toDouble() ?? 0.0;
    final mobility = (result?['mobility_score'] as num?)?.toDouble() ?? 0.0;
    final summary = result?['summary'] as String? ?? '';

    return Container(
      color: Colors.black,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.greenAccent,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.baselineSuccess,
                style: GoogleFonts.barlow(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMetric(l10n.baselineStability, stability),
                  _buildMetric(l10n.baselineMobility, mobility),
                ],
              ),
              const SizedBox(height: 32),
              if (summary.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    summary,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeView()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(l10n.baselineContinue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, double value) {
    return Column(
      children: [
        Text(
          "${(value * 100).toInt()}",
          style: GoogleFonts.barlowCondensed(
            color: Colors.cyanAccent,
            fontSize: _kMetricValueFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: _kMetricLabelFontSize,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorOverlay(
    BuildContext context,
    BaselineAssessmentController controller,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 80),
            const SizedBox(height: 24),
            Text(
              l10n.baselineErrorTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage ?? l10n.unknownError,
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: controller.retry,
              child: Text(l10n.baselineTryAgainLater),
            ),
          ],
        ),
      ),
    );
  }
}
