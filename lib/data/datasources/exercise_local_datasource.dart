import '../../../domain/entities/exercise_config.dart';
import '../../../domain/entities/workout_task.dart';

/// Data source interface for exercise-related local operations
abstract class ExerciseLocalDataSource {
  /// Get cached exercise configuration
  Future<ExerciseConfig?> getCachedExerciseConfig(String url);

  /// Cache exercise configuration
  Future<void> cacheExerciseConfig(String url, ExerciseConfig config);

  /// Get sample/mock exercise configuration
  Future<ExerciseConfig> getSampleExerciseConfig(String taskId);

  /// Get locally saved workout tasks
  Future<List<WorkoutTask>> getLocalWorkoutTasks();

  /// Save workout task locally
  Future<void> saveWorkoutTask(WorkoutTask task);

  /// Delete workout task from local storage
  Future<void> deleteWorkoutTask(String taskId);

  /// Get sample workout task
  Future<WorkoutTask> getSampleWorkoutTask();
}
