import 'package:dartz/dartz.dart';
import '../entities/exercise_config.dart';
import '../entities/workout_task.dart';
import '../../core/error/failures.dart';

/// Repository interface for exercise configuration operations
///
/// This defines the contract that data layer must implement
abstract class ExerciseRepository {
  /// Get exercise configuration for a specific workout task
  ///
  /// Prioritizes: Cached file -> Remote URL -> Sample/Mock
  Future<Either<Failure, ExerciseConfig>> getExerciseConfig(
    WorkoutTask task, {
    bool useMock = false,
  });

  /// Get available workout tasks
  ///
  /// Merges: Built-in + Local + Remote
  Future<Either<Failure, List<WorkoutTask>>> getAvailableWorkouts({
    bool forceRefresh = false,
  });

  /// Get sample workout task for testing
  Future<Either<Failure, WorkoutTask>> getSampleWorkoutTask();

  /// Save workout task locally
  Future<Either<Failure, void>> saveWorkoutTask(WorkoutTask task);

  /// Delete workout task from local storage
  Future<Either<Failure, void>> deleteWorkoutTask(String taskId);
}
