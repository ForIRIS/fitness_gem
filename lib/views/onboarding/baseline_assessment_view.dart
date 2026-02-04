import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../domain/entities/user_profile.dart';
import '../../presentation/controllers/baseline_assessment_controller.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = BaselineAssessmentController();
    _controller.initialize(widget.userProfile);
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
              _buildOverlay(controller),

              // 3. Header
              _buildHeader(context),

              // 4. Phase-Specific Overlays
              if (controller.phase == AssessmentPhase.analyzing)
                _buildAnalyzingOverlay(),

              if (controller.phase == AssessmentPhase.completed)
                _buildCompletedOverlay(controller),

              if (controller.phase == AssessmentPhase.error)
                _buildErrorOverlay(controller),
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
                'PHYSICAL BASELINE',
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

  Widget _buildOverlay(BaselineAssessmentController controller) {
    if (controller.phase == AssessmentPhase.instructions) {
      return _buildInstructionSlide(controller);
    }

    if (controller.phase == AssessmentPhase.ready) {
      return _buildReadyPoseGuidance(controller);
    }

    if (controller.phase == AssessmentPhase.countdown) {
      return _buildCountdown(controller);
    }

    if (controller.phase == AssessmentPhase.recording) {
      return _buildRecordingUI(controller);
    }

    return const SizedBox.shrink();
  }

  Widget _buildInstructionSlide(BaselineAssessmentController controller) {
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
                        "Movement Benchmark",
                        style: GoogleFonts.barlow(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "To personalize your experience, please perform 3 air squats. \n\nEnsure your head and feet are visible in the frame.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
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
                        child: const Text("I'M READY"),
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

  Widget _buildReadyPoseGuidance(BaselineAssessmentController controller) {
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
            const Text(
              "Full Body Not Visible",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Please move back until your feet are visible.",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ] else ...[
            CircularProgressIndicator(
              value: (controller.holdSeconds / 5).clamp(0.0, 1.0),
              color: Colors.cyanAccent,
              strokeWidth: 8,
            ),
            const SizedBox(height: 24),
            const Text(
              "Holding Position...",
              style: TextStyle(
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

  Widget _buildRecordingUI(BaselineAssessmentController controller) {
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
                  "RECORDING... ${10 - controller.recordingSeconds}s",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Perform 3 Air Squats now",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.deepPurpleAccent),
            const SizedBox(height: 24),
            Text(
              "GEMINI ANALYZING...",
              style: GoogleFonts.barlowCondensed(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Extracting mobility and stability markers",
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedOverlay(BaselineAssessmentController controller) {
    final result = controller.analysisResult;
    final stability = (result?['stability_score'] as num?)?.toDouble() ?? 0.0;
    final mobility = (result?['mobility_score'] as num?)?.toDouble() ?? 0.0;
    final summary = result?['summary'] as String? ?? 'Assessment complete.';

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
                "Assessment Success",
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
                  _buildMetric("STABILITY", stability),
                  _buildMetric("MOBILITY", mobility),
                ],
              ),
              const SizedBox(height: 32),
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
                  child: const Text("CONTINUE TO WORKOUT"),
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
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildErrorOverlay(BaselineAssessmentController controller) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 80),
            const SizedBox(height: 24),
            const Text(
              "Something went wrong",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage ?? "An unknown error occurred",
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("TRY AGAIN LATER"),
            ),
          ],
        ),
      ),
    );
  }
}
