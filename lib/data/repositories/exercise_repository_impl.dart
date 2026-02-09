import 'package:dartz/dartz.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../../core/error/failures.dart';
import '../../domain/entities/exercise_config.dart';
import '../../domain/entities/workout_task.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../datasources/exercise_local_datasource.dart';
import '../datasources/exercise_remote_datasource.dart';

class ExerciseRepositoryImpl implements ExerciseRepository {
  final ExerciseRemoteDataSource remoteDataSource;
  final ExerciseLocalDataSource localDataSource;

  // Placeholder URL for the Back Lunge video - User to update
  static const String _kBackLungeVideoUrl =
      'https://example.com/placeholder_back_lunge.mp4';

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

      // 1. Check if asset exists in bundle
      try {
        // If this throws, asset doesn't exist
        await rootBundle.load(task.exampleVideoUrl);
        return Right(task);
      } catch (_) {
        // Asset not found, continue to check local storage
      }

      // 2. Check Local File System
      try {
        final directory = await getApplicationDocumentsDirectory();
        final localPath = '${directory.path}/videos/back_lunge.mp4';
        final localFile = File(localPath);

        if (await localFile.exists()) {
          return Right(task.copyWith(exampleVideoUrl: localPath));
        }

        // 3. Download if missing
        try {
          await _downloadVideo(_kBackLungeVideoUrl, localFile);
          return Right(task.copyWith(exampleVideoUrl: localPath));
        } catch (e) {
          // If download fails, return task with original URL (graceful degradation)
          // The UI will likely fail to play, but handles error
          return Right(task);
        }
      } catch (e) {
        // Fallback to original task if file system access fails
        return Right(task);
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<void> _downloadVideo(String url, File targetFile) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      await targetFile.parent.create(recursive: true);
      await targetFile.writeAsBytes(response.bodyBytes);
    } else {
      throw Exception('Failed to download video: ${response.statusCode}');
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
