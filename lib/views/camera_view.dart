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

/// CameraView - 운동 화면 (카메라 + 스켈레톤 오버레이 + UI)
class CameraView extends StatefulWidget {
  final WorkoutCurriculum? curriculum;

  const CameraView({super.key, this.curriculum});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  // 카메라 관련
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

  // 운동 상태
  WorkoutCurriculum? _curriculum;
  WorkoutTask? _currentTask;
  int _currentRep = 0;
  int _currentSet = 1;
  bool _isResting = false;
  bool _isPaused = false;

  // 타이머
  Timer? _workoutTimer;
  int _elapsedSeconds = 0;
  int _timeoutSeconds = 60;

  // 서비스
  final TTSService _ttsService = TTSService();
  final GeminiService _geminiService = GeminiService();
  final VideoRecorder _videoRecorder = VideoRecorder();

  // Rep 카운팅
  RepCounter? _repCounter;
  ExerciseConfig? _exerciseConfig;

  // 사용자 프로필
  UserProfile? _userProfile;

  // 분석 결과
  final List<SetAnalysis> _setAnalyses = [];

  // 녹화 상태
  bool _isRecording = false;

  // 낙상 감지
  final FallDetectionService _fallDetectionService = FallDetectionService();
  final bool _showFallConfirmDialog = false;

  // Ready Pose 감지
  List<Point3D>? _readyPoseReference;
  final double _poseSimilarity = 0.0;
  static const double _readyPoseThreshold = 0.8; // 80% 유사도

  // 신체 가시성 및 준비자세 카운트다운
  bool _isFullBodyVisible = false;
  bool _isWaitingForReadyPose = true;
  int _countdownSeconds = 0;
  Timer? _countdownTimer;
  DateTime? _lastBodyNotVisibleTTS;

  // 실시간 자세 피드백
  final FormRuleChecker _formRuleChecker = FormRuleChecker();

  // 가이드 비디오
  final String _dummyGuideVideoUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';

  // 서비스
  final ExerciseService _exerciseService = ExerciseService();
  late final DisplayViewModel _displayViewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 외부 디스플레이 뷰모델 초기화
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

