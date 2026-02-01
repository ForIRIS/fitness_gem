import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/exercise_config.dart';
import '../../domain/entities/workout_task.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../datasources/exercise_local_datasource.dart';
import '../datasources/exercise_remote_datasource.dart';

class ExerciseRepositoryImpl implements ExerciseRepository {
  final ExerciseRemoteDataSource remoteDataSource;
  final ExerciseLocalDataSource localDataSource;

  ExerciseRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, ExerciseConfig>> getExerciseConfig(
    WorkoutTask task, {
    bool useMock = false,
  }) async {
    try {
      // If test flag is set or ID matches internal sample ID
      if (useMock || task.id == 'sample_back_lunge') {
        final config = await localDataSource.getSampleExerciseConfig(task.id);
        return Right(config);
      }

      // 1. Check Cache
      if (task.configureUrl.isNotEmpty) {
        final cachedConfig = await localDataSource.getCachedExerciseConfig(
          task.configureUrl,
        );
        if (cachedConfig != null) {
          return Right(cachedConfig);
        }
      }

      // 2. Fetch from URL (Remote)
      if (task.configureUrl.isNotEmpty &&
          task.configureUrl.startsWith('http')) {
        final config = await remoteDataSource.fetchExerciseConfig(
          task.configureUrl,
          task.category,
        );
        // Cache the fetched config
        await localDataSource.cacheExerciseConfig(task.configureUrl, config);
        return Right(config);
      }

      // 3. Fallback to Sample/Mock
      final config = await localDataSource.getSampleExerciseConfig(task.id);
      return Right(config);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WorkoutTask>>> getAvailableWorkouts({
    bool forceRefresh = false,
  }) async {
    try {
      final workoutsMap = <String, WorkoutTask>{};

      // Add Sample Workout for Testing
      final sampleWorkout = await localDataSource.getSampleWorkoutTask();
      workoutsMap[sampleWorkout.id] = sampleWorkout;

      // 1. Fetch Remote (Firebase)
      try {
        final remoteWorkouts = await remoteDataSource.fetchWorkoutTasks();
        for (final workout in remoteWorkouts) {
          workoutsMap[workout.id] = workout;
        }
      } catch (e) {
        // Continue if remote fetch fails
      }

      // 2. Load Local Overrides/Additions
      try {
        final localWorkouts = await localDataSource.getLocalWorkoutTasks();
        for (final workout in localWorkouts) {
          workoutsMap[workout.id] = workout;
        }
      } catch (e) {
        // Continue if local fetch fails
      }

      return Right(workoutsMap.values.toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkoutTask>> getSampleWorkoutTask() async {
    try {
      final task = await localDataSource.getSampleWorkoutTask();
      return Right(task);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveWorkoutTask(WorkoutTask task) async {
    try {
      await localDataSource.saveWorkoutTask(task);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteWorkoutTask(String taskId) async {
    try {
      await localDataSource.deleteWorkoutTask(taskId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
