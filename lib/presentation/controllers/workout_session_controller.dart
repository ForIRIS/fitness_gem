import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../core/di/injection.dart';
import '../../domain/entities/workout_curriculum.dart';
import '../../domain/entities/workout_task.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/workout/save_curriculum.dart';
import '../../domain/entities/exercise_config.dart';
import '../../domain/usecases/workout/get_exercise_config_usecase.dart';
import '../../domain/usecases/ai/analyze_video_session_usecase.dart';
import '../../domain/services/coaching_manager.dart';
import '../../utils/rep_counter.dart';
import '../../utils/form_rule_checker.dart';
import '../../services/tts_service.dart';
import '../../services/video_recorder.dart';
import '../../services/camera_manager.dart'; // To access controller for recording
import '../../services/workout_timer_service.dart';
import '../../services/ready_pose_detector.dart';
import '../states/workout_session_state.dart';
import '../../viewmodels/display_viewmodel.dart';
import '../../services/gemini_cache_manager.dart';
import '../../services/voice_command_service.dart';

class WorkoutSessionController extends ChangeNotifier {
  // Internal State
  WorkoutSessionState _state = const WorkoutSessionState();
  WorkoutSessionState get state => _state;

  // Dependencies
  late final WorkoutTimerService _timerService;
  late final ReadyPoseDetector _readyPoseDetector;

  // External Services (Injected or Retrieved via GetIt)
  final TTSService _ttsService = TTSService();
  final VideoRecorder _videoRecorder = VideoRecorder();
  final CoachingManager _coachingManager = getIt<CoachingManager>();
  final GetExerciseConfigUseCase _getExerciseConfigUseCase =
      getIt<GetExerciseConfigUseCase>();
  final SaveCurriculumUseCase _saveCurriculumUseCase =
      getIt<SaveCurriculumUseCase>();
  final AnalyzeVideoSessionUseCase _analyzeVideoSession =
      getIt<AnalyzeVideoSessionUseCase>();
  final VoiceCommandService _voiceService = VoiceCommandService();

  // Logic Helpers
  RepCounter? _repCounter;
  final FormRuleChecker _formRuleChecker = FormRuleChecker();
  UserProfile? _userProfile;

  // Camera Controller Reference (for recording)
  CameraManager? _cameraManager;

  // External Display
  final DisplayViewModel _displayViewModel = DisplayViewModel();

  WorkoutSessionController() {
    _timerService = WorkoutTimerService();
    _readyPoseDetector = ReadyPoseDetector();

    // Wire up timer callbacks
    _timerService.onWorkoutTick = (elapsed) {
      _updateState(_state.copyWith(elapsedSeconds: elapsed));
    };

    _timerService.onWorkoutTimeout = _onSetComplete;

    _timerService.onCountdownTick = (remaining) {
      _updateState(_state.copyWith(countdownSeconds: remaining));
      _ttsService.speakCountdown(remaining);
    };

    _timerService.onCountdownComplete = _onCountdownComplete;
  }

  Future<void> initialize(
    WorkoutCurriculum curriculum,
    UserProfile? profile,
    CameraManager cameraManager,
  ) async {
    _userProfile = profile;
    _cameraManager = cameraManager;

    // Initialize services
    await _ttsService.initialize();
    await _voiceService.initialize();

    // Voice Command Callbacks
    _voiceService.onStart = () {
      debugPrint("Voice detected START");
      if (_state.phase == SessionPhase.ready) {
        _startCountdown();
      }
    };
    _voiceService.onPause = pause;
    _voiceService.onResume = resume;
    _voiceService.onStop = quit;

    // Start Listening immediately
    _voiceService.startListening();

    WorkoutCurriculum currentCurriculum = curriculum;
    WorkoutTask? initialTask;

    if (curriculum.workoutTasks.isNotEmpty) {
      initialTask = curriculum.currentTask ?? curriculum.workoutTasks[0];
    }

    // Set Initial State
    _updateState(
      _state.copyWith(
        curriculum: currentCurriculum,
        currentTask: initialTask,
        currentSet: (currentCurriculum.currentSetIndex) + 1,
        timeoutSeconds: initialTask?.timeoutSec ?? 60,
        phase: SessionPhase.ready, // Start waiting for ready pose
      ),
    );

    if (initialTask != null) {
      await _loadExerciseConfig(initialTask);
      _ttsService.speakWorkoutStart(initialTask.title);
      _formRuleChecker.setExercise(initialTask.title);
    }
  }

