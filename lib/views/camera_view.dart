import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/di/injection.dart';
import '../domain/entities/workout_curriculum.dart';
import '../domain/entities/user_profile.dart';
import '../domain/services/coaching_manager.dart';

import '../presentation/controllers/workout_session_controller.dart';
import '../presentation/states/workout_session_state.dart';
import '../services/camera_manager.dart'; // Restored import
import 'widgets/ai_pose_camera_preview.dart';
import '../widgets/coaching_overlay.dart'; // Restored import

import '../services/fall_detection_service.dart';
import '../services/emergency_flow_manager.dart';
import 'widgets/emergency_flow_overlay.dart';
import '../widgets/glass_dialog.dart';
import 'result_dashboard_view.dart';

class CameraView extends StatefulWidget {
  final WorkoutCurriculum? curriculum;
  final UserProfile? userProfile;

  const CameraView({super.key, this.curriculum, this.userProfile});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  late final WorkoutSessionController _controller;
  late final CameraManager _cameraManager;
  final CoachingManager _coachingManager = getIt<CoachingManager>();
  late final FallDetectionService _fallDetectionService;
  late final EmergencyFlowManager _emergencyFlowManager;
  StreamSubscription? _poseSubscription;

  // Guide Video
  VideoPlayerController? _guideVideoController;
  final String _dummyGuideVideoUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';

  bool _isVideoFullscreen = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _cameraManager = CameraManager();
    _controller = WorkoutSessionController();

    // Listen to phase changes to control video player
    _controller.addListener(_onControllerChanged);

    // Initialize Fall Detection Service
    _fallDetectionService = FallDetectionService();
    _fallDetectionService.onFallSuspected = _onFallSuspected;

    // Initialize Emergency Flow Manager
    _emergencyFlowManager = EmergencyFlowManager();

