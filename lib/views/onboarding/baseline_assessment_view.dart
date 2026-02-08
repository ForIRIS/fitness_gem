import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import '../../core/di/injection.dart';
import '../../domain/entities/user_profile.dart';
import '../../presentation/controllers/baseline_assessment_controller.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/ai_pose_camera_preview.dart';

class BaselineAssessmentView extends StatefulWidget {
  final UserProfile userProfile;

  const BaselineAssessmentView({super.key, required this.userProfile});

  @override
  State<BaselineAssessmentView> createState() => _BaselineAssessmentViewState();
}

class _BaselineAssessmentViewState extends State<BaselineAssessmentView> {
  late final BaselineAssessmentController _controller;
  VideoPlayerController? _videoPlayerController;

  // Constants
  static const int _kRecordingDuration = 10;
  static const double _kMetricValueFontSize = 48.0;
  static const double _kMetricLabelFontSize = 12.0;
  static const String _kExampleVideoPath =
      'assets/videos/workouts/example_squat.mp4';

  @override
  void initState() {
    super.initState();
    _controller = getIt<BaselineAssessmentController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkCameraPermission();
      }
    });
  }

  Future<void> _checkCameraPermission() async {
    debugPrint('[BaselineView] Checking permissions...');
    try {
      // Check Camera
      final cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        final newStatus = await Permission.camera.request();
        if (!newStatus.isGranted) {
          debugPrint('[BaselineView] Camera permission denied.');
          if (!mounted) return;
          _showPermissionDialog();
          return;
        }
      }

      // Check Microphone for STT
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        final newMicStatus = await Permission.microphone.request();
        if (!newMicStatus.isGranted) {
          debugPrint('[BaselineView] Microphone permission denied.');
          if (!mounted) return;
          _showPermissionDialog(isMicrophone: true);
          return;
        }
      }

      // Initialize video player
      debugPrint('[BaselineView] Initializing video player...');
      _videoPlayerController = VideoPlayerController.asset(_kExampleVideoPath);
      await _videoPlayerController!.initialize();
      await _videoPlayerController!.setLooping(true);

      if (mounted) {
        debugPrint('[BaselineView] Video player ready. Playing.');
        await _videoPlayerController!.play();
        setState(() {}); // Rebuild to show video
      }

      // Proceed to initialize controller
      if (mounted) {
        debugPrint('[BaselineView] Initializing controller...');
        await _controller.initialize(
          widget.userProfile,
          AppLocalizations.of(context)!,
        );
      }
    } catch (e, stack) {
      debugPrint('[BaselineView] Error during initialization: $e');
      debugPrint('$stack');
      // Optionally show error dialog
    }
  }

  void _showPermissionDialog({bool isMicrophone = false}) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.permissionRequired),
        content: Text(
          isMicrophone
              ? 'Microphone access is required for voice commands.'
              : l10n.cameraPermissionReason,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
            },
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final controller = _controller;
          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Video Background (Main Layer)
              _buildVideoBackground(),

              // 2. PIP Camera (Small overlay)
              _buildPIPCamera(controller),

              // 3. Glass Overlay for Instructions / Feedback
              _buildOverlay(context, controller),

              // 4. Header
              _buildHeader(context),

              // 5. Phase-Specific Overlays
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

  Widget _buildVideoBackground() {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized) {
      return Container(
        color: Colors.white,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        child: VideoPlayer(_videoPlayerController!),
      ),
    );
  }

  Widget _buildPIPCamera(BaselineAssessmentController controller) {
    return Positioned(
      bottom: 30,
      right: 16,
      child: Container(
        width: 180,
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.deepPurple, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: AIPoseCameraPreview(
            cameraManager: controller.cameraManager,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
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
                icon: const Icon(Icons.close, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.baselineTitle,
                style: GoogleFonts.barlowCondensed(
                  color: Colors.black87,
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
              color: Colors.black.withValues(alpha: 0.6),
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
                          fontSize: 22,
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
    final isKorean = l10n.localeName == 'ko';
    final voiceCommand = isKorean ? '시작' : 'Start';
    final listeningText = isKorean
        ? '음성 명령을 듣고 있습니다...'
        : 'Listening for voice command...';

    return Positioned(
      bottom: 32,
      left: 16,
      right: 140, // Leave space for PIP camera
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic, color: Colors.cyanAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              '"$voiceCommand"',
              style: GoogleFonts.barlow(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              listeningText,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
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
                    Navigator.pop(context, true);
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 80,
              ),
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
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 40),
              // Primary action: Retry
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.retry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    l10n.baselineRetry,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Secondary action: Skip Assessment
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    l10n.baselineSkipAssessment,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