  Future<void> initializeTestMode(CameraManager cameraManager) async {
    _cameraManager = cameraManager;
    _updateState(
      _state.copyWith(phase: SessionPhase.testing, isTestMode: true),
    );
  }

  void setCameraManager(CameraManager manager) {
    _cameraManager = manager;
  }

  Future<void> _loadExerciseConfig(WorkoutTask task) async {
    final result = await _getExerciseConfigUseCase.execute(
      GetExerciseConfigParams(task: task),
    );

    // Extract config from Either without async callback in fold
    ExerciseConfig? config;
    result.fold(
      (failure) => debugPrint('Failed to load config: ${failure.message}'),
      (c) => config = c,
    );

    if (config == null) return;

    final counter = RepCounter(
      config!,
      coachingManager: _coachingManager,
      onRepCountChanged: _onRepCounted,
    );

    final loaded = await counter.initialize();
    debugPrint('Model loaded for ${task.title}: $loaded');

    // Dispose previous counter to free native resources
    await _repCounter?.dispose();
    _repCounter = counter;
  }

  // --- Core Processing Loop (Called on every frame) ---
  void processPose(Pose pose) {
    if (_state.isTestMode ||
        _state.phase == SessionPhase.paused ||
        _state.phase == SessionPhase.completed) {
      return;
    }

    // 1. Ready Pose Detection Phase
    if (_state.phase == SessionPhase.ready) {
      // Feed frames to RepCounter so it can detect 'Ready' class
      _repCounter?.processFrame(pose);

      final result = _readyPoseDetector.processFrame(pose, _repCounter);

      // Update Visibility only if changed significantly?
      // For UI smoothness, we update consistently or throttle.
      if (result.isBodyVisible != _state.isFullBodyVisible ||
          result.holdSeconds != _state.readyPoseHoldSeconds) {
        _updateState(
          _state.copyWith(
            isFullBodyVisible: result.isBodyVisible,
            readyPoseHoldSeconds: result.holdSeconds,
          ),
        );
      }

      if (result.isReady) {
        _startCountdown();
      } else if (!result.isBodyVisible) {
        // Optional: Throttle TTS warning
        // _coachingManager.deliver('Show your full body');
      }
      return;
    }

    // 2. Workout Phase
    if (_state.phase == SessionPhase.working) {
      // Update Recording Pose Data
      _videoRecorder.updatePose(
        pose,
        stability: _repCounter?.currentStability ?? 1.0,
      );

      // Process Reps
      _repCounter?.processFrame(pose);

      // Real-time Form Feedback
      final feedback = _formRuleChecker.checkForm(pose);
      if (feedback != null) {
        _ttsService.speakFormCorrection(feedback);
        _coachingManager.deliver(feedback);
      }

      _updateExternalDisplay(pose, feedback);
    }
  }

  void _startCountdown() {
    _updateState(
      _state.copyWith(phase: SessionPhase.countdown, countdownSeconds: 5),
    );
    _readyPoseDetector.reset();
    _ttsService.speakReady();
    _timerService.startCountdown(5);
  }

  Future<void> _onCountdownComplete() async {
    _ttsService.speakCountdown(0); // "Start!"

    // Reset RepCounter to clear buffer of Ready poses
    _repCounter?.reset();

    // Start Recording
    if (_cameraManager?.controller != null) {
      _videoRecorder.startRecording(_cameraManager!.controller!);
    }

    _updateState(
      _state.copyWith(phase: SessionPhase.working, elapsedSeconds: 0),
    );

    // Start Workout Timer
    _timerService.startWorkoutTimer(timeoutSeconds: _state.timeoutSeconds);
  }

  void _onRepCounted(int count) {
    _updateState(_state.copyWith(currentRep: count));

    // Check Set Completion
    final targetReps = _state.currentTask?.adjustedReps ?? 10;
    if (count >= targetReps) {
      _onSetComplete();
    }
  }