      // ExerciseConfig 로드 (더미 또는 실제 데이터)
      _loadExerciseConfig();
    }
  }

  Future<void> _loadExerciseConfig() async {
    if (_currentTask == null) return;

    // TODO: 나중에 useMock: false로 변경하여 실제 데이터를 사용하세요.
    final config = await _exerciseService.getExerciseConfig(
      _currentTask!.title,
      useMock: true,
    );

    if (config != null && mounted) {
      setState(() {
        _exerciseConfig = config;
        _repCounter = RepCounter(_exerciseConfig!);
      });
    }

    // 실시간 자세 피드백 설정
    _formRuleChecker.setExercise(_currentTask?.title ?? 'squat');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 백그라운드 전환 시 일시정지
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

    // 가이드 비디오 초기화
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

    // TTS 초기화
    await _ttsService.initialize();

    // 사용자 프로필 로드
    _userProfile = await UserProfile.load();

    // 첫 세트 가이드 오디오
    if (_currentTask != null) {
      await _ttsService.speakWorkoutStart(_currentTask!.title);
    }

    // 준비자세 대기 모드로 시작 (타이머/녹화는 카운트다운 후 시작)
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
      // Gemini 분석 요청
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
        // 분석 결과 저장
        final setAnalysis = SetAnalysis.fromGeminiResponse(
          _currentSet,
          analysisResult,
        );
        _setAnalyses.add(setAnalysis);

        // TTS 피드백 재생
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
            // 타임아웃 - 세트 종료
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

      // 신체 가시성 체크 및 카운트다운 로직
      if (smoothedPoses.isNotEmpty) {
        final pose = smoothedPoses.first;
        final bodyVisible = _checkBodyVisibility(pose);

        if (mounted) {
          setState(() => _isFullBodyVisible = bodyVisible);
        }

        // 준비자세 대기 중일 때
        if (_isWaitingForReadyPose) {
          if (bodyVisible) {
            // 신체가 보이면 카운트다운 시작
            if (_countdownSeconds == 0 && _countdownTimer == null) {
              _startCountdown();
            }
          } else {
            // 신체가 안 보이면 카운트다운 취소 및 TTS 안내
            _cancelCountdown();
            _speakBodyNotVisibleThrottled();
          }
          return; // 준비자세 대기 중에는 아래 로직 실행 안 함
        }

        // 운동 중 신체가 안 보이면 안내
        if (!bodyVisible && !_isResting) {
          _speakBodyNotVisibleThrottled();
        }

        _videoRecorder.updatePose(pose); // ControlNet 프레임용

        // Rep 카운팅
        if (_repCounter != null && !_isResting) {
          final newRep = _repCounter!.processFrame(pose);
          if (newRep && mounted) {
            _incrementRep();
          }
        }

        // 실시간 자세 피드백
        if (!_isResting) {
          final formFeedback = _formRuleChecker.checkForm(pose);
          if (formFeedback != null) {
            _ttsService.speakFormCorrection(formFeedback);
          }

          // 외부 디스플레이 데이터 전송
          _displayViewModel.updateSessionData(
            exerciseName: _currentTask?.title ?? 'Ready',
            reps: _currentRep,
            feedback: formFeedback ?? 'Good Form!',
            isGoodPose: formFeedback == null,
          );
        }
      } else {
        // 포즈가 감지되지 않음
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

  /// 신체 가시성 체크 - 주요 랜드마크가 충분히 감지되는지 확인
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

    // 8개 중 6개 이상 보이면 OK
    return visibleCount >= 6;
  }

  /// 카운트다운 시작 (3초)
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
        // 카운트다운 완료 - 운동 시작!
        timer.cancel();
        _countdownTimer = null;
        _ttsService.speakCountdown(0); // "시작!"
        _onCountdownComplete();
      }
    });
  }

  /// 카운트다운 취소
  void _cancelCountdown() {
    if (_countdownTimer != null) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
      if (mounted) {
        setState(() => _countdownSeconds = 0);
      }
    }
  }

  /// TTS 안내 (5초에 한 번만)
  void _speakBodyNotVisibleThrottled() {
    final now = DateTime.now();
    if (_lastBodyNotVisibleTTS == null ||
        now.difference(_lastBodyNotVisibleTTS!).inSeconds >= 5) {
      _lastBodyNotVisibleTTS = now;
      _ttsService.speakBodyNotVisible();
    }
  }

  /// 카운트다운 완료 후 운동 시작
  Future<void> _onCountdownComplete() async {
    setState(() {
      _isWaitingForReadyPose = false;
    });

    // 녹화 시작
    if (_controller != null) {
      await _startRecording();
    }

    // 타이머 시작
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

    // 녹화 중지 및 분석 요청
    await _stopRecordingAndAnalyze();

    // 휴식 안내
    await _ttsService.speakRestStart(10);

    // 다음 세트/운동 준비
    _currentSet++;
    final maxSets = _currentTask?.adjustedSets ?? 3;

    if (_currentSet > maxSets) {
      // 다음 운동으로 이동
      _curriculum?.moveToNextSet();
      _currentTask = _curriculum?.currentTask;
      _currentSet = 1;

      // ExerciseConfig 재로드
      _loadExerciseConfig();
      _repCounter?.reset();

      if (_currentTask == null || _curriculum?.isCompleted == true) {
        // 모든 운동 완료
        await _ttsService.speakWorkoutComplete();
        _showCompletionDialog();
        return;
      }
    }

    // 휴식 후 다음 세트
    _currentRep = 0;
    _elapsedSeconds = 0;
    _timeoutSeconds = _currentTask?.timeoutSec ?? 60;
    _repCounter?.reset();

    // 휴식 시간 (10초 후 자세 준비 안내)
    await Future.delayed(const Duration(seconds: 10));

    if (mounted) {
      await _ttsService.speakReadyPose();
      setState(() => _isResting = false);

      // 다음 세트 녹화 시작
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
          // 1. 카메라 프리뷰
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

          // 2. 스켈레톤 오버레이
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

          // 3. 상단 UI - 뒤로가기 + 상태 정보 (Top Right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 뒤로가기 버튼
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

                // 우측 정보 (다음 운동)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [_buildCurrentTaskInfo()],
                ),
              ],
            ),
          ),

          // 5. 가이드 비디오 (우측 하단) - 사용자 요청: 버튼 대신 영상 표시
          Positioned(right: 16, bottom: 40, child: _buildGuidePIP()),

          // 6. 하단 UI - 타이머 (좌측)
          if (!_isWaitingForReadyPose)
            Positioned(bottom: 40, left: 16, child: _buildCircularTimer()),

          // 7. 준비자세 대기 오버레이
          if (_isWaitingForReadyPose) _buildReadyPoseOverlay(),

          // 8. 휴식 오버레이
          if (_isResting) _buildRestOverlay(),

          // 9. 일시정지 오버레이
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
