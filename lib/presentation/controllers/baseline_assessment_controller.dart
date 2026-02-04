import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../core/di/injection.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/ai/analyze_baseline_video_usecase.dart';
import '../../domain/usecases/user/update_user_profile.dart';
import '../../services/camera_manager.dart';
import '../../services/video_recorder.dart';
import '../../services/ready_pose_detector.dart';
import '../../services/tts_service.dart';
import '../../services/workout_timer_service.dart';

enum AssessmentPhase {
  instructions,
  ready,
  countdown,
  recording,
  analyzing,
  completed,
  error,
}

class BaselineAssessmentController extends ChangeNotifier {
  // State
  AssessmentPhase _phase = AssessmentPhase.instructions;
  AssessmentPhase get phase => _phase;

  bool _isFullBodyVisible = false;
  bool get isFullBodyVisible => _isFullBodyVisible;

  int _holdSeconds = 0;
  int get holdSeconds => _holdSeconds;

  int _countdownSeconds = 5;
  int get countdownSeconds => _countdownSeconds;

  int _recordingSeconds = 0;
  int get recordingSeconds => _recordingSeconds;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? _analysisResult;
  Map<String, dynamic>? get analysisResult => _analysisResult;

  // Dependencies
  final CameraManager _cameraManager = CameraManager();
  CameraManager get cameraManager => _cameraManager;
  final VideoRecorder _videoRecorder = VideoRecorder();
  final ReadyPoseDetector _readyPoseDetector = ReadyPoseDetector();
  final TTSService _ttsService = TTSService();
  final WorkoutTimerService _timerService = WorkoutTimerService();

  final AnalyzeBaselineVideoUseCase _analyzeBaselineVideo =
      getIt<AnalyzeBaselineVideoUseCase>();
  final UpdateUserProfileUseCase _updateUserProfile =
      getIt<UpdateUserProfileUseCase>();

  UserProfile? _userProfile;

  BaselineAssessmentController() {
    _timerService.onCountdownTick = (remaining) {
      _countdownSeconds = remaining;
      _ttsService.speakCountdown(remaining);
      notifyListeners();
    };
    _timerService.onCountdownComplete = _startRecording;

    _timerService.onWorkoutTick = (elapsed) {
      _recordingSeconds = elapsed;
      notifyListeners();
    };
    _timerService.onWorkoutTimeout = _stopRecording;
  }

  Future<void> initialize(UserProfile profile) async {
    _userProfile = profile;
    await _ttsService.initialize();
    await _cameraManager.initialize();
    _cameraManager.startPoseDetection();

    _cameraManager.poseStream.listen(_processPose);

    _updatePhase(AssessmentPhase.instructions);
    _ttsService.speak(
      'We will now perform a quick physical assessment. Please stand back so your full body is visible.',
    );
  }

  void startReadyPhase() {
    _updatePhase(AssessmentPhase.ready);
  }

  void _processPose(List<Pose> poses) {
    if (poses.isEmpty ||
        (_phase != AssessmentPhase.ready &&
            _phase != AssessmentPhase.recording)) {
      return;
    }

    final pose = poses.first;

    if (_phase == AssessmentPhase.ready) {
      final result = _readyPoseDetector.processFrame(pose, null);

      if (result.isBodyVisible != _isFullBodyVisible ||
          result.holdSeconds != _holdSeconds) {
        _isFullBodyVisible = result.isBodyVisible;
        _holdSeconds = result.holdSeconds;
        notifyListeners();
      }

      if (result.isReady) {
        _startCountdown();
      }
    } else if (_phase == AssessmentPhase.recording) {
      _videoRecorder.updatePose(pose);
    }
  }

  void _startCountdown() {
    _updatePhase(AssessmentPhase.countdown);
    _readyPoseDetector.reset();
    _countdownSeconds = 5;
    _ttsService.speakReady();
    _timerService.startCountdown(5);
  }

  Future<void> _startRecording() async {
    _updatePhase(AssessmentPhase.recording);
    _recordingSeconds = 0;
    _ttsService.speakCountdown(0); // "Start"

    if (_cameraManager.controller != null) {
      await _videoRecorder.startRecording(_cameraManager.controller!);
    }

    _timerService.startWorkoutTimer(timeoutSeconds: 10);
    _ttsService.speak('Please perform 3 moderate air squats.');
  }

  Future<void> _stopRecording() async {
    _updatePhase(AssessmentPhase.analyzing);
    _timerService.stopWorkoutTimer();
    final result = await _videoRecorder.stopRecording();

    if (result != null) {
      await _runAnalysis(result.rgbVideoPath);
    } else {
      _handleError('Failed to capture assessment video');
    }
  }

  Future<void> _runAnalysis(String videoPath) async {
    final result = await _analyzeBaselineVideo.execute(videoPath);

    await result.fold(
      (failure) async {
        _handleError('Analysis failed: ${failure.message}');
      },
      (data) async {
        _analysisResult = data;
        await _saveResultsToProfile(data);
        _updatePhase(AssessmentPhase.completed);
        _ttsService.speak(
          'Assessment complete. I have updated your physical profile.',
        );
      },
    );
  }

  Future<void> _saveResultsToProfile(Map<String, dynamic> data) async {
    if (_userProfile == null) return;

    final stability = (data['stability_score'] as num?)?.toDouble() ?? 0.0;
    final mobility = (data['mobility_score'] as num?)?.toDouble() ?? 0.0;
    final analysis = data['summary'] as String? ?? '';

    final updatedProfile = _userProfile!.copyWith(
      stabilityBaseline: stability,
      mobilityScore: mobility,
      baselineAnalysis: analysis,
    );

    await _updateUserProfile.execute(updatedProfile);
  }

  void _handleError(String message) {
    _errorMessage = message;
    _updatePhase(AssessmentPhase.error);
    _ttsService.speak('An error occurred during assessment. Please try again.');
  }

  void _updatePhase(AssessmentPhase newPhase) {
    _phase = newPhase;
    notifyListeners();
  }

  @override
  void dispose() {
    _timerService.dispose();
    _cameraManager.dispose();
    _videoRecorder.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}
