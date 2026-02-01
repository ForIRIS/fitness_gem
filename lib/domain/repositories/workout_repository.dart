import 'package:dartz/dartz.dart';
import '../entities/workout_curriculum.dart';
import '../entities/featured_program.dart';
import '../entities/workout_task.dart';
import '../entities/user_profile.dart';
import '../../core/error/failures.dart';

/// Repository interface for workout-related operations
///
/// This defines the contract that data layer must implement
abstract class WorkoutRepository {
  /// Get today's workout curriculum from local storage
  Future<Either<Failure, WorkoutCurriculum?>> getTodayCurriculum();

  /// Save workout curriculum to local storage
  Future<Either<Failure, void>> saveCurriculum(WorkoutCurriculum curriculum);

  /// Generate a new curriculum based on user profile
  Future<Either<Failure, WorkoutCurriculum>> generateCurriculum(
    UserProfile profile,
  );

  /// Get daily hot categories from server
  Future<Either<Failure, List<String>>> getDailyHotCategories();

  /// Get featured program from server
  Future<Either<Failure, FeaturedProgram?>> getFeaturedProgram();

  /// Get workout tasks by category
  Future<Either<Failure, List<WorkoutTask>>> getWorkoutTasksByCategory(
    String category,
  );

  /// Get specific workout tasks by IDs
  Future<Either<Failure, List<WorkoutTask>>> getWorkoutTasksByIds(
    List<String> ids,
  );

  /// Cache workout resources (videos, images, etc.)
  Future<Either<Failure, void>> cacheWorkoutResources(
    List<WorkoutTask> tasks, {
    Function(int completed, int total)? onProgress,
  });

  /// Check if workout resources are cached
  Future<Either<Failure, bool>> areResourcesCached(WorkoutTask task);
}