  Future<void> _onSetComplete() async {
    if (_state.phase == SessionPhase.resting ||
        _state.phase == SessionPhase.analyzing) {
      return;
    }

    // 1. Stop Current Set
    _timerService.stopWorkoutTimer();
    final recordingResult = await _videoRecorder.stopRecording();

    // 2. Start Rest Phase Immediately — clear previous feedback
    final restTime = _state.currentTask?.timeoutSec ?? 15;
    _ttsService.speakRestStart(restTime);

    _updateState(
      _state.copyWith(
        phase: SessionPhase.resting,
        timeoutSeconds: restTime,
        elapsedSeconds: 0,
        lastFeedback: '', // Clear previous set's analysis
      ),
    );

    // Start Rest Timer (Visual Countdown)
    _timerService.startWorkoutTimer(timeoutSeconds: restTime);

    // 3. Trigger AI Analysis in Background (Dont await)
    if (_userProfile != null &&
        _state.currentTask != null &&
        recordingResult != null) {
      _runBackgroundAnalysis(recordingResult);
    }

    // 4. Wait for Rest to Finish
    await Future.delayed(Duration(seconds: restTime));

    // Safety: Stop timer if it's still running for some reason
    _timerService.stopWorkoutTimer();

    if (_state.phase != SessionPhase.paused) {
      _proceedToNextSet();
    }
  }

  Future<void> _runBackgroundAnalysis(RecordingResult recordingResult) async {
    try {
      final analysisResult = await _analyzeVideoSession.execute(
        AnalyzeVideoSessionParams(
          rgbVideoFile: recordingResult.rgbFile,
          controlNetVideoFile: recordingResult.controlNetFile,
          profile: _userProfile!,
          exerciseName: _state.currentTask!.title,
          setNumber: _state.currentSet,
          totalSets: _state.currentTask!.adjustedSets,
          language: 'ko', // UI language preferred
        ),
      );

      analysisResult.fold(
        (failure) => debugPrint('AI Analysis failed: $failure'),
        (data) {
          if (data != null && _state.phase == SessionPhase.resting) {
            _applyAiAdjustments(data);
          }
        },
      );
    } catch (e) {
      debugPrint('Error in background analysis: $e');
    }
  }

