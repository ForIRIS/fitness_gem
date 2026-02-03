import 'package:equatable/equatable.dart';
import '../../domain/entities/workout_curriculum.dart';
import '../../domain/entities/workout_task.dart';

enum SessionPhase {
  ready, // Waiting for ready pose (or initial load)
  countdown, // 5-4-3-2-1
  working, // Exercise in progress
  resting, // Rest between sets/exercises
  paused, // User paused
  completed, // All exercises done
  analyzing, // Analyzing previous set (during rest)
  testing, // Camera Test Mode (no logic)
}

class WorkoutSessionState extends Equatable {
  final WorkoutCurriculum? curriculum;
  final WorkoutTask? currentTask;
  final int currentRep;
  final int currentSet;
  final int elapsedSeconds;
  final int timeoutSeconds;

  // Phase & Status
  final SessionPhase phase;
  final bool isFullBodyVisible;
  final int countdownSeconds;
  final int readyPoseHoldSeconds;

  // New: Feedback State
  final String? lastFeedback;
  final bool isGoodPose;
  final bool isTestMode;

  const WorkoutSessionState({
    this.curriculum,
    this.currentTask,
    this.currentRep = 0,
    this.currentSet = 1,
    this.elapsedSeconds = 0,
    this.timeoutSeconds = 60,
    this.phase = SessionPhase.ready,
    this.isFullBodyVisible = false,
    this.countdownSeconds = 0,
    this.readyPoseHoldSeconds = 0,
    this.lastFeedback,
    this.isGoodPose = true,
    this.isTestMode = false,
  });

  // Computed Properties
  bool get isWaitingForReadyPose => phase == SessionPhase.ready;
  bool get isResting =>
      phase == SessionPhase.resting || phase == SessionPhase.analyzing;
  bool get isPaused => phase == SessionPhase.paused;
  bool get isCompleted => phase == SessionPhase.completed;
  bool get isWorking => phase == SessionPhase.working;
  bool get isTesting => phase == SessionPhase.testing;

  double get timerProgress {
    if (timeoutSeconds == 0) return 0.0;
    return (elapsedSeconds / timeoutSeconds).clamp(0.0, 1.0);
  }

  WorkoutSessionState copyWith({
    WorkoutCurriculum? curriculum,
    WorkoutTask? currentTask,
    int? currentRep,
    int? currentSet,
    int? elapsedSeconds,
    int? timeoutSeconds,
    SessionPhase? phase,
    bool? isFullBodyVisible,
    int? countdownSeconds,
    int? readyPoseHoldSeconds,
    String? lastFeedback,
    bool? isGoodPose,
    bool? isTestMode,
  }) {
    return WorkoutSessionState(
      curriculum: curriculum ?? this.curriculum,
      currentTask: currentTask ?? this.currentTask,
      currentRep: currentRep ?? this.currentRep,
      currentSet: currentSet ?? this.currentSet,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      phase: phase ?? this.phase,
      isFullBodyVisible: isFullBodyVisible ?? this.isFullBodyVisible,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      readyPoseHoldSeconds: readyPoseHoldSeconds ?? this.readyPoseHoldSeconds,
      lastFeedback: lastFeedback ?? this.lastFeedback,
      isGoodPose: isGoodPose ?? this.isGoodPose,
      isTestMode: isTestMode ?? this.isTestMode,
    );
  }

  @override
  List<Object?> get props => [
    curriculum,
    currentTask,
    currentRep,
    currentSet,
    elapsedSeconds,
    timeoutSeconds,
    phase,
    isFullBodyVisible,
    countdownSeconds,
    readyPoseHoldSeconds,
    lastFeedback,
    isGoodPose,
    isTestMode,
  ];
}
