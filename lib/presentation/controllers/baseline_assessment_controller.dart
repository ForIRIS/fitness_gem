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
import '../../services/stt_service.dart';
import '../../services/workout_timer_service.dart';
import '../../l10n/app_localizations.dart';

enum AssessmentPhase {
  instructions,
  ready, // Waiting for voice command
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
  final STTService _sttService;
  final WorkoutTimerService _timerService = WorkoutTimerService();

  final AnalyzeBaselineVideoUseCase _analyzeBaselineVideo =
      getIt<AnalyzeBaselineVideoUseCase>();
  final UpdateUserProfileUseCase _updateUserProfile =
      getIt<UpdateUserProfileUseCase>();

  UserProfile? _userProfile;
  AppLocalizations? _l10n;

  BaselineAssessmentController({STTService? sttService})
    : _sttService = sttService ?? getIt<STTService>() {
    _timerService.onWorkoutTick = (elapsed) {
      _recordingSeconds = elapsed;
      notifyListeners();
    };
    _timerService.onWorkoutTimeout = _stopRecording;
  }

  Future<void> initialize(UserProfile profile, AppLocalizations l10n) async {
    _userProfile = profile;
    _l10n = l10n;
    _ttsService.updateLocalizations(l10n);

    await _ttsService.initialize();
    await _sttService.initialize();
    await _cameraManager.initialize();
    _cameraManager.startPoseDetection();

    _cameraManager.poseStream.listen(_processPose);

    _updatePhase(AssessmentPhase.instructions);
    _ttsService.speak(
      _l10n?.baselineTtsStart ??
          'We will now perform a quick physical assessment. Please stand back so your full body is visible.',
    );
  }

  void startReadyPhase() {
    _updatePhase(AssessmentPhase.ready);
    _startListeningForCommand();
  }

  void _startListeningForCommand() {
    _sttService.startListening(
      onResult: (recognizedText) {
        final text = recognizedText.toLowerCase().trim();
        debugPrint('[BaselineController] STT Recognized: $text');
        if (text.contains('start') ||
            text.contains('begin') ||
            text.contains('go') ||
            text.contains('ready') ||
            text.contains('시작') ||
            text.contains('고')) {
          _sttService.stopListening();
          _startRecording();
        }
      },
      languageCode: _l10n?.localeName == 'ko' ? 'ko-KR' : 'en-US',
    );
  }

  void _processPose(List<Pose> poses) {
    if (poses.isEmpty || _phase != AssessmentPhase.recording) {
      return;
    }

    final pose = poses.first;
    _videoRecorder.updatePose(pose);
  }

  void forceStartRecording() {
    _sttService.stopListening();
    _startRecording();
  }

  Future<void> _startRecording() async {
    _updatePhase(AssessmentPhase.recording);
    _recordingSeconds = 0;
    _ttsService.speakCountdown(0); // "Start"

    if (_cameraManager.controller != null) {
      await _videoRecorder.startRecording(_cameraManager.controller!);
    }

    _timerService.startWorkoutTimer(timeoutSeconds: 10);
    _ttsService.speak(
      _l10n?.baselineTtsPerformSquats ??
          'Please perform 3 moderate air squats.',
    );
  }

  Future<void> _stopRecording() async {
    _updatePhase(AssessmentPhase.analyzing);
    _timerService.stopWorkoutTimer();
    final result = await _videoRecorder.stopRecording();

    if (result != null) {
      await _runAnalysis(result.rgbVideoPath);
    } else {
      _handleError(
        _l10n?.errorCaptureFailed ?? 'Failed to capture assessment video',
      );
    }
  }

  Future<void> _runAnalysis(String videoPath) async {
    final result = await _analyzeBaselineVideo.execute(videoPath);

    await result.fold(
      (failure) async {
        _handleError(
          _l10n?.errorAnalysisFailed(failure.message) ??
              'Analysis failed: ${failure.message}',
        );
      },
      (data) async {
        _analysisResult = data;
        await _saveResultsToProfile(data);
        _updatePhase(AssessmentPhase.completed);
        _ttsService.speak(
          _l10n?.baselineTtsComplete ??
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
    _ttsService.speak(
      _l10n?.baselineTtsError ??
          'An error occurred during assessment. Please try again.',
    );
  }

  void retry() {
    _timerService.stopWorkoutTimer();
    _sttService.stopListening();
    _isFullBodyVisible = false;
    _holdSeconds = 0;
    _recordingSeconds = 0;
    _errorMessage = null;
    _analysisResult = null;
    _readyPoseDetector.reset();

    _updatePhase(AssessmentPhase.instructions);
    _ttsService.speak(
      _l10n?.baselineTtsStart ??
          'We will now perform a quick physical assessment. Please stand back so your full body is visible.',
    );
  }

  void _updatePhase(AssessmentPhase newPhase) {
    _phase = newPhase;
    notifyListeners();
  }

  @override
  void dispose() {
    _timerService.dispose();
    _sttService.stopListening();
    _cameraManager.dispose();
    _videoRecorder.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}
