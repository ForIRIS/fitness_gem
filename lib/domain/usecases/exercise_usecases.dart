import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/exercise_config.dart';
import '../../domain/entities/workout_task.dart';
import '../../domain/repositories/exercise_repository.dart';

/// Use case for getting exercise configuration
class GetExerciseConfigUseCase {
  final ExerciseRepository repository;

  GetExerciseConfigUseCase(this.repository);

  Future<Either<Failure, ExerciseConfig>> call(
    WorkoutTask task, {
    bool useMock = false,
  }) async {
    return await repository.getExerciseConfig(task, useMock: useMock);
  }
}

/// Use case for getting available workouts
class GetAvailableWorkoutsUseCase {
  final ExerciseRepository repository;

  GetAvailableWorkoutsUseCase(this.repository);

  Future<Either<Failure, List<WorkoutTask>>> call({
    bool forceRefresh = false,
  }) async {
    return await repository.getAvailableWorkouts(forceRefresh: forceRefresh);
  }
}
