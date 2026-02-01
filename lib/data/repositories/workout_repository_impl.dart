import 'package:dartz/dartz.dart';
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
      final model = await localDataSource.getCurriculum();
      if (model != null) {
        return Right(model.toEntity());
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to load curriculum: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveCurriculum(
    WorkoutCurriculum curriculum,
  ) async {
    try {
      final model = WorkoutCurriculumModel.fromEntity(curriculum);
      await localDataSource.saveCurriculum(model);
      return const Right(null);
    } catch (e) {
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
  Future<Either<Failure, FeaturedProgram?>> getFeaturedProgram() async {
    try {
      final data = await remoteDataSource.fetchFeaturedProgramData();

      final taskIds = (data['task_ids'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();

      final tasks = await remoteDataSource.fetchWorkoutTasksByIds(taskIds);

      if (tasks.isEmpty) {
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
