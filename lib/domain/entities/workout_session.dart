import 'package:equatable/equatable.dart';

/// Domain Entity: WorkoutSession
/// Represents a completed workout session for analytics and progress tracking.
/// Each session is tied to a WorkoutCurriculum and tracks individual task completions.
class WorkoutSession extends Equatable {
  final String id;
  final DateTime date;
  final int durationSeconds;
  final String curriculumId;
  final String curriculumTitle;
  final List<CompletedTask> completedTasks;
  final double avgFormScore; // 0.0 ~ 1.0

  const WorkoutSession({
    required this.id,
    required this.date,
    required this.durationSeconds,
    required this.curriculumId,
    required this.curriculumTitle,
    required this.completedTasks,
    this.avgFormScore = 0.0,
  });

  /// Total reps across all completed tasks
  int get totalReps => completedTasks.fold(0, (sum, task) => sum + task.reps);

  /// Total sets across all completed tasks
  int get totalSets => completedTasks.fold(0, (sum, task) => sum + task.sets);

  /// Total volume (weight × reps) - for weighted exercises
  double get totalVolume =>
      completedTasks.fold(0.0, (sum, task) => sum + task.volume);

  /// Duration in minutes (formatted)
  int get durationMinutes => (durationSeconds / 60).ceil();

  /// List of exercise titles completed
  List<String> get exerciseTitles =>
      completedTasks.map((t) => t.taskTitle).toList();

  /// Categories involved in this session
  Set<String> get categories => completedTasks.map((t) => t.category).toSet();

  WorkoutSession copyWith({
    String? id,
    DateTime? date,
    int? durationSeconds,
    String? curriculumId,
    String? curriculumTitle,
    List<CompletedTask>? completedTasks,
    double? avgFormScore,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      date: date ?? this.date,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      curriculumId: curriculumId ?? this.curriculumId,
      curriculumTitle: curriculumTitle ?? this.curriculumTitle,
      completedTasks: completedTasks ?? this.completedTasks,
      avgFormScore: avgFormScore ?? this.avgFormScore,
    );
  }

  @override
  List<Object?> get props => [
    id,
    date,
    durationSeconds,
    curriculumId,
    curriculumTitle,
    completedTasks,
    avgFormScore,
  ];
}

/// Represents a single completed task (exercise) within a session
class CompletedTask extends Equatable {
  final String taskId;
  final String taskTitle;
  final String category;
  final int reps;
  final int sets;
  final double weight; // kg, 0 if bodyweight
  final double formScore; // 0.0 ~ 1.0

  const CompletedTask({
    required this.taskId,
    required this.taskTitle,
    required this.category,
    required this.reps,
    required this.sets,
    this.weight = 0.0,
    this.formScore = 0.0,
  });

  /// Volume for this task (weight × reps × sets)
  double get volume => weight * reps * sets;

  CompletedTask copyWith({
    String? taskId,
    String? taskTitle,
    String? category,
    int? reps,
    int? sets,
    double? weight,
    double? formScore,
  }) {
    return CompletedTask(
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      category: category ?? this.category,
      reps: reps ?? this.reps,
      sets: sets ?? this.sets,
      weight: weight ?? this.weight,
      formScore: formScore ?? this.formScore,
    );
  }

  @override
  List<Object?> get props => [
    taskId,
    taskTitle,
    category,
    reps,
    sets,
    weight,
    formScore,
  ];
}
