import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/camera_utils.dart';
import '../utils/pose_painter.dart';
import '../utils/one_euro_filter.dart';
import '../utils/rep_counter.dart';
// import '../utils/pose_similarity.dart'; // Unused
import '../utils/form_rule_checker.dart';
import '../services/tts_service.dart';
import '../services/video_recorder.dart';
// import '../services/fall_detection_service.dart'; // Unused
import '../core/di/injection.dart';
import '../domain/usecases/ai/analyze_video_session_usecase.dart';
import '../domain/usecases/workout/get_exercise_config_usecase.dart';
import '../domain/entities/workout_curriculum.dart';
import '../domain/entities/workout_task.dart';
import '../domain/entities/exercise_config.dart';
import '../domain/entities/user_profile.dart';
import '../domain/usecases/workout/save_curriculum.dart';

import '../services/workout_model_service.dart';
import '../viewmodels/display_viewmodel.dart';
import '../widgets/coaching_overlay.dart';
import '../domain/services/coaching_manager.dart';
import '../widgets/glass_dialog.dart';
import 'package:google_fonts/google_fonts.dart';

/// CameraView - Workout Screen (Camera + Skeleton Overlay + UI)
class CameraView extends StatefulWidget {
  final WorkoutCurriculum? curriculum;
  final UserProfile? userProfile;

