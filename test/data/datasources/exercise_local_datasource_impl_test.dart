import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_gem/data/datasources/exercise_local_datasource_impl.dart';
import 'package:fitness_gem/services/cache_service.dart';
import 'package:fitness_gem/domain/entities/workout_task.dart';
import 'package:fitness_gem/data/models/workout_task_model.dart';

// Generate mock for CacheService
@GenerateMocks([CacheService])
import 'exercise_local_datasource_impl_test.mocks.dart';

void main() {
  late ExerciseLocalDataSourceImpl dataSource;
  late MockCacheService mockCacheService;

  setUp(() {
    mockCacheService = MockCacheService();
    dataSource = ExerciseLocalDataSourceImpl(cacheService: mockCacheService);
    SharedPreferences.setMockInitialValues({});
  });

  group('Workout Task CRUD Operations', () {
    const tWorkoutTask = WorkoutTask(
      id: 'task_1',
      title: 'Test Workout',
      description: 'Test Description',
      advice: 'Test Advice',
      category: 'Strength',
      difficulty: 1,
      reps: 10,
      sets: 3,
      timeoutSec: 30,
      isCountable: true,
    );

    test('should return empty list when no workouts are saved', () async {
      // Act
      final result = await dataSource.getLocalWorkoutTasks();

      // Assert
      expect(result, isEmpty);
    });

    test('should save and retrieve a workout task', () async {
      // Act
      await dataSource.saveWorkoutTask(tWorkoutTask);
      final result = await dataSource.getLocalWorkoutTasks();

      // Assert
      expect(result, hasLength(1));
      expect(result.first, tWorkoutTask);
    });

    test('should update existing task if saved with same ID', () async {
      // Arrange
      await dataSource.saveWorkoutTask(tWorkoutTask);
      final updatedTask = tWorkoutTask.copyWith(title: 'Updated Title');

      // Act
      await dataSource.saveWorkoutTask(updatedTask);
      final result = await dataSource.getLocalWorkoutTasks();

      // Assert
      expect(result, hasLength(1));
      expect(result.first.id, tWorkoutTask.id);
      expect(result.first.title, 'Updated Title');
    });

    test('should delete a workout task', () async {
      // Arrange
      await dataSource.saveWorkoutTask(tWorkoutTask);

      // Act
      await dataSource.deleteWorkoutTask(tWorkoutTask.id);
      final result = await dataSource.getLocalWorkoutTasks();

      // Assert
      expect(result, isEmpty);
    });
  });
}
