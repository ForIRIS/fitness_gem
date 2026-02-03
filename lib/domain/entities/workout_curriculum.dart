import 'package:equatable/equatable.dart';
import 'workout_task.dart';

/// Domain Entity: WorkoutCurriculum
/// Pure business object representing a daily workout plan
class WorkoutCurriculum extends Equatable {
  final String id;
  final String title;
  final String description;
  final String thumbnail;
  final List<WorkoutTask> workoutTasks;
  final DateTime createdAt;

  final int currentTaskIndex;
  final int currentSetIndex;

  const WorkoutCurriculum({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnail = '',
    required this.workoutTasks,
    required this.createdAt,
    this.currentTaskIndex = 0,
    this.currentSetIndex = 0,
  });

  // Business logic methods

  /// Total estimated time in minutes
  int get estimatedMinutes {
    double totalSeconds = 0;

    for (int i = 0; i < workoutTasks.length; i++) {
      final task = workoutTasks[i];
      double taskSeconds = 0;

      if (task.isCountable) {
        // Dynamic exercise: Estimate 4s per rep
        // (eccentric + concentric + pause)
        taskSeconds += task.adjustedReps * 4 * task.adjustedSets;
      } else {
        // Static exercise: Use duration
        // If adjustedDurationSec is set, use it, otherwise use default durationSec or fallback to 30s
        final duration = task.adjustedDurationSec ?? task.durationSec ?? 30;
        taskSeconds += duration * task.adjustedSets;
      }

      // Add rest time between sets (Sets - 1 rests)
      if (task.adjustedSets > 1) {
        taskSeconds += (task.adjustedSets - 1) * task.timeoutSec;
      }

      totalSeconds += taskSeconds;

      // Add transition time between tasks (e.g., 60 seconds)
      if (i < workoutTasks.length - 1) {
        totalSeconds += 60;
      }
    }

    return (totalSeconds / 60).ceil();
  }

  /// Summary text for display
  String get summaryText {
    if (workoutTasks.isEmpty) return 'No Exercise';
    if (workoutTasks.length == 1) return workoutTasks.first.title;
    return '${workoutTasks.first.title} and ${workoutTasks.length - 1} more';
  }

  /// Current task being performed
  WorkoutTask? get currentTask {
    if (currentTaskIndex < workoutTasks.length) {
      return workoutTasks[currentTaskIndex];
    }
    return null;
  }

  /// Next task in the curriculum
  WorkoutTask? get nextTask {
    if (currentTaskIndex + 1 < workoutTasks.length) {
      return workoutTasks[currentTaskIndex + 1];
    }
    return null;
  }

  /// Whether this is the last task
  bool get isLastTask => currentTaskIndex == workoutTasks.length - 1;

  /// Whether the curriculum is completed
  bool get isCompleted => currentTaskIndex >= workoutTasks.length;

  /// Move to the next set/task and return the updated curriculum
  WorkoutCurriculum moveToNextSet() {
    final task = currentTask;
    if (task == null) return this;

    int newSetIndex = currentSetIndex + 1;
    int newTaskIndex = currentTaskIndex;

    if (newSetIndex >= task.adjustedSets) {
      // Move to next task
      newTaskIndex++;
      newSetIndex = 0;
    }

    return copyWith(
      currentTaskIndex: newTaskIndex,
      currentSetIndex: newSetIndex,
    );
  }

  /// Reset progress and return the updated curriculum
  WorkoutCurriculum resetProgress() {
    return copyWith(currentTaskIndex: 0, currentSetIndex: 0);
  }

  WorkoutCurriculum copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnail,
    List<WorkoutTask>? workoutTasks,
    DateTime? createdAt,
    int? currentTaskIndex,
    int? currentSetIndex,
  }) {
    return WorkoutCurriculum(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnail: thumbnail ?? this.thumbnail,
      workoutTasks: workoutTasks ?? this.workoutTasks,
      createdAt: createdAt ?? this.createdAt,
      currentTaskIndex: currentTaskIndex ?? this.currentTaskIndex,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    thumbnail,
    workoutTasks,
    createdAt,
    currentTaskIndex,
    currentSetIndex,
  ];
}
