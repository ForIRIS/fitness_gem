import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/workout_curriculum.dart';
import '../../domain/entities/featured_program.dart';
import '../../domain/entities/workout_task.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../core/error/failures.dart';
import '../datasources/local/workout_local_datasource.dart';
import '../datasources/remote/firebase_datasource.dart';
import '../datasources/remote/gemini_datasource.dart';
import '../models/workout_curriculum_model.dart';
import '../models/user_profile_model.dart';
import '../models/featured_program_model.dart';

/// Implementation of WorkoutRepository
class WorkoutRepositoryImpl implements WorkoutRepository {
  final WorkoutLocalDataSource localDataSource;
  final FirebaseDataSource remoteDataSource;
  final GeminiDataSource aiDataSource;

  WorkoutRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.aiDataSource,
  });

  @override
  Future<Either<Failure, WorkoutCurriculum?>> getTodayCurriculum() async {
    try {
      debugPrint('WorkoutRepo: Getting today\'s curriculum...');
      final model = await localDataSource.getCurriculum();
      if (model != null) {
        debugPrint('WorkoutRepo: Found cached curriculum: ${model.title}');
        return Right(model.toEntity());
      }
      debugPrint('WorkoutRepo: No cached curriculum found');
      return const Right(null);
    } catch (e) {
      debugPrint('WorkoutRepo: Failed to load curriculum: $e');
      return Left(CacheFailure('Failed to load curriculum: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveCurriculum(
    WorkoutCurriculum curriculum,
  ) async {
    try {
      debugPrint('WorkoutRepo: Saving curriculum: ${curriculum.title}');
      final model = WorkoutCurriculumModel.fromEntity(curriculum);
      await localDataSource.saveCurriculum(model);
      debugPrint('WorkoutRepo: Curriculum saved successfully');
      return const Right(null);
    } catch (e) {
      debugPrint('WorkoutRepo: Failed to save curriculum: $e');
      return Left(CacheFailure('Failed to save curriculum: $e'));
    }
  }

  @override
  Future<Either<Failure, WorkoutCurriculum>> generateCurriculum(
    UserProfile profile,
  ) async {
    try {
      // Determine category from target exercise
      final category = _getCategoryFromTarget(profile.targetExercise);

      // Fetch available workouts from Firebase
      final tasks = await remoteDataSource.fetchWorkoutTasks(category);

      if (tasks.isEmpty) {
        return Left(
          ServerFailure('No workouts available for category: $category'),
        );
      }

      // Generate curriculum using AI
      final profileModel = UserProfileModel.fromEntity(profile);
      final curriculumModel = await aiDataSource.generateCurriculum(
        profile: profileModel,
        category: category,
        availableTasks: tasks,
      );

      // Save locally
      await localDataSource.saveCurriculum(curriculumModel);

      return Right(curriculumModel.toEntity());
    } catch (e) {
      return Left(ServerFailure('Failed to generate curriculum: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getDailyHotCategories() async {
    try {
      final categories = await remoteDataSource.fetchDailyHotCategories();
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch hot categories: $e'));
    }
  }

  @override
  Future<Either<Failure, FeaturedProgram?>> getFeaturedProgram([
    String? category,
  ]) async {
    try {
      debugPrint(
        'WorkoutRepo: Getting featured program for category: $category',
      );

      // 1. Try Local Cache First
      try {
        final cachedModel = await localDataSource.getFeaturedProgram(
          category ?? 'featured',
        );
        if (cachedModel != null) {
          debugPrint('WorkoutRepo: Found cached featured program');
          // Sanitize cached data just in case
          final entity = cachedModel.toEntity();
          return Right(entity);
        }
      } catch (e) {
        debugPrint(
          'WorkoutRepo: Cache lookup failed, proceeding to remote: $e',
        );
      }

      // 2. Fetch Remote
      final data = await remoteDataSource.fetchFeaturedProgramData(category);

      final taskIds =
          (data['task_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      debugPrint('WorkoutRepo: Fetching ${taskIds.length} tasks: $taskIds');

      if (taskIds.isEmpty) {
        debugPrint('WorkoutRepo: No task IDs provided');
        return const Right(null);
      }

      final tasks = await remoteDataSource.fetchWorkoutTasksByIds(taskIds);

      if (tasks.isEmpty) {
        debugPrint('WorkoutRepo: No tasks found for IDs: $taskIds');
        return const Right(null);
      }

      // Reorder tasks to match task_ids order
      final orderedTasks = <WorkoutTask>[];
      for (final id in taskIds) {
        final task = tasks.where((t) => t.id == id).firstOrNull;
        if (task != null) {
          orderedTasks.add(task.toEntity());
        }
      }

      final curriculum = WorkoutCurriculum(
        id: data['id'] ?? 'featured',
        title: data['title'] ?? 'Featured Program',
        description: data['description'] ?? '',
        workoutTasks: orderedTasks,
        createdAt: DateTime.now(),
      );

      // Create Model for Caching
      // Note: We need to reconstruct the model from the fetched data + resolved tasks
      // But FeaturedProgramModel expects a full curriculum model, not just tasks.
      // We'll create the entity first, then the model.

      final featuredProgram = FeaturedProgram(
        id: data['id'] ?? 'featured',
        title: data['title'] ?? 'Featured Program',
        slogan: data['slogan'] ?? 'Get Set, Stay Ignite.',
        description: data['description'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
        membersCount: data['membersCount'] ?? '0',
        rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
        difficulty: (data['difficulty'] ?? 1).toString(),
        userAvatars:
            (data['userAvatars'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        workoutCurriculum: curriculum,
      );

      // 3. Save to Cache
      try {
        final model = FeaturedProgramModel.fromEntity(featuredProgram);
        await localDataSource.saveFeaturedProgram(
          model,
          category ?? 'featured',
        );
      } catch (e) {
        debugPrint('WorkoutRepo: Failed to cache featured program: $e');
      }

      return Right(featuredProgram);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch featured program: $e'));
    }
  }

  @override
  Future<Either<Failure, List<WorkoutTask>>> getWorkoutTasksByCategory(
    String category,
  ) async {
    try {
      final tasks = await remoteDataSource.fetchWorkoutTasks(category);
      return Right(tasks.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Failed to fetch workout tasks: $e'));
    }
  }

  @override
  Future<Either<Failure, List<WorkoutTask>>> getWorkoutTasksByIds(
    List<String> ids,
  ) async {
    try {
      final tasks = await remoteDataSource.fetchWorkoutTasksByIds(ids);
      return Right(tasks.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Failed to fetch workout tasks: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cacheWorkoutResources(
    List<WorkoutTask> tasks, {
    Function(int completed, int total)? onProgress,
  }) async {
    // TODO: Implement caching logic
    // This would integrate with CacheService
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> areResourcesCached(WorkoutTask task) async {
    // TODO: Implement cache checking logic
    return const Right(false);
  }

  String _getCategoryFromTarget(String target) {
    final lower = target.toLowerCase();
    if (lower.contains('squat') || lower.contains('lower')) return 'squat';
    if (lower.contains('push') || lower.contains('upper')) return 'push';
    if (lower.contains('plank') || lower.contains('core')) return 'core';
    if (lower.contains('lunge')) return 'lunge';
    return 'squat'; // Default
  }
}