  void _applyAiAdjustments(Map<String, dynamic> data) {
    // Implement AI adjustment log (same as original)
    final feedbackText = data['feedback']?['tts_message'];

    if (feedbackText != null) {
      _ttsService.speak(feedbackText);
      // Update state to show feedback in UI
      _updateState(_state.copyWith(lastFeedback: feedbackText));

      // Clear feedback after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (_state.lastFeedback == feedbackText) {
          _updateState(_state.copyWith(lastFeedback: null));
        }
      });
    }

    final adjustments = data['feedback']?['next_step_adjustments'];
    if (adjustments != null) {
      final int? repsChange = adjustments['reps_change'];
      final int? restChange = adjustments['rest_change'];

      if (repsChange == null && restChange == null) return;

      final currentTask = _state.currentTask;
      if (currentTask == null || _state.curriculum == null) return;

      // Calculate new values
      int newReps = currentTask.adjustedReps + (repsChange ?? 0);
      newReps = newReps.clamp(1, 100); // Safety bounds

      int newRest = currentTask.timeoutSec + (restChange ?? 0);
      newRest = newRest.clamp(5, 300); // Safety bounds

      // Update Task in Curriculum
      final updatedTasks = List<WorkoutTask>.from(
        _state.curriculum!.workoutTasks,
      );
      final taskIndex = _state.curriculum!.currentTaskIndex;

      updatedTasks[taskIndex] = currentTask.copyWith(
        adjustedReps: newReps,
        timeoutSec: newRest,
      );

      final updatedCurriculum = _state.curriculum!.copyWith(
        workoutTasks: updatedTasks,
      );

      // Persist changes
      _saveCurriculumUseCase.execute(updatedCurriculum);

      // Update State
      _updateState(
        _state.copyWith(
          curriculum: updatedCurriculum,
          currentTask: updatedTasks[taskIndex],
        ),
      );

      // Optional: Extend current rest if rest was increased?
      // For now, we announce the change.
      if (repsChange != null && repsChange != 0) {
        // e.g. "Lowering reps to 8 for the next set."
        final msg = repsChange < 0
            ? "Decreasing reps to $newReps to help you maintain form."
            : "Increasing reps to $newReps. You're doing great!";
        _ttsService.speak(msg);
      }
    }
  }

  Future<void> _proceedToNextSet() async {
    if (_state.curriculum == null) return;

    final updatedCurriculum = _state.curriculum!.moveToNextSet();
    await _saveCurriculumUseCase.execute(updatedCurriculum);

    if (updatedCurriculum.isCompleted) {
      _finishWorkout();
    } else {
      final nextTask = updatedCurriculum.currentTask;
      final isNewTask = nextTask?.id != _state.currentTask?.id;

      if (isNewTask && nextTask != null) {
        await _loadExerciseConfig(nextTask);
        _repCounter?.reset();
      } else {
        _repCounter?.reset();
      }

      await _ttsService.speakReadyPose();

      _updateState(
        _state.copyWith(
          curriculum: updatedCurriculum,
          currentTask: nextTask,
          currentSet: updatedCurriculum.currentSetIndex + 1,
          currentRep: 0,
          elapsedSeconds: 0,
          timeoutSeconds: nextTask?.timeoutSec ?? 60,
          phase: SessionPhase.ready, // Back to Ready Pose
          isFullBodyVisible: false,
          readyPoseHoldSeconds: 0,
        ),
      );

      _readyPoseDetector.reset();
    }
  }

  void _finishWorkout() {
    _updateState(_state.copyWith(phase: SessionPhase.completed));
    _ttsService.speakWorkoutComplete();

    // Log Workout to History for Progress Tracking
    try {
      final cacheManager = GeminiCacheManager();
      cacheManager.logEvent(
        type: 'workout',
        data: {
          'exercise': _state.curriculum?.currentTask?.title ?? 'Unknown',
          'sets_completed': _state.currentSet,
          'total_reps':
              _state.currentRep, // This is just last set, ideally total
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error logging workout: $e');
    }
  }

  SessionPhase? _previousPhase;

  // --- Actions ---
  void pause() {
    if (_state.isPaused) return;
    _previousPhase = _state.phase;
    _timerService.stopWorkoutTimer();
    _timerService.cancelCountdown();
    if (_cameraManager?.controller != null) {
      _cameraManager!.stopPoseDetection();
      // Note: CameraController might need to be paused/resumed carefully
    }
    _updateState(_state.copyWith(phase: SessionPhase.paused));
  }

  void resume() {
    if (!_state.isPaused) return;

    final targetPhase = _previousPhase ?? SessionPhase.ready;

    if (targetPhase == SessionPhase.working) {
      _timerService.startWorkoutTimer(
        timeoutSeconds: _state.timeoutSeconds,
        initialElapsed: _state.elapsedSeconds,
      );
    } else if (targetPhase == SessionPhase.countdown) {
      _timerService.startCountdown(_state.countdownSeconds);
    }

    if (_cameraManager != null) {
      _cameraManager!.startPoseDetection();
    }

    _updateState(_state.copyWith(phase: targetPhase));
  }

  void quit() {
    _timerService.dispose();
    _videoRecorder.dispose();
    _ttsService.dispose();
    _displayViewModel.dispose();
    // Clean up
  }

  void _updateState(WorkoutSessionState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  void _updateExternalDisplay(Pose pose, String? feedback) {
    // Send Data to External Display
    _displayViewModel.updateSessionData(
      exerciseName: _state.currentTask?.title ?? 'Ready',
      reps: _state.currentRep,
      feedback: feedback ?? 'Good Form!',
      isGoodPose: feedback == null,
    );
  }

  @override
  void dispose() {
    _voiceService.stopListening();
    _voiceService.dispose();
    _timerService.dispose();
    _videoRecorder.dispose();
    _ttsService.dispose();
    _displayViewModel.dispose();
    _repCounter?.dispose(); // Release native ML resources
    super.dispose();
  }
}