  const CameraView({super.key, this.curriculum, this.userProfile});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  // Camera Related
  CameraController? _controller;
  VideoPlayerController? _guideVideoController;
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(),
  );

  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  List<Pose> _poses = [];
  CameraDescription? _camera;

  // One Euro Filter
  final Map<PoseLandmarkType, OneEuroFilterSimple> _xFilters = {};
  final Map<PoseLandmarkType, OneEuroFilterSimple> _yFilters = {};

  // Workout State
  WorkoutCurriculum? _curriculum;
  WorkoutTask? _currentTask;
  int _currentRep = 0;
  int _currentSet = 1;
  bool _isResting = false;
  bool _isPaused = false;

  // Timer
  Timer? _workoutTimer;
  int _elapsedSeconds = 0;
  int _timeoutSeconds = 60;

  // Services
  final TTSService _ttsService = TTSService();
  final AnalyzeVideoSessionUseCase _analyzeVideoSession =
      getIt<AnalyzeVideoSessionUseCase>();
  final VideoRecorder _videoRecorder = VideoRecorder();

  // Rep Counting
  RepCounter? _repCounter;
  ExerciseConfig? _exerciseConfig;
  final GetExerciseConfigUseCase _getExerciseConfigUseCase =
      getIt<GetExerciseConfigUseCase>();

  // User Profile
  UserProfile? _userProfile;

  // Analysis Results

  // Recording State
  bool _isRecording = false;

  // Fall Detection - Removed unused

  // Ready Pose Detection - Removed unused

  // Body Visibility and Countdown
  bool _isFullBodyVisible = false;
  bool _isWaitingForReadyPose = true;
  int _countdownSeconds = 0;
  Timer? _countdownTimer;

  // PIP State
  bool _isVideoFullscreen = true; // Default: Video Fullscreen, Camera PIP

  // Real-time Form Feedback
  final FormRuleChecker _formRuleChecker = FormRuleChecker();

  // Guide Video
  final String _dummyGuideVideoUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';

  // 서비스
  late final CoachingManager _coachingManager = getIt<CoachingManager>();
  late final DisplayViewModel _displayViewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize External Display ViewModel
    _displayViewModel = DisplayViewModel();
    _displayViewModel.addListener(() {
      if (mounted) setState(() {});
    });

    _curriculum = widget.curriculum;
    _initializeServices();
    _initializeWorkout();
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _poseDetector.close();
    _videoRecorder.dispose();
    _displayViewModel.dispose();
    _workoutTimer?.cancel();
    _countdownTimer?.cancel();
    _guideVideoController?.dispose();
    _ttsService.dispose();
    _coachingManager.dispose();
    super.dispose();
  }

  Future<void> _initializeWorkout() async {
    // Load curriculum data
    if (_curriculum != null) {
      if (_curriculum!.workoutTasks.isNotEmpty) {
        // Resume from saved progress
        _currentTask = _curriculum!.currentTask ?? _curriculum!.workoutTasks[0];
        _currentSet = _curriculum!.currentSetIndex + 1;

        _timeoutSeconds = _currentTask?.timeoutSec ?? 60;
        await _loadExerciseConfig();

        // Set Real-time Form Feedback
        _formRuleChecker.setExercise(_currentTask?.title ?? 'squat');
      }
    }
  }

  Future<void> _loadExerciseConfig() async {
    if (_currentTask == null) return;
    final result = await _getExerciseConfigUseCase.execute(
      GetExerciseConfigParams(task: _currentTask!),
    );

    result.fold(
      (failure) {
        debugPrint('Failed to load exercise config: ${failure.message}');
      },
      (config) {
        if (mounted) {
          setState(() {
            _exerciseConfig = config;
            _repCounter = RepCounter(
              _exerciseConfig!,
              coachingManager: _coachingManager,
              onRepCountChanged: (newCount) {
                if (mounted) {
                  setState(() {
                    _currentRep = newCount;
                    if (_currentRep >= (_currentTask?.adjustedReps ?? 10)) {
                      _onSetComplete();
                    }
                  });
                }
              },
            );
          });

          // Load native model
          _loadNativeModel();
        }
      },
    );
  }

  Future<void> _loadNativeModel() async {
    final modelService = WorkoutModelService();
    final modelLoaded = await modelService.loadSampleModel();
    if (modelLoaded) {
      debugPrint('Successfully loaded sample model for platform');
    } else {
      debugPrint('Failed to load sample model');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause when going to background
    if (state == AppLifecycleState.paused) {
      _pauseWorkout();
    } else if (state == AppLifecycleState.resumed) {
      if (_isPaused) {
        _showResumeDialog();
      }
    }
  }

  void _pauseWorkout() {
    setState(() => _isPaused = true);
    _workoutTimer?.cancel();
    _controller?.stopImageStream();
  }

  void _resumeWorkout() {
    setState(() => _isPaused = false);
    _startWorkoutTimer();
    _startDisplayStream();
  }

  void _showResumeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GlassDialog(
        title: 'Paused',
        content: 'Workout is paused. Would you like to continue?',
        icon: const Icon(
          Icons.pause_circle_outline,
          color: Colors.white,
          size: 48,
        ),
        actions: [
          GlassButton(
            text: 'Quit',
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Exit workout screen
            },
          ),
          GlassButton(
            text: 'Continue',
            isPrimary: true,
            onPressed: () {
              Navigator.pop(context);
              _resumeWorkout();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _initialize() async {
    await [Permission.camera, Permission.microphone].request();

    final cameras = await availableCameras();

    if (cameras.isNotEmpty) {
      _camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        _camera!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      _startDisplayStream();
    } else {
      debugPrint("No cameras found. Running in Simulator Mode.");
    }

    // Initialize Guide Video
    final videoUrl = _currentTask?.exampleVideoUrl.isNotEmpty == true
        ? _currentTask!.exampleVideoUrl
        : _dummyGuideVideoUrl;

    _guideVideoController =
        VideoPlayerController.networkUrl(Uri.parse(videoUrl))
          ..initialize().then((_) {
            setState(() {});
            _guideVideoController!.setLooping(true);
            // Don't auto-play here, wait for workout start
            // _guideVideoController!.play();
          });

    // Initialize TTS
    await _ttsService.initialize();

    // First Set Guide Audio
    if (_currentTask != null) {
      await _ttsService.speakWorkoutStart(_currentTask!.title);
    }

    // Start in Ready Pose Waiting Mode (Timer/Recording starts after countdown)
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
        _isWaitingForReadyPose = true;
      });
    }
  }

  Future<void> _initializeServices() async {
    // Services init

    // User Profile is passed in constructor
    if (widget.userProfile != null) {
      _userProfile = widget.userProfile;
    }
  }

  Future<void> _startRecording() async {
    if (_controller == null || _isRecording) return;

    final success = await _videoRecorder.startRecording(_controller!);
    if (success) {
      _isRecording = true;
    }
  }

  Future<void> _stopRecordingAndAnalyze() async {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (!_isRecording) return;

    final result = await _videoRecorder.stopRecording();
    _isRecording = false;

    if (result != null && _userProfile != null && _currentTask != null) {
      // Request Gemini Analysis
      await _ttsService.speakAnalyzing();

      final analysisResultEither = await _analyzeVideoSession.execute(
        AnalyzeVideoSessionParams(
          rgbVideoFile: result.rgbFile,
          controlNetVideoFile: result.controlNetFile ?? result.rgbFile,
          profile: _userProfile!,
          exerciseName: _currentTask!.title,
          setNumber: _currentSet,
          totalSets: _currentTask!.adjustedSets,
          language: languageCode,
        ),
      );

      analysisResultEither.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Analysis Failed: ${failure.toString()}')),
          );
        },
        (analysisResult) {
          if (analysisResult != null) {
            // Speak Feedback
            final feedbackText = analysisResult['feedback']?['tts_message'];
            if (feedbackText != null) {
              _ttsService.speak(feedbackText);
            }
          }
        },
      );
    }
  }

  void _startWorkoutTimer() {
    _workoutTimer?.cancel();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && !_isResting) {
        setState(() {
          _elapsedSeconds++;
          if (_elapsedSeconds >= _timeoutSeconds) {
            // Timeout - Set Complete
            _onSetComplete();
          }
        });
      }
    });
  }

  void _startDisplayStream() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _controller!.startImageStream((CameraImage image) {
      if (_isDetecting || _isPaused) return;
      _isDetecting = true;

      _processImage(image).then((_) {
        if (mounted) _isDetecting = false;
      });
    });
  }

  Future<void> _processImage(CameraImage image) async {
    final inputImage = CameraUtils.inputImageFromCameraImage(
      image,
      _controller!,
      _camera!,
    );
    if (inputImage == null) return;

    try {
      final poses = await _poseDetector.processImage(inputImage);
      final smoothedPoses = _filterPoses(poses);

      if (mounted) {
        setState(() {
          _poses = smoothedPoses;
        });
      }

      // Body Visibility Check and Countdown Logic
      if (smoothedPoses.isNotEmpty) {
        final pose = smoothedPoses.first;
        final bodyVisible = _checkBodyVisibility(pose);

        if (mounted) {
          setState(() => _isFullBodyVisible = bodyVisible);
        }

        // When waiting for ready pose
        if (_isWaitingForReadyPose) {
          if (bodyVisible) {
            // Start Countdown if body is visible
            if (_countdownSeconds == 0 && _countdownTimer == null) {
              _startCountdown();
            }
          } else {
            // Cancel Countdown and Warn if body is not visible
            _cancelCountdown();
            _speakBodyNotVisibleThrottled();
          }
          return; // Skip logic below while waiting for ready pose
        }

        // Warn if body is not visible during workout
        if (!bodyVisible && !_isResting) {
          _speakBodyNotVisibleThrottled();
        }

        _videoRecorder.updatePose(pose); // For ControlNet Frame

        // Rep Counting
        if (_repCounter != null && !_isResting) {
          _repCounter!.processFrame(pose);
        }

        // Real-time Form Feedback
        if (!_isResting) {
          final formFeedback = _formRuleChecker.checkForm(pose);
          if (formFeedback != null) {
            _ttsService.speakFormCorrection(formFeedback);
            // Deliver feedback via CoachingManager
            await _coachingManager.deliver(formFeedback);
          }

          // Send Data to External Display
          _displayViewModel.updateSessionData(
            exerciseName: _currentTask?.title ?? 'Ready',
            reps: _currentRep,
            feedback: formFeedback ?? 'Good Form!',
            isGoodPose: formFeedback == null,
          );
        }
      } else {
        // Pose Not Detected
        if (mounted) {
          setState(() => _isFullBodyVisible = false);
        }
        if (_isWaitingForReadyPose) {
          _cancelCountdown();
          _speakBodyNotVisibleThrottled();
        }
      }
    } catch (e) {
      debugPrint('Error detecting pose: $e');
    }
  }

  List<Pose> _filterPoses(List<Pose> rawPoses) {
    if (rawPoses.isEmpty) return [];

    final pose = rawPoses.first;
    final Map<PoseLandmarkType, PoseLandmark> smoothedLandmarks = {};
    final double timestamp = DateTime.now().millisecondsSinceEpoch / 1000.0;

    pose.landmarks.forEach((type, landmark) {
      _xFilters.putIfAbsent(
        type,
        () => OneEuroFilterSimple(minCutoff: 1.0, beta: 0.007),
      );
      _yFilters.putIfAbsent(
        type,
        () => OneEuroFilterSimple(minCutoff: 1.0, beta: 0.007),
      );

      final double smoothedX = _xFilters[type]!.process(timestamp, landmark.x);
      final double smoothedY = _yFilters[type]!.process(timestamp, landmark.y);

      smoothedLandmarks[type] = PoseLandmark(
        type: type,
        x: smoothedX,
        y: smoothedY,
        z: landmark.z,
        likelihood: landmark.likelihood,
      );
    });

    return [Pose(landmarks: smoothedLandmarks)];
  }

  /// Body Visibility Check - Check if key landmarks are sufficiently detected
  bool _checkBodyVisibility(Pose pose) {
    final requiredLandmarks = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];

    int visibleCount = 0;
    const double minLikelihood = 0.5;

    for (final type in requiredLandmarks) {
      final landmark = pose.landmarks[type];
      if (landmark != null && landmark.likelihood >= minLikelihood) {
        visibleCount++;
      }
    }

    // OK if 6 or more out of 8 are visible
    return visibleCount >= 6;
  }

  /// Start Countdown (3 seconds)
  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdownSeconds = 3);

    _ttsService.speakReady();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _countdownSeconds--;
      });

      if (_countdownSeconds > 0) {
        _ttsService.speakCountdown(_countdownSeconds);
      } else {
        // Countdown Complete - Workout Start!
        timer.cancel();
        _countdownTimer = null;
        _ttsService.speakCountdown(0); // "Start!"
        _onCountdownComplete();
      }
    });
  }

  /// Cancel Countdown
  void _cancelCountdown() {
    if (_countdownTimer != null) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
      if (mounted) {
        setState(() => _countdownSeconds = 0);
      }
    }
  }

  /// TTS Warning (Throttled via CoachingManager)
  void _speakBodyNotVisibleThrottled() {
    _coachingManager.deliver('Show your full body');
  }

  /// Start Workout after Countdown Complete
  Future<void> _onCountdownComplete() async {
    setState(() {
      _isWaitingForReadyPose = false;
    });

    // Start Recording
    if (_controller != null) {
      await _startRecording();
    }

    // Start Video Playback
    if (_guideVideoController != null &&
        _guideVideoController!.value.isInitialized) {
      _guideVideoController!.play();
    }

    // Start Timer
    _startWorkoutTimer();
  }

  void _onSetComplete() async {
    if (_isResting) return;

    setState(() => _isResting = true);
    _workoutTimer?.cancel();

    // Stop Recording and Request Analysis
    await _stopRecordingAndAnalyze();

    // Rest Guide
    await _ttsService.speakRestStart(10);

    // Prepare Next Set/Example
    _curriculum = _curriculum?.moveToNextSet();

    // Save progress to local storage
    if (_curriculum != null) {
      final saveCurriculum = getIt<SaveCurriculumUseCase>();
      await saveCurriculum.execute(_curriculum!);
    }

    _currentSet = (_curriculum?.currentSetIndex ?? 0) + 1;
    final previousTaskId = _currentTask?.id;
    _currentTask = _curriculum?.currentTask;

    if (_currentTask == null || _curriculum?.isCompleted == true) {
      // All Workouts Complete
      await _ttsService.speakWorkoutComplete();
      _showCompletionDialog();
      return;
    }

    // Reload config if task changed
    if (_currentTask?.id != previousTaskId) {
      _loadExerciseConfig();
      _repCounter?.reset();
    }

    // Next Set after Rest
    _currentRep = 0;
    _elapsedSeconds = 0;
    _timeoutSeconds = _currentTask?.timeoutSec ?? 60;
    _repCounter?.reset();

    // Rest Time (Guide Pose Prep after 10s)
    await Future.delayed(const Duration(seconds: 10));

    if (mounted) {
      await _ttsService.speakReadyPose();
      setState(() => _isResting = false);

      // Start Next Set Recording
      await _startRecording();
      _startWorkoutTimer();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GlassDialog(
        title: 'Workout Complete! 🎉',
        content: 'You have completed today\'s workout. Great job!',
        icon: const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
        actions: [
          GlassButton(
            text: 'Home',
            isPrimary: true,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _togglePIPMode() {
    setState(() => _isVideoFullscreen = !_isVideoFullscreen);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/fitness_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.black),
              ),
            ),
            const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Main Background Content
          Positioned.fill(child: _buildMainContent()),

          // 2. PIP Content (Bottom Right)
          Positioned(right: 16, bottom: 40, child: _buildPIPContent()),

          // 7. Ready Pose Waiting Overlay
          if (_isWaitingForReadyPose) _buildReadyPoseOverlay(),

          // 8. Header Overlay (Back, Title, Stats)
          _buildHeader(),

          // 6. Bottom UI - Timer (Left)
          if (!_isWaitingForReadyPose)
            Positioned(bottom: 40, left: 16, child: _buildCircularTimer()),

          // 8. Rest Overlay
          if (_isResting) _buildRestOverlay(),

          // 9. Pause Overlay
          if (_isPaused) _buildPauseOverlay(),

          // 10. Coaching Overlay (New CMS-based)
          CoachingOverlay(messageStream: _coachingManager.messageStream),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isVideoFullscreen) {
      return _buildGuideVideoPlayer(fit: BoxFit.contain);
    } else {
      return _buildCameraWithSkeleton();
    }
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // Top Row: Back Button & Exercise Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildGlassButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Text(
                        _currentTask?.title ?? '',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.barlowCondensed(
                          color: Colors.white,
                          fontSize: 32, // Increased size for impact
                          fontWeight: FontWeight.w800,
                          shadows: [
                            const Shadow(blurRadius: 4, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Secondary Row: Next Exercise & Rep Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildNextExerciseCard(), _buildCurrentTaskInfo()],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(icon, color: Colors.white),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTaskInfo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$_currentRep',
                    style: GoogleFonts.barlowCondensed(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    ' / ${_currentTask?.adjustedReps ?? '-'}',
                    style: GoogleFonts.barlow(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'SET $_currentSet / ${_currentTask?.adjustedSets ?? '-'}',
                style: GoogleFonts.barlow(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPIPContent() {
    return Container(
      width: 120, // 조금 더 키움
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

          // Toggle Button with larger touch target
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: _togglePIPMode,
              behavior: HitTestBehavior.opaque, // Catch all taps
              child: Container(
                padding: const EdgeInsets.all(
                  12,
                ), // Increased padding for touch target
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    border: Border.all(color: Colors.white30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.swap_calls,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraWithSkeleton({bool isPIP = false}) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: Text(
          "Camera unavailable",
          style: TextStyle(color: Colors.white, fontSize: 10),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera Preview
        FittedBox(
          fit: isPIP ? BoxFit.cover : BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.previewSize!.height,
            height: _controller!.value.previewSize!.width,
            child: CameraPreview(_controller!),
          ),
        ),

        // Skeleton Overlay
        if (_poses.isNotEmpty)
          Transform.scale(
            scaleX: -1,
            alignment: Alignment.center,
            child: CustomPaint(
              painter: PosePainter(
                _poses,
                _controller!.value.previewSize!,
                Platform.isAndroid
                    ? InputImageRotation.rotation270deg
                    : InputImageRotation.rotation90deg,
                _camera?.lensDirection ?? CameraLensDirection.front,
              ),
            ),
          ),
      ],
    );
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

  Widget _buildNextExerciseCard() {
    final nextTask = _curriculum?.nextTask;
    final isLast = _curriculum?.isLastTask ?? true;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.skip_next_rounded,
                      color: Colors.white54,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'UP NEXT',
                      style: GoogleFonts.barlow(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    isLast ? 'Last Exercise' : (nextTask?.title ?? '-'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.barlow(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularTimer() {
    final progress = _elapsedSeconds / _timeoutSeconds;
    final size = MediaQuery.of(context).size;
    final minDim = size.shortestSide;

    // 폰: 0.3, 태블릿: 0.2, 최소 140
    final timerSize = (minDim < 600 ? minDim * 0.3 : minDim * 0.2).clamp(
      140.0,
      400.0,
    );

    return SizedBox(
      width: timerSize,
      height: timerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: timerSize,
            height: timerSize,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              // 크기에 비례하여 두께 조절 (최소 8)
              strokeWidth: min(8.0, timerSize * 0.05),
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation(
                progress > 0.8 ? Colors.red : Colors.deepPurple,
              ),
            ),
          ),
          Text(
            '${_timeoutSeconds - _elapsedSeconds}',
            style: GoogleFonts.barlowCondensed(
              color: Colors.white,
              fontSize: timerSize * 0.35, // 크기에 비례하여 폰트 조정
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyPoseOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 카운트다운 중일 때
            if (_countdownSeconds > 0) ...[
              Text(
                '$_countdownSeconds',
                style: GoogleFonts.barlowCondensed(
                  color: Colors.white,
                  fontSize: 120,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Get Ready!',
                style: GoogleFonts.barlowCondensed(
                  color: Colors.white70,
                  fontSize: 24,
                ),
              ),
            ] else if (!_isFullBodyVisible) ...[
              // 신체가 안 보일 때
              const Icon(Icons.person_outline, size: 100, color: Colors.orange),
              const SizedBox(height: 24),
              Text(
                'Adjust camera to see\nfull body',
                textAlign: TextAlign.center,
                style: GoogleFonts.barlowCondensed(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Shoulders, hips, knees, ankles\nmust be visible',
                textAlign: TextAlign.center,
                style: GoogleFonts.barlow(color: Colors.white54, fontSize: 16),
              ),
            ] else ...[
              // 신체가 보이고 카운트다운 대기 중
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'Checking pose...',
                style: GoogleFonts.barlowCondensed(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRestOverlay() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withValues(alpha: 0.4),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, size: 60, color: Colors.deepPurple),
                const SizedBox(height: 16),
                Text(
                  'Resting...',
                  style: GoogleFonts.barlowCondensed(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Analyzing. Please wait.',
                  style: GoogleFonts.barlow(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pause_circle, size: 80, color: Colors.white54),
                const SizedBox(height: 16),
                Text(
                  'Paused',
                  style: GoogleFonts.barlowCondensed(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
