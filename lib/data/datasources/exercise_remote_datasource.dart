import '../../../domain/entities/exercise_config.dart';
import '../../../domain/entities/workout_task.dart';

/// Data source interface for exercise-related remote operations
abstract class ExerciseRemoteDataSource {
  /// Fetch exercise configuration from remote URL
  Future<ExerciseConfig> fetchExerciseConfig(String url, String category);

  /// Fetch workout tasks from Firebase
  Future<List<WorkoutTask>> fetchWorkoutTasks();
}
