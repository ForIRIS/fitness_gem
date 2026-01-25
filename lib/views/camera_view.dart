import 'package:camera/camera.dart';
import 'dart:async';
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
import '../utils/pose_similarity.dart';
import '../utils/form_rule_checker.dart';
import '../services/tts_service.dart';
import '../services/gemini_service.dart';
import '../services/video_recorder.dart';
import '../services/fall_detection_service.dart';
import '../models/workout_curriculum.dart';
import '../models/workout_task.dart';
import '../models/exercise_config.dart';
import '../models/user_profile.dart';
import '../models/session_analysis.dart';
import '../services/exercise_service.dart';
import '../viewmodels/display_viewmodel.dart';

/// CameraView - Workout Screen (Camera + Skeleton Overlay + UI)
class CameraView extends StatefulWidget {
  final WorkoutCurriculum? curriculum;

  const CameraView({super.key, this.curriculum});

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
  final GeminiService _geminiService = GeminiService();
  final VideoRecorder _videoRecorder = VideoRecorder();

  // Rep Counting
  RepCounter? _repCounter;
  ExerciseConfig? _exerciseConfig;

  // User Profile
  UserProfile? _userProfile;

  // Analysis Results
  final List<SetAnalysis> _setAnalyses = [];

  // Recording State
  bool _isRecording = false;

  // Fall Detection
  final FallDetectionService _fallDetectionService = FallDetectionService();
  final bool _showFallConfirmDialog = false;

  // Ready Pose Detection
  List<Point3D>? _readyPoseReference;
  final double _poseSimilarity = 0.0;
  static const double _readyPoseThreshold = 0.8; // 80% 유사도

  // Body Visibility and Countdown
  bool _isFullBodyVisible = false;
  bool _isWaitingForReadyPose = true;
  int _countdownSeconds = 0;
  Timer? _countdownTimer;
  DateTime? _lastBodyNotVisibleTTS;

  // Real-time Form Feedback
  final FormRuleChecker _formRuleChecker = FormRuleChecker();

  // Guide Video
  final String _dummyGuideVideoUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';