    _initialize();
  }

  void _onControllerChanged() {
    final state = _controller.state;
    if (_guideVideoController == null ||
        !_guideVideoController!.value.isInitialized) {
      return;
    }

    if (state.isPaused ||
        state.isResting ||
        state.isCompleted ||
        state.isWaitingForReadyPose ||
        state.isTestMode) {
      if (_guideVideoController!.value.isPlaying) {
        _guideVideoController!.pause();
      }
    } else if (state.isWorking) {
      if (!_guideVideoController!.value.isPlaying) {
        _guideVideoController!.play();
      }

      // Start/Resume Fall Monitoring when working
      if (widget.userProfile?.fallDetectionEnabled == true &&
          !_fallDetectionService.isMonitoring) {
        _fallDetectionService.startMonitoring();
      }
    } else {
      // Stop monitoring in other phases (Rest, Ready, etc)
      if (_fallDetectionService.isMonitoring) {
        _fallDetectionService.stopMonitoring();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.userProfile != null) {
      _emergencyFlowManager.initialize(
        userProfile: widget.userProfile!,
        cameraManager: _cameraManager,
        l10n: AppLocalizations.of(context),
      );
    }
  }

  Future<void> _initialize() async {
    await [Permission.camera, Permission.microphone].request();

    // 1. Initialize Camera
    await _cameraManager.initialize();

    // 2. Initialize Controller
    if (widget.curriculum != null) {
      await _controller.initialize(
        widget.curriculum!,
        widget.userProfile,
        _cameraManager,
      );
    } else {
      await _controller.initializeTestMode(_cameraManager);
    }

    // 3. Start Pose Stream & Wire to Controller
    _poseSubscription = _cameraManager.poseStream.listen((poses) {
      if (poses.isNotEmpty) {
        final pose = poses.first;
        _controller.processPose(pose);

        // Pass to Fall Detection Service (only if user has enabled it in settings)
        // For now, always check, service handles 'isMonitoring' state
        if (widget.userProfile?.fallDetectionEnabled == true) {
          // We need screen height for drop ratio calculation
          final screenHeight =
              _cameraManager.controller?.value.previewSize?.height ?? 1000;
          // We need current exercise name to exclude lying exercises
          final exerciseName = _controller.state.currentTask?.title ?? '';

          _fallDetectionService.processPose(pose, screenHeight, exerciseName);
        }
      }
    });

    _cameraManager.startPoseDetection();

    _cameraManager.startPoseDetection();

    // 4. Initialize Video
    _initializeGuideVideo();

    if (mounted) setState(() {});
  }

  void _initializeGuideVideo() {
    if (_controller.state.isTestMode) return;

    final videoUrl =
        _controller.state.currentTask?.exampleVideoUrl.isNotEmpty == true
        ? _controller.state.currentTask!.exampleVideoUrl
        : _dummyGuideVideoUrl;

    if (videoUrl.startsWith('assets/')) {
      _guideVideoController = VideoPlayerController.asset(videoUrl);
    } else {
      _guideVideoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );
    }

    _guideVideoController!.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _guideVideoController!.setLooping(true);
        // Only play if in a phase that requires guide and NOT in test mode
        if (!_controller.state.isWaitingForReadyPose &&
            !_controller.state.isTestMode) {
          _guideVideoController!.play();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poseSubscription?.cancel();
    _controller.removeListener(_onControllerChanged);
    _cameraManager.dispose();
    _fallDetectionService.stopMonitoring();
    _emergencyFlowManager.dispose();
    _controller.dispose();
    _guideVideoController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.pause();
      _guideVideoController?.pause();
    } else if (state == AppLifecycleState.resumed) {
      // Logic for resume if needed
    }
  }

  // --- Fall Detection Handling ---
  void _onFallSuspected() {
    debugPrint("Fall Suspected! Entering Amber Mode...");
    _controller.pause();
    _fallDetectionService.stopMonitoring();

    // Trigger Amber mode via EmergencyFlowManager
    _emergencyFlowManager.startAmber();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final state = _controller.state;

        if (!_cameraManager.isInitialized) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Main Background Content
              Positioned.fill(child: _buildMainContent(state)),

              // 2. PIP Content
              if (!state.isTestMode)
                Positioned(
                  right: 16,
                  bottom: 40,
                  child: _buildPIPContent(state),
                ),

              // 3. Ready Pose Overlay (Waiting for user)
              if (state.isWaitingForReadyPose ||
                  state.phase == SessionPhase.countdown)
                _buildReadyPoseOverlay(state),

              // 4. Header
              _buildHeader(state),

              // 5. Timer (Bottom Left)
              if (!state.isWaitingForReadyPose &&
                  !state.isCompleted &&
                  !state.isTestMode)
                Positioned(
                  bottom: 40,
                  left: 16,
                  child: _buildCircularTimer(state),
                ),

              // 6. Rest Overlay
              if (state.isResting) _buildRestOverlay(state),

              // 7. Pause Overlay
              if (state.isPaused) _buildPauseOverlay(),

              // 8. Completed Overlay
              if (state.isCompleted) _buildCompletionDialog(),

              // 9. Coaching Overlay
              if (!state.isTestMode)
                CoachingOverlay(messageStream: _coachingManager.messageStream),

              // 10. Emergency Flow Overlay (Amber/Red)
              EmergencyFlowOverlay(manager: _emergencyFlowManager),
            ],
          ),
        );
      },
    );
  }

  // --- Sub-Widgets (extracted from logic) ---

  Widget _buildMainContent(WorkoutSessionState state) {
    if (state.isTestMode) {
      return _buildCameraWithSkeleton();
    }
    if (_isVideoFullscreen) {
      return _buildGuideVideoPlayer(fit: BoxFit.contain);
    } else {
      return _buildCameraWithSkeleton();
    }
  }

  Widget _buildPIPContent(WorkoutSessionState state) {
    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.black54,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _isVideoFullscreen
                ? _buildCameraWithSkeleton(isPIP: true)
                : _buildGuideVideoPlayer(fit: BoxFit.cover),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () =>
                  setState(() => _isVideoFullscreen = !_isVideoFullscreen),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.swap_calls,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraWithSkeleton({bool isPIP = false}) {
    return AIPoseCameraPreview(cameraManager: _cameraManager);
  }

  Widget _buildGuideVideoPlayer({BoxFit fit = BoxFit.contain}) {
    if (_guideVideoController == null ||
        !_guideVideoController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: fit,
        child: SizedBox(
          width: _guideVideoController!.value.size.width,
          height: _guideVideoController!.value.size.height,
          child: VideoPlayer(_guideVideoController!),
        ),
      ),
    );
  }

  Widget _buildReadyPoseOverlay(WorkoutSessionState state) {
    return Container(
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (state.currentTask?.readyPoseImageUrl.isNotEmpty == true)
            Positioned.fill(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: state.currentTask!.readyPoseImageUrl.startsWith('http')
                      ? Image.network(
                          state.currentTask!.readyPoseImageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox(),
                        )
                      : Image.asset(
                          state.currentTask!.readyPoseImageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox(),
                        ),
                ),
              ),
            ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.phase == SessionPhase.countdown) ...[
                  Text(
                    '${state.countdownSeconds}',
                    style: GoogleFonts.barlowCondensed(
                      color: const Color(0xFFFEE715),
                      fontSize: 160,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    "Get Ready!",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ] else if (!state.isFullBodyVisible) ...[
                  const Icon(
                    Icons.accessibility_new,
                    size: 80,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Stand back to show\nyour full body',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  CircularProgressIndicator(
                    value: (state.readyPoseHoldSeconds / 5).clamp(0.0, 1.0),
                    strokeWidth: 8,
                    color: const Color(0xFF00B0E0),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${5 - state.readyPoseHoldSeconds}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text("Hold Position", style: TextStyle(fontSize: 24)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularTimer(WorkoutSessionState state) {
    final progress = state.timerProgress;
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(
                progress > 0.8 ? Colors.red : Colors.deepPurple,
              ),
            ),
          ),
          Text(
            '${state.timeoutSeconds - state.elapsedSeconds}',
            style: GoogleFonts.barlowCondensed(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: _isVideoFullscreen ? Colors.black87 : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(WorkoutSessionState state) {
    final isDark = _isVideoFullscreen || state.isWaitingForReadyPose;
    final color = isDark ? Colors.black87 : Colors.white;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: color),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    state.isTestMode
                        ? 'Camera Test'
                        : (state.currentTask?.title ?? ''),
                    style: GoogleFonts.barlowCondensed(
                      color: color,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!state.isTestMode)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${state.currentRep} / ${state.currentTask?.adjustedReps}',
                          style: GoogleFonts.barlowCondensed(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'SET ${state.currentSet}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestOverlay(WorkoutSessionState state) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer, size: 60, color: Colors.deepPurple),
            const Text(
              "Resting...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Next set in ${state.timeoutSeconds - state.elapsedSeconds}s",
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_circle, size: 80, color: Colors.white),
            const Text(
              "Paused",
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _controller.resume(),
              child: const Text("Resume"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionDialog() {
    // Aggregate session data for Storyteller
    final state = _controller.state;
    final exerciseName = state.currentTask?.title ?? 'Workout';
    final totalReps = state.currentRep; // Total reps completed

    // Calculate session stability (average form score as percentage)
    // Using a default of 75 if no analysis available
    final sessionStability = 75; // TODO: Get from actual session analysis

    return Container(
      color: Colors.black54,
      child: GlassDialog(
        title: 'Workout Complete! 🎉',
        content: 'View your performance insights',
        icon: Hero(
          tag: 'workout_complete',
          child: const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
        ),
        actions: [
          GlassButton(
            text: 'View Results',
            isPrimary: true,
            onPressed: () {
              // Navigate to ResultDashboardView with session data
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      ResultDashboardView(
                        userProfile: widget.userProfile,
                        exerciseName: exerciseName,
                        sessionStability: sessionStability,
                        totalReps: totalReps,
                        primaryFault: null, // TODO: Get from session analysis
                      ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
          ),
          GlassButton(
            text: 'Home',
            isPrimary: false,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