  // 서비스
  final ExerciseService _exerciseService = ExerciseService();
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
    super.dispose();
  }

  void _initializeWorkout() {
    if (_curriculum != null && _curriculum!.workoutTaskList.isNotEmpty) {
      _currentTask = _curriculum!.currentTask;
      _timeoutSeconds = _currentTask?.timeoutSec ?? 60;

      // Load ExerciseConfig (Mock or Real)
      _loadExerciseConfig();
    }
  }

  Future<void> _loadExerciseConfig() async {
    if (_currentTask == null) return;

    // TODO: Change to useMock: false later to use real data.
    final config = await _exerciseService.getExerciseConfig(
      _currentTask!,
      useMock: true,
    );

    if (config != null && mounted) {
      setState(() {
        _exerciseConfig = config;
        _repCounter = RepCounter(_exerciseConfig!);
      });
    }

    // Set Real-time Form Feedback
    _formRuleChecker.setExercise(_currentTask?.title ?? 'squat');
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
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('일시정지됨', style: TextStyle(color: Colors.white)),
        content: const Text(
          '운동이 일시정지되었습니다. 계속하시겠습니까?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // 운동 화면 종료
            },
            child: const Text('종료'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeWorkout();
            },
            child: const Text('계속하기'),
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
            _guideVideoController!.play();
          });

    // Initialize TTS
    await _ttsService.initialize();

    // Load User Profile
    _userProfile = await UserProfile.load();

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

  Future<void> _startRecording() async {
    if (_controller == null || _isRecording) return;

    final success = await _videoRecorder.startRecording(_controller!);
    if (success) {
      _isRecording = true;
    }
  }

  Future<void> _stopRecordingAndAnalyze() async {
    if (!_isRecording) return;

    final result = await _videoRecorder.stopRecording();
    _isRecording = false;

    if (result != null && _userProfile != null && _currentTask != null) {
      // Request Gemini Analysis
      await _ttsService.speakAnalyzing();

      final analysisResult = await _geminiService.analyzeVideoSession(
        rgbVideoFile: result.rgbFile,
        controlNetVideoFile: result.controlNetFile ?? result.rgbFile,
        profile: _userProfile!,
        exerciseName: _currentTask!.title,
        setNumber: _currentSet,
        totalSets: _currentTask!.adjustedSets,
        language: Localizations.localeOf(context).languageCode,
      );

      if (analysisResult != null) {
        // Save Analysis Result
        final setAnalysis = SetAnalysis.fromGeminiResponse(
          _currentSet,
          analysisResult,
        );
        _setAnalyses.add(setAnalysis);

        // Play TTS Feedback
        final ttsMessage = analysisResult['feedback']?['tts_message'];
        if (ttsMessage != null && ttsMessage.isNotEmpty) {
          await _ttsService.speak(ttsMessage);
        }
      }
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

        // 준비자세 대기 중일 때
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
          final newRep = _repCounter!.processFrame(pose);
          if (newRep && mounted) {
            _incrementRep();
          }
        }

        // Real-time Form Feedback
        if (!_isResting) {
          final formFeedback = _formRuleChecker.checkForm(pose);
          if (formFeedback != null) {
            _ttsService.speakFormCorrection(formFeedback);
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
        _ttsService.speakCountdown(0); // "시작!"
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

  /// TTS Warning (Throttled to once every 5 seconds)
  void _speakBodyNotVisibleThrottled() {
    final now = DateTime.now();
    if (_lastBodyNotVisibleTTS == null ||
        now.difference(_lastBodyNotVisibleTTS!).inSeconds >= 5) {
      _lastBodyNotVisibleTTS = now;
      _ttsService.speakBodyNotVisible();
    }
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

    // Start Timer
    _startWorkoutTimer();
  }

  void _incrementRep() {
    setState(() {
      _currentRep++;
      if (_currentRep >= (_currentTask?.adjustedReps ?? 10)) {
        _onSetComplete();
      }
    });
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
    _currentSet++;
    final maxSets = _currentTask?.adjustedSets ?? 3;

    if (_currentSet > maxSets) {
      // Move to Next Exercise
      _curriculum?.moveToNextSet();
      _currentTask = _curriculum?.currentTask;
      _currentSet = 1;

      // Reload ExerciseConfig
      _loadExerciseConfig();
      _repCounter?.reset();

      if (_currentTask == null || _curriculum?.isCompleted == true) {
        // All Workouts Complete
        await _ttsService.speakWorkoutComplete();
        _showCompletionDialog();
        return;
      }
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
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('운동 완료! 🎉', style: TextStyle(color: Colors.white)),
        content: const Text(
          '오늘의 운동을 모두 완료했습니다. 수고하셨습니다!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('홈으로'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview
          if (_controller != null && _controller!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize!.height,
                  height: _controller!.value.previewSize!.width,
                  child: CameraPreview(_controller!),
                ),
              ),
            )
          else
            const Center(
              child: Text(
                "카메라 사용 불가 (시뮬레이터)",
                style: TextStyle(color: Colors.white),
              ),
            ),

          // 2. Skeleton Overlay
          if (_poses.isNotEmpty && _controller != null)
            Transform.scale(
              scaleX: -1,
              alignment: Alignment.center,
              child: CustomPaint(
                painter: PosePainter(
                  _poses,
                  _controller!.value.previewSize!,
                  Platform.isAndroid
                      ? InputImageRotation.rotation270deg
                      : InputImageRotation
                            .rotation90deg, // iOS Portrait Scaling Fix
                  _camera?.lensDirection ?? CameraLensDirection.front,
                ),
              ),
            ),

          // 3. Top UI - Back + Status Info (Top Right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    _buildNextExerciseCard(),
                    if (_currentTask != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _currentTask?.title ?? '',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),

                // Right Info (Next Exercise)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [_buildCurrentTaskInfo()],
                ),
              ],
            ),
          ),

          // 5. Guide Video (Bottom Right) - User request: Show video instead of button
          Positioned(right: 16, bottom: 40, child: _buildGuidePIP()),

          // 6. Bottom UI - Timer (Left)
          if (!_isWaitingForReadyPose)
            Positioned(bottom: 40, left: 16, child: _buildCircularTimer()),

          // 7. Ready Pose Waiting Overlay
          if (_isWaitingForReadyPose) _buildReadyPoseOverlay(),

          // 8. Rest Overlay
          if (_isResting) _buildRestOverlay(),

          // 9. Pause Overlay
          if (_isPaused) _buildPauseOverlay(),
        ],
      ),
    );
  }

  Widget _buildCurrentTaskInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: 12),
        Text(
          '$_currentRep / ${_currentTask?.adjustedReps ?? '-'}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Set $_currentSet / ${_currentTask?.adjustedSets ?? '-'}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
          ),
        ),
      ],
    );
  }

  Widget _buildGuidePIP() {
    return Container(
      width: 120, // 조금 더 키움
      height: 160,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.black54,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child:
            _guideVideoController != null &&
                _guideVideoController!.value.isInitialized
            ? AspectRatio(
                aspectRatio: _guideVideoController!.value.aspectRatio,
                child: VideoPlayer(_guideVideoController!),
              )
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }

  Widget _buildNextExerciseCard() {
    final nextTask = _curriculum?.nextTask;
    final isLast = _curriculum?.isLastTask ?? true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '다음 운동',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            isLast ? '마지막 운동' : (nextTask?.title ?? '-'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
            style: TextStyle(
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 120,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '준비하세요!',
                style: TextStyle(color: Colors.white70, fontSize: 24),
              ),
            ] else if (!_isFullBodyVisible) ...[
              // 신체가 안 보일 때
              const Icon(Icons.person_outline, size: 100, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                '전체 몸이 보이도록\n카메라를 조정해주세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '어깨, 엉덩이, 무릎, 발목이\n모두 화면에 보여야 합니다',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ] else ...[
              // 신체가 보이고 카운트다운 대기 중
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                '자세 확인 중...',
                style: TextStyle(
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
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer, size: 60, color: Colors.deepPurple),
            const SizedBox(height: 16),
            const Text(
              '휴식 중...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '분석 중입니다. 잠시만 기다려주세요.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_circle, size: 80, color: Colors.white54),
            const SizedBox(height: 16),
            const Text(
              '일시정지',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
